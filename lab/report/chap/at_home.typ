#import "@preview/acrostiche:0.7.0": *

= At home
== Introduction

We noticed that the adquisition of these signals could be done with an #acr("MCU"). As we had a dual-core STM32H7 (Nucleo-H755ZI-Q board), with a powerful M7 core running up to 400MHz and three 16 bit #acr("ADC"), we thought it could be a good idea to try to develope the acquisition system with it.

The architecture of the system consists of an STM32H7 connected to a PC through Ethernet, which represents the data on a python frontend. Setup of the protoboard with sensors and signal conditioners can be seen in @setup_ah, where we can distinguish blocks of alimentation, filtering, conditioning and adquisition. There are also 2 big capacitors connected between the 1.8V line and gnd to stabilize the voltage of the board.

#figure(
  image("../img/at-home/setup.jpeg", width: 94%),
  caption: [Setup of the protoboard with sensors and signal conditioners.]
)<setup_ah>

== Firmware Architecture

The firmware is a `no_std` Rust application built with #acr("RTIC") 2 framework on the Cortex-M7
core of the STM32H755. The project keeps all real-time acquisition and network
transmission inside the MCU. The PC side only receives #acr("UDP") packets and performs
visualization.

The current firmware has four main responsibilities:

- Generate and measure a 2.2 MHz reference clock.
- Acquire two high-rate analog channels and one low-rate voltage channel.
- Capture a digital #acr("PDM") microphone through SPI and produce a PCM-like stream.
- Transmit status and sample frames to the PC over a direct Ethernet link.

The firmware uses Rust 2024, `stm32h7xx-hal`, RTIC, and `smoltcp`. Most work is
performed in RTIC `idle`, while SysTick provides the millisecond time base and
the Ethernet interrupt services the MAC.

=== Hardware Peripherals

==== Clock Generation and Capture

`TIM1` generates the external clock on `PA8`. The configured frequency is
`2_200_000 Hz`, with the #acr("PWM") duty cycle set to half of the timer maximum. This
signal clocks the #acr("PDM") microphone and is also routed to `PA0` for measurement.

`TIM2` measures the clock on `PA0` in #acr("PWM")-input mode. `CCR1` captures the period
and `CCR2` captures the high time, allowing the firmware to report frequency and
duty cycle in the low-rate telemetry packet. The measured duty cycle is encoded
in permyriad units, so `5000` represents 50.00%.

==== Analog Inputs

The two high-rate analog channels are sampled by #acr("ADC") peripherals triggered from `TIM6`:

- channel `1`: `PC0`, acquired with `ADC1`,
- channel `3`: `PC2`, acquired with `ADC3`.

Both #acrpl("ADC") run at 16-bit resolution and are triggered by `TIM6 TRGO` at
`200_000 samples/s`. Each #acr("DMA") frame contains `704` samples, so each channel
produces one audio packet approximately every 3.52 ms.

`PA3` is sampled separately through `ADC2` in the low-rate status loop. This
channel is intended for slowly changing voltage measurements and is included in
the `MMIC` telemetry packet every 10 ms.

==== PDM Digital Microphone

The #acr("PDM") microphone is captured through `SPI1` in slave receive mode:

- `PA5`: `SPI1_SCK`, connected to the 2.2 MHz clock,
- `PB5`: `SPI1_MOSI`, connected to the microphone #acr("PDM") data output.

`SPI1` is configured as an 8-bit, receive-only slave using Motorola #acr("SPI") mode
with idle-low clock and first-edge sampling. RX #acr("DMA") is enabled and attached to `DMA1 Stream2`. The raw #acr("DMA") frame contains `4048` bytes, equivalent to `32384` #acr("PDM") bits.

The channel id used for the decoded #acr("PDM") stream is `4`. The stream sample rate is derived from the microphone clock and decimation factor:

```text
2_200_000 Hz / 46 = 47_826 Hz
```

==== Ethernet

The firmware uses the board LAN8742A PHY in RMII mode. Ethernet #acr("DMA") descriptors are placed in SRAM3, which is required on this dual-core H7 device for reliable ETH #acr("DMA") access.

The network is configured as a fixed direct link:

```text
MCU IP:      192.168.88.99
PC IP:       192.168.88.2
MCU UDP:     5000
PC UDP:      5001
MAC address: 02:00:4d:49:43:01
```

The firmware sends unidirectional #acr("UDP") telemetry to the PC. `smoltcp` is used for packet construction and socket management. #acr("UDP") checksums are disabled in the device capabilities, which produces an IPv4 #acr("UDP") checksum value of zero. This is valid for IPv4 and avoids the invalid checksum behavior observed with the current HAL and Ethernet path.

=== Acquisition and Buffering

All high-rate acquisition paths use double-buffered peripheral-to-memory #acr("DMA").
The inactive #acr("DMA") buffer is processed only after the transfer-complete flag is
set. The firmware then immediately returns ownership of the buffer to #acr("DMA") and
sends the processed data over Ethernet.

The analog channels use two independent #acr("DMA") streams:

- `DMA1 Stream0`: `ADC1` samples from `PC0`,
- `DMA1 Stream1`: `ADC3` samples from `PC2`.

The #acr("PDM") microphone uses a third independent stream:

- `DMA1 Stream2`: `SPI1 RX` bytes from `PB5`.

Each high-rate packet contains `704` `u16` samples. For analog channels these
samples are raw ADC values. For the #acr("PDM") channel they are the result of the
firmware #acr("PDM") filter and decimator.

If a buffer is completed again while the CPU is still processing the previous
inactive buffer, the corresponding `MAUD` packet carries a #acr("DMA") overrun flag.
This makes late processing visible to the receiver without stopping acquisition.

=== Signal Processing

The analog signal path does not perform DSP in the MCU. It forwards raw 16-bit
ADC samples with per-channel sequence numbers and sample indices.

The current #acr("PDM") path uses a third-order sinc #acr("FIR") decimator. The filter is built as the convolution of three rectangular windows, each with `46` input samples, which produces `136` #acr("FIR") taps. The firmware keeps `135` bits of filter history between #acr("DMA") frames so that packet boundaries do not reset the filter state.

Each #acr("PDM") bit is converted to a signed sample: one-bits are `+1` and zero-bits are `-1`. For each output sample, the #acr("FIR") is evaluated at the current decimated position, normalized by its DC gain, and scaled into the unsigned 16-bit output
range. The decimation factor remains `46`, so the output stream remains
`47_826 samples/s`.

A previous implementation used a simple rectangular decimator. It summed only the `46` #acr("PDM") bits belonging to the current output sample, using the same `+1` and `-1` mapping, and then scaled the sum directly to `u16`. That version was useful for validating #acr("SPI") capture and packet transport, but it provided weaker out-of-band #acr("PDM") noise rejection. It is kept here as a reference point for comparing earlier measurements against the current #acr("FIR")-filtered stream.

=== Networking Protocol

The firmware sends two packet types over #acr("UDP").

==== `MMIC` Status Packet

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

Bytes `52..56` carry an implementation-specific #acr("PDM") diagnostic word. In the
current firmware the low bits indicate SPI/#acr("DMA") status and the upper 16 bits
contain the number of one-bits seen in the last #acr("PDM") #acr("DMA") frame. This is useful
for distinguishing a real #acr("PDM") bitstream from a stuck-zero or stuck-one input.

==== `MAUD` Audio Packet

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
- channel `4`: #acr("PDM") microphone decoded from `SPI1`, `47_826 samples/s`.

The sequence number is per channel. The receiver can detect packet loss by
checking that each channel sequence increments by one. The first sample index allows a receiver to place packets on a continuous sample timeline even when
different channels are transmitted as separate packets.

=== Runtime Behavior

After initialization, the firmware remains in the RTIC idle loop. Each iteration:

+ polls the Ethernet PHY link state,
+ polls the `smoltcp` interface,
+ checks whether each #acr("DMA")-backed acquisition path has a completed buffer,
+ encodes and sends ready `MAUD` packets,
+ sends a periodic `MMIC` packet every 10 ms.


The firmware is designed for a direct MCU-to-PC Ethernet connection. It does not use DHCP, DNS, routing, or retransmission. Packet timing and loss recovery
are delegated to the receiver through sequence numbers and timestamps.

=== Limitations and Next Steps

The firmware currently prioritizes deterministic acquisition and transport over
audio post-processing. The main limitations are:

- the #acr("PDM") filter is currently a fixed sinc #acr("FIR") without DC removal or gain
  calibration,
- ADC values are reported as raw 16-bit samples using a nominal `3300 mV`
  reference,
- #acr("UDP") transport is intentionally lossy and relies on receiver-side gap
  detection,
- the Ethernet and acquisition rates are fixed at compile time in `config.rs`.

The most useful firmware improvements would be calibrated voltage conversion,
#acr("PDM") gain/DC conditioning, and a small runtime configuration protocol for sample
rates and channel enables.


== PC Visualizer Frontend

The PC Visualizer acts as the central hub for the home-built oscilloscope, providing a high-performance, real-time graphical interface built on Python and PyQtGraph. It receives combined `MMIC` and `MAUD` UDP streams and reconstructs them into a unified, cross-domain visual layout.

#figure(
  image("../img/at-home/overview.png", width: 90%),
  caption: [PC Visualizer Frontend.]
)<frontend>

=== Architecture & Dynamic Memory Management
To maintain high frame rates while handling hundreds of thousands of samples per second, the visualizer leverages efficient NumPy ring buffers. Instead of hardcoding arrays for each potential audio source, the system employs Dynamic Buffer Allocation. 

When a `MAUD` packet arrives, the visualizer dynamically extracts the `channel_id` and the `sample_rate_hz` from the packet header. If the channel is unseen (e.g., the newly introduced digital #acr("PDM") stream on SPI1), the software automatically instantiates a new 1,000,000-sample high-speed buffer for it. This allows the system to scale to an arbitrary number of audio streams without code modifications, keeping the memory footprint proportional strictly to the active streams.

=== Universal Trigger Engine
We implemented a Universal Trigger Engine that performs mathematically precise cross-domain time synchronization.

When a trigger event (such as a rising edge passing $1.65"V"$) is detected in the high-speed 200 kHz audio array, the engine calculates the exact physical timestamp of that event relative to the current buffer head. This relative time offset is then mathematically projected backwards into the low-speed 100 Hz telemetry arrays. The result is that all traces—whether sampled at 100 Hz or 200 kHz—are plotted on the screen perfectly aligned to the exact same physical instant in time.

=== Time Domain Oscilloscope
The primary user interface is inspired in comercial oscilloscopes. The X-axis is strictly controlled by a Time Base knob (e.g., $10 "ms/div"$, $2 "ms/div"$), allowing users to zoom deep into the high-speed audio waveforms while maintaining synchronization with the slow environmental sensors.

To prevent application crashes or visual glitches during extreme zoom, the plotting engine includes strict boundary safety clamping. If the calculated trigger slice attempts to index negative regions (e.g., immediately after application startup before the buffer fills), or queries data that hasn't arrived over UDP yet, the slice is safely clamped to available bounds. 

#figure(
  image("../img/at-home/time_domain.png", width: 100%),
  caption: [Time Domain Interface demonstrating synced analog and PDM audio traces.]
)<time_domain>

==== Frequency Domain Analysis
To prevent calculating an #acr("FFT") with an insufficient window size, the #acr("FFT") window size is strictly decoupled from the Time Domain zoom level.

By enforcing a user-configurable, fixed window length (defaulting to $N = 65,536$ samples), the #acr("FFT") engine continuously computes over a stable $~0.32$ second history. This guarantees an ultra-high, non-fluctuating frequency resolution of roughly $3 "Hz"$ per bin regardless of the time-base scale.

#figure(
  image("../img/at-home/freq.png", width: 100%),
  caption: [Simultaneous Multi-FFT overlay showing distinct frequency peaks.]
)

Furthermore, the Math panel supports Simultaneous Multi-#acr("FFT") overlays, allowing the user to select any combination of active channels (e.g., `Ch 1` and `Ch 3 PDM`) and overlay their frequency spectrums in real-time on the same graph for immediate harmonic comparisons.

== Conclusion

The development of this project successfully demonstrates a high-performance, real-time mixed-signal oscilloscope built from scratch, applied to the acquisition of audio signals from MEMS microphones. By leveraging DMA-backed STM32H7 hardware and a custom UDP transport protocol (`MMIC`/`MAUD`), we achieved stable, high-bandwidth streaming. On the PC side, the Python Visualizer provides a robust interface featuring dynamic memory management, precise cross-domain synchronization, and decoupled, high-resolution #acr("FFT") analysis. Evaluating this end-to-end system allows us to draw key conclusions regarding both the capabilities and the hardware limitations of our prototype.

=== Power Supply Conditioning via LED Voltage Drop

Lacking a dedicated low-noise voltage regulator, we stepped down the MCU's 3.3V supply using a simple LED and series resistor to power the MEMS microphones. However, as @idle reveals, this makeshift power delivery introduces significant power supply noise into the signal. To mitigate this and stabilize the reference voltage, we placed decoupling capacitors directly at the microphone power inputs, which act as a rudimentary low-pass filter to clean the supply rails.

#figure(
  image("../img/at-home/idle.png", width: 100%),
  caption: [Idle state of the oscilloscope demonstrating residual noise floor.]
)<idle>

=== Analog Audio Capture Limitations

Unlike the laboratory setup that utilized precision instrumentation amplifiers (such as the `INA131`), this prototype connects the raw analog audio signals directly to the MCU's ADCs. Consequently, the signals suffer from a poor signal-to-noise ratio (SNR). The tiny voltage swings of the unamplified microphones fail to utilize the full dynamic range of the 16-bit ADC, severely limiting the vertical resolution and magnifying quantization noise.

=== Analog vs. Digital Processing Paradigms

This mixed-signal architecture provides a direct comparative analysis between analog and digital audio pathways. We observed that the digital #acr("PDM") audio stream exhibits significantly greater immunity to environmental interference and board-level noise compared to the unshielded analog traces. Furthermore, processing the signal in the digital domain offers greater flexibility and precision. Nevertheless, the digital implementation is not flawless, since the digital decimation filters introduce specific harmonic distortions not present in the analog path, as evidenced by the frequency spectrum in @fft_result.

#figure(
  image("../img/at-home/fir_distorsion.png", width: 100%),
  caption: [FIR Filter distortion visible in the frequency domain.]
)<fft_result>

To recover PCM audio from the PDM bitstream, we evaluated two digital filtering strategies. The initial approach employed a naive rectangular decimator (a simple moving average), which proved ineffective at suppressing out-of-band quantization noise. We subsequently upgraded to a third-order Sinc FIR filter (acting as a robust low-pass filter). The Sinc filter yielded markedly superior noise attenuation and signal reconstruction, as demonstrated by the cleaner 600 Hz sinewave profiles in @decimator and @fir_vs_rect.

#figure(
  image("../img/at-home/decimator.jpeg", width: 100%),
  caption: [600 Hz sinewave processed with a naive rectangular decimator.]
)<decimator>

#figure(
  image("../img/at-home/fir_vs_rect.png", width: 100%),
  caption: [600 Hz sinewave processed with the improved Sinc filter.]
)<fir_vs_rect>