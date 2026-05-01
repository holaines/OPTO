use stm32h7xx_hal::hal::blocking::delay::DelayUs;

pub struct AdcDelay {
    cycles_per_us: u32,
}

impl AdcDelay {
    pub fn new(cycles_per_us: u32) -> Self {
        Self { cycles_per_us }
    }
}

impl DelayUs<u8> for AdcDelay {
    fn delay_us(&mut self, us: u8) {
        cortex_m::asm::delay(self.cycles_per_us.saturating_mul(us as u32));
    }
}
