#![no_std]
#![no_main]


use embassy_executor::Spawner;
use embassy_stm32::gpio::{Level, Output, Speed};
use embassy_time::{Duration, Ticker};
use cortex_m::peripheral::DWT;

use ipc::{SharedLogBuffer, LogEntry, SystemEvent, IPC_ADDRESS, IpcError};

use {defmt_rtt as _, panic_probe as _};

fn toggle_led(led: &mut Output<'static>, state: SystemEvent) {
    match state {
        SystemEvent::LedOn => {
            led.set_high();
        },
        SystemEvent::LedOff => {
            led.set_low();
        },
    }
}

#[embassy_executor::main]
async fn main(_spawner: Spawner) {
    let shared_data = unsafe { &mut *(ipc::EMBASSY_SHARED_ADDRESS as *mut core::mem::MaybeUninit<embassy_stm32::SharedData>) };
    let p = embassy_stm32::init_secondary(shared_data);

    // Setup IPC
    let ipc = unsafe { &*(IPC_ADDRESS as *const SharedLogBuffer) };

    let mut led = Output::new(p.PE1, Level::High, Speed::Low);
    
    let mut seq = 0;
    let mut state = SystemEvent::LedOn;

    let mut ticker = Ticker::every(Duration::from_millis(250));
    loop {
        ticker.next().await;
        let now = DWT::cycle_count();

        toggle_led(&mut led, state);
        
        let entry = LogEntry {
            sequence: seq,
            timestamp: now,
            event: state,
        };

        // Envio Zero-Copy
        match ipc.try_push(entry) {
            Ok(_) => {
                seq = seq.wrapping_add(1);
            },
            Err(IpcError::BufferFull) => {
                // Buffer lleno, descartamos y seguimos
            }
        }
        state = match state {
            SystemEvent::LedOn => SystemEvent::LedOff,
            SystemEvent::LedOff => SystemEvent::LedOn,
        };
    }
}