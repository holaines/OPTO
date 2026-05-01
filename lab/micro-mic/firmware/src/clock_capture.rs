use stm32h7xx_hal::{
    pac::TIM2,
    rcc::{ResetEnable, rec::Tim2},
};

pub const FLAG_VALID: u8 = 1 << 0;
pub const FLAG_FRESH: u8 = 1 << 1;
pub const FLAG_STALE: u8 = 1 << 2;
pub const FLAG_OVERCAPTURE: u8 = 1 << 3;
pub const FLAG_RANGE_ERROR: u8 = 1 << 4;

const STALE_POLLS: u8 = 200;

#[derive(Clone, Copy, Default)]
pub struct ClockMeasurement {
    pub frequency_hz: u32,
    pub period_ticks: u32,
    pub high_ticks: u32,
    pub timer_clock_hz: u32,
    pub duty_permyriad: u16,
    pub flags: u8,
    pub missed_polls: u8,
}

pub struct ClockCapture {
    tim: TIM2,
    timer_clock_hz: u32,
    last: ClockMeasurement,
    missed_polls: u8,
}

impl ClockCapture {
    pub fn new(tim: TIM2, prec: Tim2, timer_clock_hz: u32) -> Self {
        let _prec = prec.enable().reset();

        tim.cr1.modify(|_, w| w.cen().clear_bit());
        tim.dier.write(|w| unsafe { w.bits(0) });
        tim.ccer.write(|w| unsafe { w.bits(0) });
        tim.psc.write(|w| w.psc().bits(0));
        tim.arr.write(|w| w.arr().bits(u32::MAX));

        // PWM-input mode on TI1: CCR1 captures period, CCR2 captures high time.
        tim.ccmr1_input()
            .write(|w| unsafe { w.bits((1 << 0) | (2 << 8)) });
        tim.ccer
            .write(|w| unsafe { w.bits((1 << 0) | (1 << 4) | (1 << 5)) });
        tim.smcr.write(|w| w.ts().ti1fp1().sms().reset_mode());

        tim.egr.write(|w| w.ug().update());
        tim.sr.write(|w| unsafe { w.bits(0) });
        tim.cr1.write(|w| w.cen().set_bit());

        Self {
            tim,
            timer_clock_hz,
            last: ClockMeasurement {
                timer_clock_hz,
                ..ClockMeasurement::default()
            },
            missed_polls: STALE_POLLS,
        }
    }

    pub fn sample(&mut self) -> ClockMeasurement {
        let sr = self.tim.sr.read();
        let fresh = sr.cc1if().bit_is_set() && sr.cc2if().bit_is_set();
        let overcapture = sr.cc1of().bit_is_set() || sr.cc2of().bit_is_set();
        let period_ticks = self.tim.ccr1().read().ccr().bits();
        let high_ticks = self.tim.ccr2().read().ccr().bits();
        self.tim.sr.write(|w| unsafe { w.bits(0) });

        if fresh && period_ticks != 0 {
            self.missed_polls = 0;
            let range_error = high_ticks > period_ticks;
            let duty_permyriad = if range_error {
                0
            } else {
                ((u64::from(high_ticks) * 10_000) / u64::from(period_ticks)) as u16
            };
            let frequency_hz = ((u64::from(self.timer_clock_hz) + (u64::from(period_ticks) / 2))
                / u64::from(period_ticks)) as u32;

            let mut flags = FLAG_VALID | FLAG_FRESH;
            if overcapture {
                flags |= FLAG_OVERCAPTURE;
            }
            if range_error {
                flags |= FLAG_RANGE_ERROR;
            }

            self.last = ClockMeasurement {
                frequency_hz,
                period_ticks,
                high_ticks,
                timer_clock_hz: self.timer_clock_hz,
                duty_permyriad,
                flags,
                missed_polls: 0,
            };
            return self.last;
        }

        self.missed_polls = self.missed_polls.saturating_add(1);
        if self.missed_polls < STALE_POLLS && self.last.flags & FLAG_VALID != 0 {
            let mut stale = self.last;
            stale.flags = (stale.flags | FLAG_STALE) & !FLAG_FRESH;
            stale.missed_polls = self.missed_polls;
            return stale;
        }

        ClockMeasurement {
            timer_clock_hz: self.timer_clock_hz,
            missed_polls: self.missed_polls,
            ..ClockMeasurement::default()
        }
    }
}
