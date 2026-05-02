use core::ptr::addr_of_mut;
use core::sync::atomic::{Ordering, fence};

use stm32h7xx_hal::{
    dma::{
        self, DBTransfer, DMAError, PeripheralToMemory, Transfer, config::Priority, dma::DmaConfig,
    },
    gpio::{Alternate, gpioa::PA5, gpiob::PB5},
    pac::{DMA1, SPI1, spi1::RegisterBlock as SpiRegisterBlock},
    rcc::{ResetEnable, rec},
};

use crate::config;

pub const CHANNEL_ID_PDM_SPI1: u8 = 4;
pub const FLAG_DMA_OVERRUN: u16 = 0x0001;
pub const FLAG_SPI_OVERRUN: u16 = 0x0002;
pub const FLAG_SPI_MODE_FAULT: u16 = 0x0004;

const RAW_BITS_PER_FRAME: usize = config::AUDIO_FRAME_SAMPLES * config::PDM_DECIMATION as usize;
const RAW_BYTES_PER_FRAME: usize = (RAW_BITS_PER_FRAME + 7) / 8;
const FIR_DECIMATION: usize = config::PDM_DECIMATION as usize;
const FIR_TAPS: usize = FIR_DECIMATION * 3 - 2;
const FIR_HISTORY_BITS: usize = FIR_TAPS - 1;
const FIR_GAIN: i32 = (FIR_DECIMATION * FIR_DECIMATION * FIR_DECIMATION) as i32;
const FIR_COEFFICIENTS: [i32; FIR_TAPS] = sinc3_fir_coefficients();

static mut PDM_BUFFER0: [u8; RAW_BYTES_PER_FRAME] = [0; RAW_BYTES_PER_FRAME];
static mut PDM_BUFFER1: [u8; RAW_BYTES_PER_FRAME] = [0; RAW_BYTES_PER_FRAME];

type PdmTransfer = Transfer<
    dma::dma::Stream2<DMA1>,
    SPI1,
    PeripheralToMemory,
    &'static mut [u8; RAW_BYTES_PER_FRAME],
    DBTransfer,
>;

pub struct PdmSampler {
    transfer: PdmTransfer,
    _sck: PA5<Alternate<5>>,
    _mosi: PB5<Alternate<5>>,
    pcm: [u16; config::AUDIO_FRAME_SAMPLES],
    history: [i8; FIR_HISTORY_BITS],
    pending_flags: u16,
    last_ones: u16,
}

impl PdmSampler {
    pub fn new(
        mut spi: SPI1,
        spi_prec: rec::Spi1,
        sck: PA5<Alternate<5>>,
        mosi: PB5<Alternate<5>>,
        stream: dma::dma::Stream2<DMA1>,
    ) -> Self {
        let _spi_prec = spi_prec.enable().reset();
        configure_spi1_slave_rx(&mut spi);

        let mut transfer: PdmTransfer = Transfer::init(
            stream,
            spi,
            pdm_buffer0(),
            Some(pdm_buffer1()),
            dma_config(),
        );
        transfer.start(|spi| enable_spi1_slave_rx(spi));

        Self {
            transfer,
            _sck: sck,
            _mosi: mosi,
            pcm: [0; config::AUDIO_FRAME_SAMPLES],
            history: [0; FIR_HISTORY_BITS],
            pending_flags: 0,
            last_ones: 0,
        }
    }

    pub fn process_ready_frame<F>(&mut self, f: F) -> bool
    where
        F: FnOnce(&[u16; config::AUDIO_FRAME_SAMPLES], u16),
    {
        if !self.transfer.get_transfer_complete_flag() {
            return false;
        }

        let flags = self.pending_flags | spi_status_flags();
        self.pending_flags = 0;

        let mut ones = 0u16;
        let result = unsafe {
            self.transfer.next_dbm_transfer_with(|buffer, _| {
                fence(Ordering::SeqCst);
                ones = filter_pdm(&**buffer, &mut self.history, &mut self.pcm);
                fence(Ordering::SeqCst);
            })
        };
        self.last_ones = ones;

        if matches!(result, Err(DMAError::Overflow)) {
            self.pending_flags |= FLAG_DMA_OVERRUN;
        }

        f(&self.pcm, flags);

        true
    }

    pub fn debug_word(&self) -> u32 {
        let spi = unsafe { &*SPI1::ptr() };
        let sr = spi.sr.read();
        let cfg1 = spi.cfg1.read();
        let cr1 = spi.cr1.read();

        let mut word = 0;
        if self.transfer.get_transfer_complete_flag() {
            word |= 1 << 0;
        }
        if cr1.spe().is_enabled() {
            word |= 1 << 1;
        }
        if cfg1.rxdmaen().is_enabled() {
            word |= 1 << 2;
        }
        if sr.rxp().is_not_empty() {
            word |= 1 << 3;
        }
        if sr.ovr().is_overrun() {
            word |= 1 << 4;
        }
        if sr.modf().is_fault() {
            word |= 1 << 5;
        }
        if self.last_ones > 0 && usize::from(self.last_ones) < RAW_BITS_PER_FRAME {
            word |= 1 << 6;
        }

        word | (u32::from(self.last_ones) << 16)
    }
}

fn configure_spi1_slave_rx(spi: &mut SPI1) {
    spi.cr1.write(|w| w.spe().disabled());
    clear_spi1_flags(spi);
    drain_spi1_rx(spi);

    spi.cfg1.write(|w| {
        w.dsize()
            .bits(8 - 1)
            .fthlv()
            .one_frame()
            .rxdmaen()
            .enabled()
    });
    spi.cfg2.write(|w| {
        w.afcntr()
            .controlled()
            .ssm()
            .enabled()
            .cpol()
            .idle_low()
            .cpha()
            .first_edge()
            .lsbfrst()
            .msbfirst()
            .master()
            .slave()
            .sp()
            .motorola()
            .comm()
            .receiver()
    });
    spi.cr2.write(|w| w.tsize().bits(0));
    clear_spi1_flags(spi);
}

fn enable_spi1_slave_rx(spi: &mut SPI1) {
    clear_spi1_flags(spi);
    drain_spi1_rx(spi);
    spi.cr1.write(|w| w.ssi().slave_selected().spe().enabled());
}

fn spi_status_flags() -> u16 {
    let spi = unsafe { &*SPI1::ptr() };
    let sr = spi.sr.read();
    let mut flags = 0;

    if sr.ovr().is_overrun() {
        flags |= FLAG_SPI_OVERRUN;
    }
    if sr.modf().is_fault() {
        flags |= FLAG_SPI_MODE_FAULT;
    }

    if flags != 0 {
        clear_spi1_flags(spi);
    }

    flags
}

fn clear_spi1_flags(spi: &SpiRegisterBlock) {
    spi.ifcr.write(|w| {
        w.suspc()
            .clear()
            .tserfc()
            .clear()
            .modfc()
            .clear()
            .tifrec()
            .clear()
            .crcec()
            .clear()
            .ovrc()
            .clear()
            .udrc()
            .clear()
            .txtfc()
            .clear()
            .eotc()
            .clear()
    });
}

fn drain_spi1_rx(spi: &SpiRegisterBlock) {
    while spi.sr.read().rxp().is_not_empty() {
        let _ = spi.rxdr.read().bits();
    }
}

fn filter_pdm(
    raw: &[u8; RAW_BYTES_PER_FRAME],
    history: &mut [i8; FIR_HISTORY_BITS],
    pcm: &mut [u16; config::AUDIO_FRAME_SAMPLES],
) -> u16 {
    let ones = count_raw_ones(raw);

    for (sample_index, dst) in pcm.iter_mut().enumerate() {
        let output_bit_index = sample_index * FIR_DECIMATION;
        let mut acc = 0;

        for (tap, coefficient) in FIR_COEFFICIENTS.iter().enumerate() {
            acc += coefficient * i32::from(pdm_sample(raw, history, output_bit_index, tap));
        }

        let scaled = acc * i32::from(i16::MAX) / FIR_GAIN;
        *dst = clamp_to_u16(scaled + 32_768);
    }

    update_history(raw, history);

    ones
}

const fn sinc3_fir_coefficients() -> [i32; FIR_TAPS] {
    let mut coefficients = [0; FIR_TAPS];
    let mut tap = 0;

    while tap < FIR_TAPS {
        let mut coefficient = 0;
        let mut a = 0;

        while a < FIR_DECIMATION {
            let mut b = 0;

            while b < FIR_DECIMATION {
                let ab = a + b;
                if tap >= ab && tap - ab < FIR_DECIMATION {
                    coefficient += 1;
                }
                b += 1;
            }

            a += 1;
        }

        coefficients[tap] = coefficient;
        tap += 1;
    }

    coefficients
}

fn pdm_sample(
    raw: &[u8; RAW_BYTES_PER_FRAME],
    history: &[i8; FIR_HISTORY_BITS],
    output_bit_index: usize,
    tap: usize,
) -> i8 {
    if output_bit_index >= tap {
        bit_to_sample(pdm_bit(raw, output_bit_index - tap))
    } else {
        let age = tap - output_bit_index;
        history[FIR_HISTORY_BITS - age]
    }
}

fn update_history(raw: &[u8; RAW_BYTES_PER_FRAME], history: &mut [i8; FIR_HISTORY_BITS]) {
    let start = RAW_BITS_PER_FRAME - FIR_HISTORY_BITS;

    for (index, sample) in history.iter_mut().enumerate() {
        *sample = bit_to_sample(pdm_bit(raw, start + index));
    }
}

fn count_raw_ones(raw: &[u8; RAW_BYTES_PER_FRAME]) -> u16 {
    raw.iter()
        .fold(0u16, |count, byte| count + byte.count_ones() as u16)
}

fn pdm_bit(raw: &[u8; RAW_BYTES_PER_FRAME], bit_index: usize) -> bool {
    let byte = raw[bit_index / 8];
    let mask = 0x80 >> (bit_index % 8);
    (byte & mask) != 0
}

fn bit_to_sample(bit: bool) -> i8 {
    if bit { 1 } else { -1 }
}

fn clamp_to_u16(value: i32) -> u16 {
    value.clamp(0, u16::MAX as i32) as u16
}

fn dma_config() -> DmaConfig {
    DmaConfig::default()
        .memory_increment(true)
        .double_buffer(true)
        .circular_buffer(true)
        .priority(Priority::VeryHigh)
}

fn pdm_buffer0() -> &'static mut [u8; RAW_BYTES_PER_FRAME] {
    unsafe { &mut *addr_of_mut!(PDM_BUFFER0) }
}

fn pdm_buffer1() -> &'static mut [u8; RAW_BYTES_PER_FRAME] {
    unsafe { &mut *addr_of_mut!(PDM_BUFFER1) }
}
