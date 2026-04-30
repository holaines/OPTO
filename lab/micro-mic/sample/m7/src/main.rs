#![no_std]
#![no_main]

use embassy_sync::signal::Signal;
use embassy_sync::blocking_mutex::raw::CriticalSectionRawMutex;
use embassy_executor::Spawner;
use embassy_stm32::gpio::{Level, Output, Speed};
use embassy_stm32::time::Hertz;
use embassy_stm32::{Config, pac};
use embassy_stm32::rcc::{SupplyConfig, Hse, HseMode, Pll, PllSource, PllPreDiv, PllMul, PllDiv, Sysclk, AHBPrescaler, APBPrescaler, VoltageScale};
use embassy_time::{Duration, Ticker, Timer};
use ipc::{SharedLogBuffer, SystemEvent};
use {defmt_rtt as _, panic_probe as _};


static LED_SIGNAL: Signal<CriticalSectionRawMutex, SystemEvent> = Signal::new();

fn config() -> Config {
    let mut config = Config::default();

    config.rcc.supply_config = SupplyConfig::DirectSMPS;

    // Clock Configuration (400 MHz)
    // Oscillator (HSE) - Assuming 25 MHz crystal
    config.rcc.hse = Some(Hse {
        freq: Hertz(25_000_000),
        mode: HseMode::Oscillator,
    });

    // PLL1 Configuration
    // Target: 400 MHz SysClk (Max for VOS1/SMPS)
    // HSE (25 MHz) / M(5) = 5 MHz Ref
    // 5 MHz * N(160) = 800 MHz VCO
    // 800 MHz / P(2) = 400 MHz Output
    config.rcc.pll1 = Some(Pll {
        source: PllSource::HSE,
        prediv: PllPreDiv::DIV5,
        mul: PllMul::MUL160,
        divp: Some(PllDiv::DIV2),
        divq: Some(PllDiv::DIV2), // 400 MHz
        divr: Some(PllDiv::DIV2),
    });

    config.rcc.sys = Sysclk::PLL1_P;
    config.rcc.ahb_pre = AHBPrescaler::DIV2; // HCLK = 200 MHz
    config.rcc.apb1_pre = APBPrescaler::DIV2; // PCLK1 = 100 MHz
    config.rcc.apb2_pre = APBPrescaler::DIV2; // PCLK2 = 100 MHz
    config.rcc.apb3_pre = APBPrescaler::DIV2;
    config.rcc.apb4_pre = APBPrescaler::DIV2;

    config.rcc.voltage_scale = VoltageScale::Scale1; // Critical: VOS0 is required for 480 MHz

    // To boost to 480 MHz (VOS0), use the following changes:
    // 1. config.rcc.voltage_scale = VoltageScale::Scale0;
    // 2. In pll1, change mul to PllMul::MUL192; // 25MHz / 5 * 192 / 2 = 480 MHz

    config
}

#[embassy_executor::task]
async fn print_log(ipc: &'static SharedLogBuffer) -> ! {
    let mut ticker = Ticker::every(Duration::from_millis(5));
    loop {
        ticker.next().await;
        while let Some(entry) = ipc.try_pop() {
            LED_SIGNAL.signal(entry.event);
            match entry.event {
                SystemEvent::LedOn => {
                    defmt::info!("[M4-LOG] Seq: {} | T: {} | LED ON", 
                        entry.sequence, entry.timestamp);
                }
                SystemEvent::LedOff => {
                    defmt::info!("[M4-LOG] Seq: {} | T: {} | LED OFF", 
                        entry.sequence, entry.timestamp);
                }
            }
        }
    }
}

#[embassy_executor::task]
async fn blinky(mut led: Output<'static>) -> ! {
    loop {
        match LED_SIGNAL.wait().await {
            SystemEvent::LedOn => led.set_high(),
            SystemEvent::LedOff => led.set_low(),
        }
    }
}

#[embassy_executor::main]
async fn main(spawner: Spawner) {
    let shared_data = unsafe { &mut *(ipc::EMBASSY_SHARED_ADDRESS as *mut core::mem::MaybeUninit<embassy_stm32::SharedData>) };
    
    let p = embassy_stm32::init_primary(config(), shared_data);
    let ipc = SharedLogBuffer::init();

    let green_led = Output::new(p.PB0, Level::High, Speed::Low);

    defmt::info!("M7: IPC Inicializado. Despertando M4...");

    Timer::after(Duration::from_millis(100)).await;

    cortex_m::interrupt::free(|_| {
        pac::RCC.gcr().modify(|w| w.set_boot_c2(true));
    });

    spawner.spawn(print_log(ipc)).unwrap();
    spawner.spawn(blinky(green_led)).unwrap();
}