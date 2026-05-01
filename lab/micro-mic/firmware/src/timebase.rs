use core::sync::atomic::{AtomicU32, Ordering};

use stm32h7xx_hal::rcc::CoreClocks;

static TIME_MS: AtomicU32 = AtomicU32::new(0);

pub fn init(mut syst: cortex_m::peripheral::SYST, clocks: CoreClocks) {
    let c_ck_mhz = clocks.c_ck().to_MHz();

    syst.set_clock_source(cortex_m::peripheral::syst::SystClkSource::Core);
    syst.set_reload((1_000 * c_ck_mhz) - 1);
    syst.clear_current();
    syst.enable_interrupt();
    syst.enable_counter();
}

pub fn now_ms() -> u32 {
    TIME_MS.load(Ordering::Relaxed)
}

pub fn tick() {
    TIME_MS.fetch_add(1, Ordering::Relaxed);
}
