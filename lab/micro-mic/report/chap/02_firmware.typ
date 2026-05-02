= Firmware Architecture

The firmware is a `no_std` Rust application built with RTIC 2 on the Cortex-M7
core of the STM32H755. The project keeps all real-time acquisition and network
transmission inside the MCU. The PC side only receives UDP packets and performs
visualization.

The current firmware has four main responsibilities:

- generate and measure a 2.2 MHz reference clock,
- acquire two high-rate analog channels and one low-rate voltage channel,
- capture a digital PDM microphone through SPI and produce a PCM-like stream,
- transmit status and sample frames to the PC over a direct Ethernet link.

The firmware uses Rust 2024, `stm32h7xx-hal`, RTIC, and `smoltcp`. Most work is
performed in RTIC `idle`, while SysTick provides the millisecond time base and
the Ethernet interrupt services the MAC.

== Hardware Peripherals

=== Clock Generation and Capture

`TIM1` generates the external clock on `PA8`. The configured frequency is
`2_200_000 Hz`, with the PWM duty cycle set to half of the timer maximum. This
signal clocks the PDM microphone and is also routed to `PA0` for measurement.

`TIM2` measures the clock on `PA0` in PWM-input mode. `CCR1` captures the period
and `CCR2` captures the high time, allowing the firmware to report frequency and
duty cycle in the low-rate telemetry packet. The measured duty cycle is encoded
in permyriad units, so `5000` represents 50.00%.

=== Analog Inputs

The two high-rate analog channels are sampled by ADC peripherals triggered from
`TIM6`:

- channel `1`: `PC0`, acquired with `ADC1`,
- channel `3`: `PC2`, acquired with `ADC3`.

Both ADCs run at 16-bit resolution and are triggered by `TIM6 TRGO` at
`200_000 samples/s`. Each DMA frame contains `704` samples, so each channel
produces one audio packet approximately every 3.52 ms.

`PA3` is sampled separately through `ADC2` in the low-rate status loop. This
channel is intended for slowly changing voltage measurements and is included in
the `MMIC` telemetry packet every 10 ms.

=== PDM Digital Microphone

The PDM microphone is captured through `SPI1` in slave receive mode:

- `PA5`: `SPI1_SCK`, connected to the copied 2.2 MHz clock,
- `PB5`: `SPI1_MOSI`, connected to the microphone PDM data output.

`SPI1` is configured as an 8-bit, receive-only slave using Motorola SPI mode
with idle-low clock and first-edge sampling. RX DMA is enabled and attached to
`DMA1 Stream2`. The raw DMA frame contains `4048` bytes, equivalent to `32384`
PDM bits.

The channel id used for the decoded PDM stream is `4`. The stream sample rate is
derived from the microphone clock and decimation factor:

```text
2_200_000 Hz / 46 = 47_826 Hz
```

=== Ethernet

The firmware uses the board LAN8742A PHY in RMII mode. Ethernet DMA descriptors
are placed in SRAM3, which is required on this dual-core H7 device for reliable
ETH DMA access.

The network is configured as a fixed direct link:

```text
MCU IP:      192.168.88.99
PC IP:       192.168.88.2
MCU UDP:     5000
PC UDP:      5001
MAC address: 02:00:4d:49:43:01
```

The firmware sends unidirectional UDP telemetry to the PC. `smoltcp` is used for
packet construction and socket management. UDP checksums are disabled in the
device capabilities, which produces an IPv4 UDP checksum value of zero. This is
valid for IPv4 and avoids the invalid checksum behavior observed with the
current HAL and Ethernet path.

== Acquisition and Buffering

All high-rate acquisition paths use double-buffered peripheral-to-memory DMA.
The inactive DMA buffer is processed only after the transfer-complete flag is
set. The firmware then immediately returns ownership of the buffer to DMA and
sends the processed data over Ethernet.

The analog channels use two independent DMA streams:

- `DMA1 Stream0`: `ADC1` samples from `PC0`,
- `DMA1 Stream1`: `ADC3` samples from `PC2`.

The PDM microphone uses a third independent stream:

- `DMA1 Stream2`: `SPI1 RX` bytes from `PB5`.

Each high-rate packet contains `704` `u16` samples. For analog channels these
samples are raw ADC values. For the PDM channel they are the result of the
firmware PDM filter and decimator.

If a buffer is completed again while the CPU is still processing the previous
inactive buffer, the corresponding `MAUD` packet carries a DMA overrun flag.
This makes late processing visible to the receiver without stopping acquisition.

== Signal Processing

The analog signal path does not perform DSP in the MCU. It forwards raw 16-bit
ADC samples with per-channel sequence numbers and sample indices.

The current PDM path uses a third-order sinc FIR decimator. The filter is built
as the convolution of three rectangular windows, each with `46` input samples,
which produces `136` FIR taps. The firmware keeps `135` bits of filter history
between DMA frames so that packet boundaries do not reset the filter state.

Each PDM bit is converted to a signed sample: one-bits are `+1` and zero-bits
are `-1`. For each output sample, the FIR is evaluated at the current decimated
position, normalized by its DC gain, and scaled into the unsigned 16-bit output
range. The decimation factor remains `46`, so the output stream remains
`47_826 samples/s`.

The previous implementation used a simple rectangular decimator. It summed only
the `46` PDM bits belonging to the current output sample, using the same `+1`
and `-1` mapping, and then scaled the sum directly to `u16`. That version was
useful for validating SPI capture and packet transport, but it provided weaker
out-of-band PDM noise rejection. It is kept here as a reference point for
comparing earlier measurements against the current FIR-filtered stream.

== Networking Protocol

The firmware sends two packet types over UDP.

=== `MMIC` Status Packet

`MMIC` is the low-rate telemetry packet. It is sent every `10 ms`, so the nominal
rate is 100 Hz. The packet length is fixed at `56` bytes.

The packet contains:

- magic bytes `MMIC`,
- protocol version,
- packet length,
- sequence number,
- firmware millisecond timestamp,
- three low-rate ADC/status values,
- digital input state,
- Ethernet link state,
- configured clock frequency and voltage reference,
- measured clock frequency, period, high time, duty cycle, and capture flags.

Bytes `52..56` carry an implementation-specific PDM diagnostic word. In the
current firmware the low bits indicate SPI/DMA status and the upper 16 bits
contain the number of one-bits seen in the last PDM DMA frame. This is useful
for distinguishing a real PDM bitstream from a stuck-zero or stuck-one input.

=== `MAUD` Audio Packet

`MAUD` is the high-rate sample packet. It has a fixed 32-byte header followed by
`704` little-endian `u16` samples, for a total packet size of `1440` bytes.

The header contains:

- magic bytes `MAUD`,
- protocol version,
- header length and packet length,
- per-channel sequence number,
- firmware millisecond timestamp,
- first sample index,
- sample rate in Hz,
- channel id,
- sample width,
- flags.

The current channel map is:

- channel `1`: `PC0`, analog audio, `200_000 samples/s`,
- channel `3`: `PC2`, analog audio, `200_000 samples/s`,
- channel `4`: PDM microphone decoded from `SPI1`, `47_826 samples/s`.

The sequence number is per channel. The receiver can detect packet loss by
checking that each channel sequence increments by one. The first sample index
allows a receiver to place packets on a continuous sample timeline even when
different channels are transmitted as separate packets.

== Runtime Behavior

After initialization, the firmware remains in the RTIC idle loop. Each iteration:

+ polls the Ethernet PHY link state,
+ polls the `smoltcp` interface,
+ checks whether each DMA-backed acquisition path has a completed buffer,
+ encodes and sends ready `MAUD` packets,
+ sends a periodic `MMIC` packet every 10 ms.

The status LED reflects Ethernet link state. When the link is up, the LED is
driven continuously; when the link is down, it blinks from the millisecond time
base.

The firmware is designed for a direct MCU-to-PC Ethernet connection. It does
not use DHCP, DNS, routing, or retransmission. Packet timing and loss recovery
are delegated to the receiver through sequence numbers and timestamps.

== Limitations and Next Steps

The firmware currently prioritizes deterministic acquisition and transport over
audio post-processing. The main limitations are:

- the PDM filter is currently a fixed sinc FIR without DC removal or gain
  calibration,
- ADC values are reported as raw 16-bit samples using a nominal `3300 mV`
  reference,
- UDP transport is intentionally lossy and relies on receiver-side gap
  detection,
- the Ethernet and acquisition rates are fixed at compile time in `config.rs`.

The most useful firmware improvements would be calibrated voltage conversion,
PDM gain/DC conditioning, and a small runtime configuration protocol for sample
rates and channel enables.
