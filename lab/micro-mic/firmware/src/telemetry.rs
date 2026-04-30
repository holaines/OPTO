use crate::config;

pub const PACKET_LEN: usize = 32;

pub fn encode(
    sequence: u32,
    time_ms: u32,
    adc_raw: [u16; 3],
    digital: bool,
    link_up: bool,
) -> [u8; PACKET_LEN] {
    let mut packet = [0u8; PACKET_LEN];

    packet[0..4].copy_from_slice(b"MMIC");
    packet[4] = 1;
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

    packet
}
