use core::ptr::addr_of_mut;
use core::sync::atomic::{Ordering, fence};

use stm32h7xx_hal::{
    adc::{self, Adc, Enabled},
    dma::{
        self, DBTransfer, DMAError, PeripheralToMemory, Transfer,
        config::Priority,
        dma::{DmaConfig, StreamsTuple},
    },
    gpio::{Analog, gpioc::PC0},
    pac::{ADC1, DMA1, TIM6},
    rcc::{CoreClocks, rec},
    timer::Timer,
};

use crate::config;

pub const CHANNEL_ID_PC0: u8 = 1;
pub const FLAG_DMA_OVERRUN: u16 = 0x0001;

const PC0_ADC_CHANNEL: u8 = 10;
const SAMPLE_TIME: adc::AdcSampleTime = adc::AdcSampleTime::T_64;

static mut AUDIO_BUFFER0: [u16; config::AUDIO_FRAME_SAMPLES] =
    [0; config::AUDIO_FRAME_SAMPLES];
static mut AUDIO_BUFFER1: [u16; config::AUDIO_FRAME_SAMPLES] =
    [0; config::AUDIO_FRAME_SAMPLES];

type AudioTransfer = Transfer<
    dma::dma::Stream0<DMA1>,
    Adc<ADC1, Enabled>,
    PeripheralToMemory,
    &'static mut [u16; config::AUDIO_FRAME_SAMPLES],
    DBTransfer,
>;

pub struct AudioSampler {
    transfer: AudioTransfer,
    _trigger: Timer<TIM6>,
    _pin: PC0<Analog>,
    sample_rate_hz: u32,
    pending_flags: u16,
}

impl AudioSampler {
    pub fn new(
        mut adc: Adc<ADC1, Enabled>,
        pin: PC0<Analog>,
        dma: DMA1,
        dma_prec: rec::Dma1,
        tim: TIM6,
        tim_prec: rec::Tim6,
        clocks: &CoreClocks,
    ) -> Self {
        configure_adc(&mut adc);

        let mut trigger = Timer::tim6(tim, tim_prec, clocks);
        let sample_rate_hz = configure_trigger(&mut trigger, clocks.timx_ker_ck().raw());

        let streams = StreamsTuple::new(dma, dma_prec);
        let dma_config = DmaConfig::default()
            .memory_increment(true)
            .double_buffer(true)
            .circular_buffer(true)
            .priority(Priority::VeryHigh);

        let mut transfer: AudioTransfer =
            Transfer::init(streams.0, adc, buffer0(), Some(buffer1()), dma_config);

        transfer.start(|_| start_adc());
        trigger.resume();

        Self {
            transfer,
            _trigger: trigger,
            _pin: pin,
            sample_rate_hz,
            pending_flags: 0,
        }
    }

    pub fn sample_rate_hz(&self) -> u32 {
        self.sample_rate_hz
    }

    pub fn process_ready_frame<F>(&mut self, f: F) -> bool
    where
        F: FnOnce(&[u16; config::AUDIO_FRAME_SAMPLES], u16),
    {
        if !self.transfer.get_transfer_complete_flag() {
            return false;
        }

        let flags = self.pending_flags;
        self.pending_flags = 0;

        let result = unsafe {
            self.transfer.next_dbm_transfer_with(|buffer, _| {
                fence(Ordering::SeqCst);
                f(&**buffer, flags);
                fence(Ordering::SeqCst);
            })
        };

        if matches!(result, Err(DMAError::Overflow)) {
            self.pending_flags |= FLAG_DMA_OVERRUN;
        }

        true
    }
}

fn configure_adc(_adc: &mut Adc<ADC1, Enabled>) {
    let adc = unsafe { &*ADC1::ptr() };

    if adc.cr.read().adstart().bit_is_set() {
        adc.cr.modify(|_, w| w.adstp().set_bit());
        while adc.cr.read().adstp().bit_is_set() {}
    }

    adc.ier
        .modify(|_, w| w.eocie().clear_bit().ovrie().clear_bit());
    adc.isr.modify(|_, w| {
        w.eoc()
            .set_bit()
            .eos()
            .set_bit()
            .ovr()
            .set_bit()
            .eosmp()
            .set_bit()
    });

    adc.cfgr.modify(|_, w| {
        w.res()
            .sixteen_bit()
            .dmngt()
            .dma_circular()
            .cont()
            .single()
            .discen()
            .clear_bit()
            .ovrmod()
            .overwrite()
            .extsel()
            .tim6_trgo()
            .exten()
            .rising_edge()
    });

    adc.pcsel
        .modify(|r, w| unsafe { w.pcsel().bits(r.pcsel().bits() | (1 << PC0_ADC_CHANNEL)) });
    adc.smpr2
        .modify(|_, w| w.smp10().bits(u8::from(SAMPLE_TIME)));
    adc.sqr1
        .modify(|_, w| unsafe { w.l().bits(0).sq1().bits(PC0_ADC_CHANNEL) });
}

fn configure_trigger(trigger: &mut Timer<TIM6>, timer_clock_hz: u32) -> u32 {
    let ticks = (timer_clock_hz / config::AUDIO_SAMPLE_RATE_HZ).max(1);
    let arr = ticks.saturating_sub(1).min(u16::MAX as u32) as u16;

    trigger.pause();
    trigger.urs_counter_only();
    trigger.inner_mut().psc.write(|w| w.psc().bits(0));
    trigger.inner_mut().arr.write(|w| w.arr().bits(arr));
    trigger.inner_mut().cr2.modify(|_, w| w.mms().update());
    trigger.apply_freq();
    trigger.clear_irq();

    timer_clock_hz / (u32::from(arr) + 1)
}

fn start_adc() {
    let adc = unsafe { &*ADC1::ptr() };
    adc.cr.modify(|_, w| w.adstart().set_bit());
}

fn buffer0() -> &'static mut [u16; config::AUDIO_FRAME_SAMPLES] {
    unsafe { &mut *addr_of_mut!(AUDIO_BUFFER0) }
}

fn buffer1() -> &'static mut [u16; config::AUDIO_FRAME_SAMPLES] {
    unsafe { &mut *addr_of_mut!(AUDIO_BUFFER1) }
}
