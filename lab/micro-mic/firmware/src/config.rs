pub const SAMPLE_PERIOD_MS: u32 = 10;
pub const AUDIO_SAMPLE_RATE_HZ: u32 = 200_000;
pub const AUDIO_FRAME_SAMPLES: usize = 704;
pub const CLOCK_HZ: u32 = 2_200_000;
pub const VREF_MV: u16 = 3300;

pub const MCU_IP: [u8; 4] = [192, 168, 88, 99];
pub const TELEMETRY_DEST_IP: [u8; 4] = [192, 168, 88, 2];
pub const MCU_UDP_PORT: u16 = 5000;
pub const PC_UDP_PORT: u16 = 5001;
pub const MAC_ADDRESS: [u8; 6] = [0x02, 0x00, 0x4d, 0x49, 0x43, 0x01];
