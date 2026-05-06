= FPGA and digital acquisition

== Purpose of the digital acquisition stage

The FPGA is the central digital element of the proposed acquisition system. Its function is not only to receive digital data from the ADCs, but to guarantee that the complete 160-channel microphone array is acquired with a common timing reference and that the data are delivered to the host computer in an ordered and lossless way.

The complete system contains 80 dual-frequency MEMS microphones. Each MEMS provides two analog outputs, one for the low-frequency branch and one for the high-frequency branch. Therefore, the digital acquisition system must handle:

$ 80 " MEMS" dot 2 " outputs/MEMS" = 160 " channels" $

The selected acquisition integrated circuit is the AD7606C-18. Since each AD7606C-18 contains 8 simultaneous-sampling ADC channels, the required number of ADC devices is:

$ 160 " channels" / 8 " channels/ADC" = 20 " ADCs" $

The adopted distribution is the same as in the global architecture:

#figure(
  align(center)[
    #box(inset: 8pt, stroke: 0.7pt, radius: 4pt)[
      #grid(
        columns: (1fr,),
        row-gutter: 7pt,
        align: center,
        [#strong[10 acquisition zones]],
        [$arrow.b$],
        [#strong[Each zone: 8 MEMS microphones]],
        [$arrow.b$],
        [
          #grid(
            columns: (1fr, 1fr),
            column-gutter: 20pt,
            align: center,
            [#box(inset: 6pt, stroke: 0.7pt, radius: 4pt)[8 LF outputs \ $arrow.r$ \ 1 AD7606C-18]],
            [#box(inset: 6pt, stroke: 0.7pt, radius: 4pt)[8 HF outputs \ $arrow.r$ \ 1 AD7606C-18]],
          )
        ],
        [$arrow.b$],
        [#strong[20 AD7606C-18 devices connected to one Artix-7 FPGA]],
      )
    ]
  ],
  caption: [Digital acquisition distribution for the 80 dual-frequency MEMS microphones.]
)<fig:fpga-distribution>

The FPGA must perform the following tasks:

- Generate the common sampling timing for all ADCs.
- Control the 20 AD7606C-18 devices through CONVST, RESET, CS, SCLK and configuration signals.
- Capture the conversion results from the ADC serial outputs.
- Associate every acquired frame with a timestamp.
- Reorder the samples by zone, frequency branch and channel number.
- Build data frames with header, payload and status information.
- Store the frames in a FIFO to avoid data loss during communication stalls.
- Stream the data to the PC or remote DAQ interface.

== Justification of the Artix-7 FPGA

An FPGA is preferred over a microcontroller because this acquisition problem is strongly parallel and timing-critical. A microcontroller would normally control the ADCs sequentially through software instructions, interrupts or DMA transactions. This can introduce variable latency and makes the synchronization of 20 converters more difficult. In contrast, an FPGA implements the control logic as hardware. Therefore, it can generate deterministic timing signals and read several digital interfaces at the same time.

The selected FPGA family is Artix-7. It is appropriate for this system for four main reasons.

#figure(
  table(
    columns: (1.4fr, 2.3fr, 3.2fr),
    inset: 6pt,
    align: left,
    table.header([Criterion], [Relevant Artix-7 characteristic], [Impact on this project]),

    [Deterministic timing],
    [Hardware logic, clocked counters, state machines and parallel I/O.],
    [The sampling pulse, ADC readout sequence and timestamp generation are not affected by software latency.],

    [Parallel acquisition],
    [Many user I/O pins and configurable SelectIO banks.],
    [The FPGA can read the digital outputs of the 20 ADCs in parallel instead of polling them one by one.],

    [Electrical compatibility],
    [HR I/O banks can operate with several VCCO levels, including common 1.8 V, 2.5 V and 3.3 V logic families.],
    [The AD7606C-18 VDRIVE supply can be matched to the FPGA I/O bank voltage, avoiding level translators.],

    [Environmental margin],
    [Industrial versions support junction temperatures down to -40 °C and up to 100 °C; other grades extend this range.],
    [The FPGA is compatible with the wind-tunnel temperature range provided that the PCB thermal design keeps the junction temperature within limits.],
  ),
  caption: [Reasons for using an Artix-7 FPGA as the digital acquisition core.]
)<table:artix-justification>

The Artix-7 is therefore selected as the digital timing and concentration device. The exact package must expose enough user I/O pins for the selected ADC interface and for the PC communication interface. For this reason, the final PCB implementation must verify the user I/O count in the Xilinx package and pinout documentation for the selected part, for example XC7A35T-1FTG256I.

This distinction is important: the Artix-7 family is electrically and functionally suitable, but the final package must still be checked against the I/O budget calculated in @sec:fpga-io-budget.

== ADC digital interface strategy

The AD7606C-18 can be read through a parallel or serial digital interface. For this project, the serial interface is more convenient because 20 ADCs have to be connected to the same FPGA. A full parallel bus per ADC would require too many FPGA pins and would make the PCB routing more complex.

In serial mode, the ADC sends the conversion results through digital output pins called DOUT lines. A DOUT line is a serial data output line: it transmits the bits of the conversion result from the ADC to the FPGA, synchronized by the serial clock SCLK.

For one AD7606C-18 device, each acquisition frame contains:

$ 8 " channels" dot 18 " bits/channel" = 144 " bits" $

If only one DOUT line is used, the 144 bits must be shifted sequentially through that single line. If two DOUT lines are used, the data are divided between two outputs. If four DOUT lines are used, the transfer is divided between four outputs. Therefore, using more DOUT lines reduces the readout time but increases the number of FPGA pins.

#figure(
  table(
    columns: (1.1fr, 1.2fr, 1.4fr, 2.8fr),
    inset: 6pt,
    align: left,
    table.header([DOUT per ADC], [ADC DOUT pins for 20 ADCs], [SCLK cycles per ADC frame], [Comment]),

    [1],
    [$20 dot 1 = 20$],
    [$144$],
    [Minimum number of pins, but longest readout time. Useful only if the sampling frequency is relaxed.],

    [2],
    [$20 dot 2 = 40$],
    [$72$],
    [Good compromise between FPGA pin count and readout time. Recommended baseline option.],

    [4],
    [$20 dot 4 = 80$],
    [$36$],
    [Higher pin count, but much larger timing margin. Recommended if the package has enough I/O.],

    [8],
    [$20 dot 8 = 160$],
    [$18$],
    [Fastest readout, but excessive I/O usage for this design. Not selected.],
  ),
  caption: [Comparison of possible AD7606C-18 serial readout widths.]
)<table:dout-options>

The proposed baseline is #strong[2 DOUT lines per ADC]. This option keeps the ADC interface at a reasonable I/O count while allowing the required high-frequency sampling rate. If the final package pinout has enough available I/O, a #strong[4 DOUT configuration] can be selected to increase timing margin.

== FPGA I/O budget <sec:fpga-io-budget>

The I/O budget depends mainly on the number of DOUT lines selected per ADC and on the host communication interface. The following calculation assumes a shared sampling and clocking structure:

- One common CONVST signal distributed to all ADCs.
- One common RESET signal.
- One common SCLK signal.
- One common SDI/MOSI configuration line.
- Individual CS signals, one for each ADC.
- Individual BUSY signals, one for each ADC, to detect desynchronization or ADC faults.
- Two DOUT lines per ADC as the baseline option.

#figure(
  table(
    columns: (1.8fr, 1.1fr, 3.6fr),
    inset: 6pt,
    align: left,
    table.header([Signal group], [Pins], [Purpose]),

    [CONVST],
    [1],
    [Common conversion start. Defines the sampling instant for the complete array.],

    [RESET],
    [1],
    [Global reset for the 20 ADCs.],

    [SCLK],
    [1],
    [Common serial readout clock.],

    [SDI / MOSI],
    [1],
    [Configuration data from FPGA to selected ADC.],

    [CS],
    [20],
    [Individual chip-select signals. They allow independent configuration and diagnosis.],

    [BUSY],
    [20],
    [Individual conversion-busy signals. They allow the FPGA to verify that every ADC completed the conversion.],

    [DOUT],
    [$20 dot 2 = 40$],
    [Two serial data outputs per ADC, read in parallel by the FPGA.],

    [Static or semi-static configuration pins],
    [5--8],
    [PAR/SER, oversampling pins, range-related pins and mode pins. Some can be fixed by hardware.],

    [Host interface],
    [20--40],
    [USB 3.0 FIFO, Ethernet interface or equivalent output interface.],

    [Clocks, debug and spare pins],
    [10--15],
    [External oscillator, status LEDs, test points, trigger input/output and design margin.],
  ),
  caption: [Estimated FPGA I/O budget for the 2-DOUT-per-ADC baseline implementation.]
)<table:io-budget>

The ADC-side I/O count for the baseline case is approximately:

$ N_"ADC I/O" = 1 + 1 + 1 + 1 + 20 + 20 + 40 + 8 = 92 " pins" $

Adding the PC interface and debug margin:

$ N_"total I/O" approx 92 + (20 " to " 40) + (10 " to " 15) = 122 " to " 147 " pins" $

If 4 DOUT lines per ADC are used, the DOUT contribution increases from 40 pins to 80 pins:

$ N_"total I/O, 4-DOUT" approx 162 " to " 187 " pins" $

Therefore, the 2-DOUT option is the safest baseline for the selected Artix-7 package. The 4-DOUT option is technically better in timing, but it must only be used if the final package exposes enough user I/O after assigning power, configuration, clock and communication pins.

== Synchronization strategy

The most important digital requirement is synchronization. In an acoustic array, the relative delay between channels affects phase measurements and therefore affects beamforming, delay estimation and spatial reconstruction. The system must not only digitize the 160 channels; it must digitize them with a common time reference.

The synchronization is achieved by distributing a common CONVST signal from the FPGA to all 20 AD7606C-18 devices. The rising edge of CONVST defines the sampling instant. Since each AD7606C-18 performs simultaneous sampling on its 8 channels, and all ADCs receive the same CONVST edge, the full 160-channel frame is associated with one global sampling instant.

#figure(
  align(center)[
    #box(inset: 8pt, stroke: 0.7pt, radius: 4pt)[
      #grid(
        columns: (1fr,),
        row-gutter: 6pt,
        align: center,
        [#strong[FPGA timing generator]],
        [$arrow.b$],
        [Common CONVST edge],
        [$arrow.b$],
        [20 AD7606C-18 sample simultaneously],
        [$arrow.b$],
        [BUSY high during conversion],
        [$arrow.b$],
        [BUSY low: conversion completed],
        [$arrow.b$],
        [Parallel serial readout of the 20 ADCs],
        [$arrow.b$],
        [Timestamp + frame building + FIFO],
      )
    ]
  ],
  caption: [Timing sequence controlled by the FPGA.]
)<fig:fpga-timing-sequence>

The following point is essential: the physical sampling time is determined by the CONVST edge, not by the later digital readout order. The ADC data can be read a few microseconds after conversion without creating inter-channel sampling delay, as long as all devices sampled from the same CONVST event and the frame builder keeps the samples grouped under the same timestamp.

To improve robustness, the FPGA monitors the BUSY signals. If one ADC does not release BUSY within the expected time window, the frame is marked with an error flag. This avoids silently accepting corrupted or incomplete data.

== ADC controller state machine

The FPGA implements one common ADC acquisition controller and 20 parallel serial receivers. The high-level state machine is:

#figure(
  table(
    columns: (1.2fr, 4.5fr),
    inset: 6pt,
    align: left,
    table.header([State], [Function]),

    [IDLE],
    [Wait until the next sampling tick generated from the FPGA sampling timer.],

    [START_CONVERSION],
    [Generate a common CONVST pulse for all ADCs and capture the timestamp counter.],

    [WAIT_BUSY],
    [Wait until all BUSY signals return to low. If a timeout occurs, set an ADC error flag.],

    [READ_ADC],
    [Generate SCLK and capture the DOUT streams from the 20 ADCs in parallel.],

    [ALIGN_SAMPLES],
    [Reconstruct 18-bit samples and assign them to zone, branch and channel indices.],

    [BUILD_FRAME],
    [Add header, frame counter, timestamp, status flags and payload length.],

    [WRITE_FIFO],
    [Write the complete frame into the asynchronous FIFO when there is enough space.],

    [ERROR],
    [Report timeout, FIFO overflow, CRC mismatch or synchronization loss.],
  ),
  caption: [FPGA acquisition controller state machine.]
)<table:adc-state-machine>

The individual serial receivers work in parallel. Each receiver captures the DOUT lines of one ADC and reconstructs the eight 18-bit samples. All receivers are triggered by the same global READ_ADC state, so the 20 ADCs are read in the same readout window.

== Readout timing calculation

The readout time must be shorter than the sampling period. For one AD7606C-18, the number of bits per frame is 144 bits. With 2 DOUT lines, the number of SCLK cycles is:

$ N_"cycles, 2-DOUT" = 144 / 2 = 72 " cycles" $

With 4 DOUT lines:

$ N_"cycles, 4-DOUT" = 144 / 4 = 36 " cycles" $

Assuming a conservative serial clock of 60 MHz, the readout time is:

$ t_"read, 2-DOUT" = 72 / (60 " MHz") = 1.2 mu s $

$ t_"read, 4-DOUT" = 36 / (60 " MHz") = 0.6 mu s $

The high-frequency branch must cover signals up to 100 kHz. A sampling frequency of 250 kS/s is selected for the HF branch because it is above the Nyquist minimum and leaves margin for anti-aliasing and spectral analysis:

$ f_"s,HF" = 250 " kS/s" quad => quad T_"s,HF" = 4 mu s $

Therefore, with 2 DOUT lines per ADC:

$ t_"read, 2-DOUT" = 1.2 mu s < T_"s,HF" = 4 mu s $

The low-frequency branch only needs to cover up to approximately 10 kHz. A sampling frequency of 50 kS/s is sufficient:

$ f_"s,LF" = 50 " kS/s" quad => quad T_"s,LF" = 20 mu s $

This gives even more timing margin.

#figure(
  table(
    columns: (1.4fr, 1.2fr, 1.4fr, 1.5fr, 1.5fr),
    inset: 6pt,
    align: left,
    table.header([Branch], [Selected $f_s$], [Sampling period], [2-DOUT readout], [Timing margin]),

    [HF],
    [250 kS/s],
    [4 µs],
    [1.2 µs],
    [Valid],

    [LF],
    [50 kS/s],
    [20 µs],
    [1.2 µs],
    [Large margin],
  ),
  caption: [Readout timing verification for the proposed 2-DOUT configuration.]
)<table:readout-timing>

This timing calculation justifies the 2-DOUT baseline. A 4-DOUT configuration can be kept as an upgrade path if a higher sampling frequency or extra timing margin is required.

== Timestamp and frame format

The FPGA includes a free-running timestamp counter. A 64-bit counter is proposed because it provides a very long time range even with a high-frequency FPGA system clock.

At every CONVST event, the current counter value is latched and stored as the timestamp of the complete 160-channel frame:

$ "timestamp"[k] = "counter value at CONVST edge"[k] $

This is preferable to timestamping the data at the end of the readout, because the relevant physical time is the instant at which the analog inputs were sampled.

The proposed frame structure is:

#figure(
  table(
    columns: (1.4fr, 4.2fr),
    inset: 6pt,
    align: left,
    table.header([Field], [Content]),

    [Sync word],
    [Fixed pattern used by the PC software to find the beginning of each frame.],

    [Frame counter],
    [Incremented at every acquisition. It allows detection of lost frames.],

    [Timestamp],
    [64-bit value captured at the CONVST edge.],

    [Mode field],
    [Sampling mode, LF/HF rate configuration, DOUT mode and ADC configuration version.],

    [Status flags],
    [BUSY timeout, FIFO overflow, ADC CRC error, synchronization error, reset event.],

    [Payload length],
    [Number of payload bytes.],

    [Payload],
    [Samples ordered by zone, branch and channel.],

    [CRC / checksum],
    [Optional integrity check for the complete frame.],
  ),
  caption: [Proposed digital frame format.]
)<table:frame-format>

The payload is ordered in a deterministic way:

#figure(
  align(center)[
    #box(inset: 8pt, stroke: 0.7pt, radius: 4pt)[
      #grid(
        columns: (1fr,),
        row-gutter: 4pt,
        align: left,
        [Zone 0: LF ch0...ch7, HF ch0...ch7],
        [Zone 1: LF ch0...ch7, HF ch0...ch7],
        [Zone 2: LF ch0...ch7, HF ch0...ch7],
        [...],
        [Zone 9: LF ch0...ch7, HF ch0...ch7],
      )
    ]
  ],
  caption: [Payload organization inside one acquisition frame.]
)<fig:payload-organization>

The global sensor index can be reconstructed as:

$ "sensor_id" = 8 dot "zone" + "local_channel" $

where $"zone" = 0 ... 9$ and $"local_channel" = 0 ... 7$. The frequency branch is stored separately as LF or HF.

== FIFO buffering and clock domains

The FPGA must separate the deterministic acquisition domain from the host communication domain. The ADCs are sampled periodically, but the PC interface can pause temporarily because of USB packets, Ethernet arbitration, operating-system latency or driver behavior. If these pauses are not absorbed, samples can be lost.

For this reason, the data path includes a FIFO:

#figure(
  align(center)[
    #box(inset: 8pt, stroke: 0.7pt, radius: 4pt)[
      #grid(
        columns: (1.2fr, 0.25fr, 1.2fr, 0.25fr, 1.2fr, 0.25fr, 1.2fr),
        column-gutter: 4pt,
        align: horizon,
        [#box(inset: 5pt, stroke: 0.7pt, radius: 4pt)[ADC receivers]],
        [$arrow.r$],
        [#box(inset: 5pt, stroke: 0.7pt, radius: 4pt)[Frame builder]],
        [$arrow.r$],
        [#box(inset: 5pt, stroke: 0.7pt, radius: 4pt)[Asynchronous FIFO]],
        [$arrow.r$],
        [#box(inset: 5pt, stroke: 0.7pt, radius: 4pt)[USB/Ethernet interface]],
      )
    ]
  ],
  caption: [Internal FPGA data path from ADC readout to the host interface.]
)<fig:fpga-data-path>

The FIFO has two roles:

- It provides temporary storage when the output interface is not ready.
- It crosses clock domains if the ADC acquisition clock and the communication interface clock are different.

The FIFO must report at least three status conditions: almost full, full and overflow. If the FIFO reaches almost full, the FPGA can either stop acquisition in a controlled way or mark the outgoing stream with an overflow warning. If overflow occurs, the frame counter allows the PC software to detect the lost data interval.

== Data throughput

The output data rate is determined by the number of channels, the number of bits used to store each sample and the sampling frequency.

Although the ADC resolution is 18 bits, the FPGA should not pack the samples as a continuous 18-bit bitstream. It is more practical to align each sample to 24 bits or 32 bits. The 24-bit option is selected as a compromise between efficient bandwidth and simple byte alignment.

The general expression is:

$ R = N_"channels" dot N_"bits/sample" dot f_s $

If all 160 channels were sampled at 250 kS/s and stored as 24-bit words:

$ R = 160 dot 24 dot 250 " kS/s" = 960 " Mbit/s" $

This value does not include frame headers, status fields or protocol overhead. Therefore, streaming all channels at 250 kS/s is close to the practical limit of Gigabit Ethernet.

A more efficient strategy is to use different sampling frequencies for the two branches:

- HF branch: 80 channels at 250 kS/s.
- LF branch: 80 channels at 50 kS/s.

The payload throughput is then:

$ R_"HF" = 80 dot 24 dot 250 " kS/s" = 480 " Mbit/s" $

$ R_"LF" = 80 dot 24 dot 50 " kS/s" = 96 " Mbit/s" $

$ R_"total" = 480 " Mbit/s" + 96 " Mbit/s" = 576 " Mbit/s" $

After headers, timestamps, CRC and communication overhead, the expected sustained rate is approximately 650 Mbit/s to 750 Mbit/s. This is compatible with a carefully implemented Gigabit Ethernet link, but it leaves limited margin. USB 3.0 FIFO provides more margin and is therefore selected as the preferred interface to the PC.

#figure(
  table(
    columns: (1.7fr, 1.7fr, 1.7fr, 2.7fr),
    inset: 6pt,
    align: left,
    table.header([Acquisition mode], [Payload rate], [Interface margin], [Comment]),

    [160 channels at 250 kS/s],
    [960 Mbit/s],
    [Low for Gigabit Ethernet],
    [Possible only with a faster interface or reduced overhead.],

    [HF 250 kS/s + LF 50 kS/s],
    [576 Mbit/s],
    [Moderate],
    [Recommended operating mode.],

    [HF/LF with decimation in FPGA],
    [Lower],
    [High],
    [Useful if real-time spectral features are extracted before transmission.],
  ),
  caption: [Estimated payload data rates for 24-bit-aligned samples.]
)<table:data-rates>

== Output interface to PC or DAQ

The selected primary output interface is USB 3.0 FIFO. This type of interface is convenient because it exposes a parallel FIFO-like bus to the FPGA and provides more bandwidth margin than Gigabit Ethernet for continuous streaming.

The role of the USB/Ethernet block is not to define the measurement timing. Timing is defined internally by the FPGA and CONVST. The communication interface only transports completed frames from the FIFO to the PC.

#figure(
  table(
    columns: (1.2fr, 2.4fr, 2.4fr),
    inset: 6pt,
    align: left,
    table.header([Interface], [Advantages], [Limitations]),

    [USB 3.0 FIFO],
    [High practical throughput; simple FIFO-style connection to FPGA; good for laboratory acquisition.],
    [Shorter cable distance; requires PC-side driver and acquisition software.],

    [Gigabit Ethernet],
    [Longer cables; robust connector; easier remote acquisition over standard networks.],
    [Limited margin if all channels are streamed at high sampling rate; requires MAC/UDP logic or an external controller.],
  ),
  caption: [Comparison of candidate output interfaces.]
)<table:output-interface>

The recommended final choice is:

- #strong[USB 3.0 FIFO] as the primary interface for full-rate acquisition.
- #strong[Gigabit Ethernet] as an alternative if LF and HF data rates are reduced or if the FPGA performs decimation before transmission.

== Error detection and diagnostic flags

The FPGA must include diagnostic logic because this is a large distributed acquisition system. With 20 ADCs, a single failing link should not invalidate the complete design silently. The following diagnostic flags are included in the frame header:

#figure(
  table(
    columns: (1.7fr, 3.7fr),
    inset: 6pt,
    align: left,
    table.header([Flag], [Meaning]),

    [ADC_BUSY_TIMEOUT],
    [At least one ADC did not finish conversion in the expected time.],

    [ADC_SYNC_ERROR],
    [BUSY or frame timing differs from the expected synchronized sequence.],

    [FIFO_ALMOST_FULL],
    [The communication interface is not emptying the FIFO fast enough.],

    [FIFO_OVERFLOW],
    [At least one frame was lost because the FIFO was full.],

    [FRAME_COUNTER_GAP],
    [Detected by the PC when frame counters are not consecutive.],

    [CRC_ERROR],
    [Data integrity check failed, either in ADC communication or in the output stream.],
  ),
  caption: [Diagnostic flags generated by the FPGA acquisition subsystem.]
)<table:diagnostic-flags>

These flags support system verification and simplify debugging during laboratory tests.

== Final proposed FPGA architecture

The complete FPGA subsystem is summarized in @fig:fpga-complete.

#figure(
  align(center)[
    #box(inset: 8pt, stroke: 0.7pt, radius: 4pt)[
      #grid(
        columns: (1fr, 0.2fr, 1.2fr, 0.2fr, 1fr),
        column-gutter: 5pt,
        row-gutter: 8pt,
        align: center,

        [#box(inset: 5pt, stroke: 0.7pt, radius: 4pt)[20 AD7606C-18 \ 2 DOUT/ADC]],
        [$arrow.r$],
        [#box(inset: 5pt, stroke: 0.7pt, radius: 4pt)[Artix-7 FPGA \ timing + capture + frame builder]],
        [$arrow.r$],
        [#box(inset: 5pt, stroke: 0.7pt, radius: 4pt)[USB 3.0 FIFO \ or Ethernet]],

        [],
        [],
        [
          #box(inset: 5pt, stroke: 0.7pt, radius: 4pt)[
            CONVST generator \ ADC controller \ timestamp counter \ serial receivers \ FIFO \ diagnostics
          ]
        ],
        [],
        [],
      )
    ]
  ],
  caption: [Final FPGA-based digital acquisition architecture.]
)<fig:fpga-complete>

The selected architecture satisfies the digital requirements of the project. It provides simultaneous sampling through a common CONVST signal, parallel readout of the 20 ADCs, deterministic timestamping, ordered frame construction and buffered high-throughput transmission to the host computer.

The main pending implementation check is the final package-level I/O validation. The 2-DOUT-per-ADC baseline requires approximately 122 to 147 FPGA I/O pins including host interface and debug margin. If the selected XC7A35T-1FTG256I package exposes enough user pins after power, configuration and clock pins are reserved, it is a valid choice. Otherwise, the design must either reduce debug/host-interface pins, group some BUSY/CS signals externally, or move to a larger Artix-7 package.
