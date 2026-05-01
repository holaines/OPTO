use crate::{clock_capture::ClockMeasurement, config};

pub const PACKET_LEN: usize = 56;
pub const AUDIO_HEADER_LEN: usize = 32;
pub const AUDIO_PACKET_LEN: usize = AUDIO_HEADER_LEN + config::AUDIO_FRAME_SAMPLES * 2;

pub fn encode(
    sequence: u32,
    time_ms: u32,
    adc_raw: [u16; 3],
    digital: bool,
    link_up: bool,
    clock: ClockMeasurement,
) -> [u8; PACKET_LEN] {
    let mut packet = [0u8; PACKET_LEN];

    packet[0..4].copy_from_slice(b"MMIC");
    packet[4] = 2;
    packet[5] = 0;
    packet[6..8].copy_from_slice(&(PACKET_LEN as u16).to_le_bytes());
    packet[8..12].copy_from_slice(&sequence.to_le_bytes());
    packet[12..16].copy_from_slice(&time_ms.to_le_bytes());
    packet[16..18].copy_from_slice(&adc_raw[0].to_le_bytes());
    packet[18..20].copy_from_slice(&adc_raw[1].to_le_bytes());
    packet[20..22].copy_from_slice(&adc_raw[2].to_le_bytes());
    packet[22] = u8::from(digital);
    packet[23] = u8::from(link_up);
    packet[24..28].copy_from_slice(&config::CLOCK_HZ.to_le_bytes());
    packet[28..30].copy_from_slice(&config::VREF_MV.to_le_bytes());
    packet[30..32].copy_from_slice(&(config::SAMPLE_PERIOD_MS as u16).to_le_bytes());

    packet[32..36].copy_from_slice(&clock.frequency_hz.to_le_bytes());
    packet[36..40].copy_from_slice(&clock.period_ticks.to_le_bytes());
    packet[40..44].copy_from_slice(&clock.high_ticks.to_le_bytes());
    packet[44..48].copy_from_slice(&clock.timer_clock_hz.to_le_bytes());
    packet[48..50].copy_from_slice(&clock.duty_permyriad.to_le_bytes());
    packet[50] = clock.flags;
    packet[51] = clock.missed_polls;

    packet
}

pub fn encode_audio(
    packet: &mut [u8; AUDIO_PACKET_LEN],
    sequence: u32,
    time_ms: u32,
    first_sample_index: u64,
    sample_rate_hz: u32,
    channel_id: u8,
    flags: u16,
    samples: &[u16; config::AUDIO_FRAME_SAMPLES],
) {
    packet.fill(0);

    packet[0..4].copy_from_slice(b"MAUD");
    packet[4] = 1;
    packet[5] = AUDIO_HEADER_LEN as u8;
    packet[6..8].copy_from_slice(&(AUDIO_PACKET_LEN as u16).to_le_bytes());
    packet[8..12].copy_from_slice(&sequence.to_le_bytes());
    packet[12..16].copy_from_slice(&time_ms.to_le_bytes());
    packet[16..24].copy_from_slice(&first_sample_index.to_le_bytes());
    packet[24..28].copy_from_slice(&sample_rate_hz.to_le_bytes());
    packet[28] = channel_id;
    packet[29] = 16;
    packet[30..32].copy_from_slice(&flags.to_le_bytes());

    for (index, sample) in samples.iter().enumerate() {
        let offset = AUDIO_HEADER_LEN + index * 2;
        packet[offset..offset + 2].copy_from_slice(&sample.to_le_bytes());
    }
}
