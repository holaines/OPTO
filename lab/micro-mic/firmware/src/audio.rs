use core::ptr::addr_of_mut;
use core::sync::atomic::{Ordering, fence};

use stm32h7xx_hal::{
    adc::{self, Adc, Enabled},
    dma::{
        self, DBTransfer, DMAError, PeripheralToMemory, Transfer,
        config::Priority,
        dma::{DmaConfig, StreamsTuple},
    },
    gpio::{
        Analog,
        gpioc::{PC0, PC2},
    },
    pac::{ADC1, ADC3, DMA1, TIM6, adc3::RegisterBlock as AdcRegisterBlock},
    rcc::{CoreClocks, rec},
    timer::Timer,
};

use crate::config;

pub const CHANNEL_ID_PC0: u8 = 1;
pub const CHANNEL_ID_PC2: u8 = 3;
pub const FLAG_DMA_OVERRUN: u16 = 0x0001;

const PC0_ADC_CHANNEL: u8 = 10;
const PC2_ADC_CHANNEL: u8 = 12;
const SAMPLE_TIME: adc::AdcSampleTime = adc::AdcSampleTime::T_64;

static mut PC0_BUFFER0: [u16; config::AUDIO_FRAME_SAMPLES] =
    [0; config::AUDIO_FRAME_SAMPLES];
static mut PC0_BUFFER1: [u16; config::AUDIO_FRAME_SAMPLES] =
    [0; config::AUDIO_FRAME_SAMPLES];
static mut PC2_BUFFER0: [u16; config::AUDIO_FRAME_SAMPLES] =
    [0; config::AUDIO_FRAME_SAMPLES];
static mut PC2_BUFFER1: [u16; config::AUDIO_FRAME_SAMPLES] =
    [0; config::AUDIO_FRAME_SAMPLES];

pub type DmaStreams = StreamsTuple<DMA1>;

type AudioTransferAdc1 = Transfer<
    dma::dma::Stream0<DMA1>,
    Adc<ADC1, Enabled>,
    PeripheralToMemory,
    &'static mut [u16; config::AUDIO_FRAME_SAMPLES],
    DBTransfer,
>;

type AudioTransferAdc3 = Transfer<
    dma::dma::Stream1<DMA1>,
    Adc<ADC3, Enabled>,
    PeripheralToMemory,
    &'static mut [u16; config::AUDIO_FRAME_SAMPLES],
    DBTransfer,
>;

pub trait AudioChannel {
    fn process_ready_frame<F>(&mut self, f: F) -> bool
    where
        F: FnOnce(&[u16; config::AUDIO_FRAME_SAMPLES], u16);
}

pub struct AudioTrigger {
    timer: Timer<TIM6>,
    sample_rate_hz: u32,
}

impl AudioTrigger {
    pub fn new(tim: TIM6, tim_prec: rec::Tim6, clocks: &CoreClocks) -> Self {
        let mut timer = Timer::tim6(tim, tim_prec, clocks);
        let sample_rate_hz = configure_trigger(&mut timer, clocks.timx_ker_ck().raw());

        Self {
            timer,
            sample_rate_hz,
        }
    }

    pub fn start(&mut self) {
        self.timer.resume();
    }

    pub fn sample_rate_hz(&self) -> u32 {
        self.sample_rate_hz
    }
}

pub struct AudioSamplerAdc1 {
    transfer: AudioTransferAdc1,
    _pin: PC0<Analog>,
    pending_flags: u16,
}

impl AudioSamplerAdc1 {
    pub fn new(
        mut adc: Adc<ADC1, Enabled>,
        pin: PC0<Analog>,
        stream: dma::dma::Stream0<DMA1>,
    ) -> Self {
        configure_adc1(&mut adc);

        let mut transfer: AudioTransferAdc1 =
            Transfer::init(stream, adc, pc0_buffer0(), Some(pc0_buffer1()), dma_config());

        transfer.start(|_| start_adc1());

        Self {
            transfer,
            _pin: pin,
            pending_flags: 0,
        }
    }
}

impl AudioChannel for AudioSamplerAdc1 {
    fn process_ready_frame<F>(&mut self, f: F) -> bool
    where
        F: FnOnce(&[u16; config::AUDIO_FRAME_SAMPLES], u16),
    {
        process_ready_frame(&mut self.transfer, &mut self.pending_flags, f)
    }
}

pub struct AudioSamplerAdc3 {
    transfer: AudioTransferAdc3,
    _pin: PC2<Analog>,
    pending_flags: u16,
}

impl AudioSamplerAdc3 {
    pub fn new(
        mut adc: Adc<ADC3, Enabled>,
        pin: PC2<Analog>,
        stream: dma::dma::Stream1<DMA1>,
    ) -> Self {
        configure_adc3(&mut adc);

        let mut transfer: AudioTransferAdc3 =
            Transfer::init(stream, adc, pc2_buffer0(), Some(pc2_buffer1()), dma_config());

        transfer.start(|_| start_adc3());

        Self {
            transfer,
            _pin: pin,
            pending_flags: 0,
        }
    }
}

impl AudioChannel for AudioSamplerAdc3 {
    fn process_ready_frame<F>(&mut self, f: F) -> bool
    where
        F: FnOnce(&[u16; config::AUDIO_FRAME_SAMPLES], u16),
    {
        process_ready_frame(&mut self.transfer, &mut self.pending_flags, f)
    }
}

pub fn split_dma(dma: DMA1, dma_prec: rec::Dma1) -> DmaStreams {
    StreamsTuple::new(dma, dma_prec)
}

fn dma_config() -> DmaConfig {
    DmaConfig::default()
        .memory_increment(true)
        .double_buffer(true)
        .circular_buffer(true)
        .priority(Priority::VeryHigh)
}

fn process_ready_frame<STREAM, ADC, F>(
    transfer: &mut Transfer<
        STREAM,
        Adc<ADC, Enabled>,
        PeripheralToMemory,
        &'static mut [u16; config::AUDIO_FRAME_SAMPLES],
        DBTransfer,
    >,
    pending_flags: &mut u16,
    f: F,
) -> bool
where
    STREAM: dma::traits::DoubleBufferedStream,
    STREAM: dma::traits::Stream<Config = DmaConfig>,
    Adc<ADC, Enabled>: dma::traits::TargetAddress<PeripheralToMemory, MemSize = u16>,
    F: FnOnce(&[u16; config::AUDIO_FRAME_SAMPLES], u16),
{
    if !transfer.get_transfer_complete_flag() {
        return false;
    }

    let flags = *pending_flags;
    *pending_flags = 0;

    let result = unsafe {
        transfer.next_dbm_transfer_with(|buffer, _| {
            fence(Ordering::SeqCst);
            f(&**buffer, flags);
            fence(Ordering::SeqCst);
        })
    };

    if matches!(result, Err(DMAError::Overflow)) {
        *pending_flags |= FLAG_DMA_OVERRUN;
    }

    true
}

fn configure_adc1(_adc: &mut Adc<ADC1, Enabled>) {
    configure_adc_registers(unsafe { &*ADC1::ptr() }, PC0_ADC_CHANNEL);
}

fn configure_adc3(_adc: &mut Adc<ADC3, Enabled>) {
    configure_adc_registers(unsafe { &*ADC3::ptr() }, PC2_ADC_CHANNEL);
}

fn configure_adc_registers(adc: &AdcRegisterBlock, channel: u8) {
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
        .modify(|r, w| unsafe { w.pcsel().bits(r.pcsel().bits() | (1 << channel)) });
    adc.sqr1
        .modify(|_, w| unsafe { w.l().bits(0).sq1().bits(channel) });

    let sample_time = u8::from(SAMPLE_TIME);
    match channel {
        10 => adc.smpr2.modify(|_, w| w.smp10().bits(sample_time)),
        12 => adc.smpr2.modify(|_, w| w.smp12().bits(sample_time)),
        _ => {}
    }
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

fn start_adc1() {
    let adc = unsafe { &*ADC1::ptr() };
    adc.cr.modify(|_, w| w.adstart().set_bit());
}

fn start_adc3() {
    let adc = unsafe { &*ADC3::ptr() };
    adc.cr.modify(|_, w| w.adstart().set_bit());
}

fn pc0_buffer0() -> &'static mut [u16; config::AUDIO_FRAME_SAMPLES] {
    unsafe { &mut *addr_of_mut!(PC0_BUFFER0) }
}

fn pc0_buffer1() -> &'static mut [u16; config::AUDIO_FRAME_SAMPLES] {
    unsafe { &mut *addr_of_mut!(PC0_BUFFER1) }
}

fn pc2_buffer0() -> &'static mut [u16; config::AUDIO_FRAME_SAMPLES] {
    unsafe { &mut *addr_of_mut!(PC2_BUFFER0) }
}

fn pc2_buffer1() -> &'static mut [u16; config::AUDIO_FRAME_SAMPLES] {
    unsafe { &mut *addr_of_mut!(PC2_BUFFER1) }
}
