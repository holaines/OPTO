#let navy = rgb("#17324D")
#let blue = rgb("#2F6F9F")
#let light-blue = rgb("#EAF3F8")
#let pale-blue = rgb("#F6FAFD")
#let green = rgb("#3A7D44")
#let light-green = rgb("#ECF7EF")
#let orange = rgb("#B86B00")
#let light-orange = rgb("#FFF4E3")
#let red = rgb("#9B2C2C")
#let light-red = rgb("#FDECEC")
#let grey = rgb("#5A5A5A")
#let light-grey = rgb("#F4F6F8")

= FPGA and digital acquisition

== Purpose of the digital acquisition stage

The FPGA is the central digital element of the proposed acquisition system. Its function is not only to receive digital data from the ADCs, but to guarantee that all 160 microphone channels are acquired with a common timing reference and that the data are delivered to the host computer in an ordered and lossless way.

The complete system contains 80 dual-frequency MEMS microphones. Each MEMS provides two analog outputs, one for the low-frequency branch and one for the high-frequency branch. Therefore, the digital acquisition system must handle:

$ 80 " MEMS" dot 2 " outputs/MEMS" = 160 " channels" $

The selected acquisition integrated circuit is the AD7606C-18. Since each AD7606C-18 contains 8 simultaneous-sampling ADC channels, the required number of ADC devices is:

$ 160 " channels" / 8 " channels/ADC" = 20 " ADCs" $

The adopted distribution is the same as in the global architecture:

#figure(
  align(center)[
    #box(inset: 8pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(90%))[
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
            [#box(inset: 6pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(75%))[8 LF outputs \ $arrow.b$ \ 1 AD7606C-18]],
            [#box(inset: 6pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(75%))[8 HF outputs \ $arrow.b$ \ 1 AD7606C-18]],
          )
        ],
        [$arrow.b$],
        [#strong[20 AD7606C-18 devices connected to one Artix-7 FPGA]],
      )
    ]
  ],
  caption: [Digital acquisition distribution for the 80 dual-frequency MEMS microphones.]
) <fig:fpga-distribution>

The FPGA must perform the following tasks:

- Generate the common sampling timing for all ADCs.
- Control the 20 AD7606C-18 devices through CONVST, RESET, CS, SCLK and configuration signals.
- Capture the conversion results from the ADC serial outputs.
- Associate every acquired frame with a timestamp.
- Reorder the samples by zone, frequency branch and channel number.
- Build data frames with header, payload and status information.
- Store the frames in a FIFO to avoid data loss during communication stalls.
- Stream the data to the acquisition PC through the 2.5G Ethernet interface.

== Justification of the Artix-7 FPGA

An FPGA is preferred over a microcontroller because this acquisition problem is strongly parallel and timing-critical. A microcontroller would normally control the ADCs sequentially through software instructions, interrupts or DMA transactions. This can introduce variable latency and makes the synchronization of 20 converters more difficult. In contrast, an FPGA implements the control logic as hardware. Therefore, it can generate deterministic timing signals and read several digital interfaces at the same time.

The choice of an FPGA is also directly linked to the functional requirements of this project. The digital subsystem is not required to perform only one task, such as reading ADC samples. It must simultaneously generate branch-specific sampling signals, receive 160 channels from 20 ADCs, verify conversion completion, reconstruct the sample ordering, attach timestamps, buffer the data stream and forward the frames to the communication interface. These operations must remain consistent over long acquisitions and must not depend on software execution order. An FPGA is well suited to this kind of pipeline because each function can be implemented as a dedicated hardware block operating concurrently with the others.

This hardware concurrency is especially useful in the present architecture. The LF and HF branches operate at different sampling rates, but both must remain internally synchronized and traceable to the same FPGA timebase. At the same time, the output interface must transmit a continuous stream of framed data without disturbing the acquisition schedule. The FPGA can separate these functions into timing generation, ADC readout, FIFO buffering and Ethernet packetization blocks. This modular structure makes it easier to guarantee that communication delays or packet scheduling do not affect the actual sampling instants.

Another practical reason for selecting an FPGA is that the design benefits from a large amount of configurable digital I/O placed close to the acquisition logic. The 20 AD7606C-18 devices require many control, status and data signals, and those signals must be handled with predictable timing. A processor-based solution would either require extensive external glue logic or would sacrifice determinism when the interface count becomes too large. The FPGA instead acts as a digital backplane: it concentrates the distributed ADC interfaces into one deterministic, timestamped and communication-ready data stream for the acquisition PC.

The selected FPGA family is Artix-7. It is appropriate for this system for four main reasons.

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + navy,
    fill: pale-blue,
    radius: 5pt,
  )[
    #table(
      columns: (2fr, 3fr, 3.2fr),
      inset: 6pt,
      fill: (col, row) => { if row == 0 { navy } },
      align: left,
      table.header(
        text(fill: white)[*Criterion*],
        text(fill: white)[*Relevant Artix-7 characteristic*], 
        text(fill: white)[*Impact on this project*]),

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
  )],
  caption: [Reasons for using an Artix-7 FPGA as the digital acquisition core.]
) <table:artix-justification>

The Artix-7 is therefore selected as the digital timing and concentration device. The exact package must expose enough user I/O pins for the selected ADC interface and for the PC communication interface. For this reason, the final PCB implementation must verify the user I/O count in the Xilinx package and pinout documentation for the selected part, for example XC7A35T-1FTG256I.

This distinction is important: the Artix-7 family is electrically and functionally suitable, but the final package must still be checked against the I/O budget calculated in @sec:fpga-io-budget.

== ADC digital interface strategy

The AD7606C-18 can be read through a parallel or serial digital interface. For this project, the serial interface is more convenient because 20 ADCs have to be connected to the same FPGA. A full parallel bus per ADC would require too many FPGA pins and would make the PCB routing more complex.

In serial mode, the ADC sends the conversion results through digital output pins called DOUT lines. A DOUT line is a serial data output line: it transmits the bits of the conversion result from the ADC to the FPGA, synchronized by the serial clock SCLK.

For one AD7606C-18 device, each acquisition frame contains:

$ 8 " channels" dot 18 " bits/channel" = 144 " bits" $

If only one DOUT line is used, the 144 bits must be shifted sequentially through that single line. If two DOUT lines are used, the data are divided between two outputs. If four DOUT lines are used, the transfer is divided between four outputs. Therefore, using more DOUT lines reduces the readout time but increases the number of FPGA pins.

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + green,
    fill: light-green,
    radius: 5pt,
  )[
    #table(
      columns: (0.8fr, 1.5fr, 1.5fr, 2.8fr),
      inset: 6pt,
      fill: (col, row) => { if row == 0 { green }},
      align: left,
      table.header(
        text(fill: white)[*DOUT per ADC*],
        text(fill: white)[*ADC DOUT pins for 20 ADCs*],
        text(fill: white)[*SCLK cycles per ADC frame*],
        text(fill: white)[*Comment*]),

      [1],
      [$20 dot 1 = 20$],
      [$144$],
      [Minimum number of pins, but longest readout time. Useful only if the sampling frequency is relaxed.],

      [2],
      [$20 dot 2 = 40$],
      [$72$],
      [Lower pin count, but lower timing margin.],

      [4],
      [$20 dot 4 = 80$],
      [$36$],
      [Selected configuration. It provides larger timing margin while keeping the I/O count acceptable.],

      [8],
      [$20 dot 8 = 160$],
      [$18$],
      [Fastest readout, but excessive I/O usage for this design. Not selected.],
  )],
  caption: [Comparison of possible AD7606C-18 serial readout widths.]
) <table:dout-options>

The selected configuration is #strong[4 DOUT lines per ADC]. This matches the data-handling architecture and provides enough timing margin for the 256 kS/s HF branch while avoiding the excessive pin usage of the 8-DOUT option.

== FPGA I/O budget
<sec:fpga-io-budget>

The I/O budget depends mainly on the number of DOUT lines selected per ADC and on the host communication interface. The following calculation assumes a shared sampling and clocking structure:

- Separate CONVST signals for the LF and HF ADC groups.
- One common RESET signal.
- One common SCLK signal.
- One common SDI/MOSI configuration line.
- Individual CS signals, one for each ADC.
- Individual BUSY signals, one for each ADC, to detect desynchronization or ADC faults.
- Four DOUT lines per ADC as the selected option.
- Additional FPGA pins for the 2.5G Ethernet PHY, external trigger, clocks and debug.

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + navy,
    fill: pale-blue,
    radius: 5pt,
  )[
    #table(
      columns: (1.8fr, 1.1fr, 3.6fr),
      inset: 6pt,
      fill: (col, row) => { if row == 0 { navy }},
      align: left,
      table.header(
        text(fill: white)[*Signal group*],
        text(fill: white)[*Pins*],
        text(fill: white)[*Purpose*]),

      [CONVST_LF \ CONVST_HF],
      [2],
      [Synchronized conversion-start signals for the LF and HF ADC groups.],

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
      [$20 dot 4 = 80$],
      [Four serial data outputs per ADC, read in parallel by the FPGA.],

      [Static or semi-static configuration pins],
      [5--8],
      [PAR/SER, oversampling pins, range-related pins and mode pins. Some can be fixed by hardware.],

      [2.5G Ethernet PHY interface],
      [15--25],
      [RGMII/SGMII-related signals, MDIO/MDC, reset, interrupts and clocking, depending on the selected PHY.],

      [Clocks, debug and spare pins],
      [10--15],
      [External oscillator, status LEDs, test points, trigger input/output and design margin.],
    )],
  caption: [Estimated FPGA I/O budget for the 4-DOUT-per-ADC and 2.5G Ethernet implementation.]
) <table:io-budget>

The ADC-side I/O count for the selected case is approximately:

$ N_"ADC I/O" = 2 + 1 + 1 + 1 + 20 + 20 + 80 + 8 = 133 " pins" $

Adding the 2.5G Ethernet PHY interface and debug margin:

$ N_"total I/O" approx 133 + (15 " to " 25) + (10 " to " 15) = 158 " to " 173 " pins" $

Therefore, the selected FPGA package must be checked against the final I/O budget after assigning power, configuration, clock and communication pins.

== Synchronization strategy

The most important digital requirement is synchronization. In an acoustic array, the relative delay between channels affects phase measurements and therefore affects beamforming, delay estimation and spatial reconstruction. The system must not only digitize the 160 channels; it must digitize them with a common time reference.

The synchronization is achieved by generating CONVST_HF and CONVST_LF from the same FPGA timebase. The rising edge of each CONVST signal defines the sampling instant for its corresponding ADC group.

#figure(
  align(center)[
    #box(inset: 8pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(90%))[
      #grid(
        columns: (1fr,),
        row-gutter: 6pt,
        align: center,
        [#strong[FPGA timing generator]],
        [$arrow.b$],
        [CONVST_HF at 256 kS/s and CONVST_LF at 51.2 kS/s],
        [$arrow.b$],
        [10 HF ADCs and 10 LF ADCs sample synchronously within each branch],
        [$arrow.b$],
        [BUSY high during conversion],
        [$arrow.b$],
        [BUSY low: conversion completed],
        [$arrow.b$],
        [Parallel 4-DOUT serial readout of the ADCs],
        [$arrow.b$],
        [Timestamp + frame building + FIFO],
      )
    ]
  ],
  caption: [Timing sequence controlled by the FPGA.]
) <fig:fpga-timing-sequence>

The physical sampling time is determined by the CONVST edge, not by the later digital readout order. The ADC data can be read after conversion without creating inter-channel sampling delay, as long as all devices in the same branch sampled from the same CONVST event and the frame builder keeps the samples grouped under the same timestamp or sample counter.

To improve robustness, the FPGA monitors the BUSY signals. If one ADC does not release BUSY within the expected time window, the frame is marked with an error flag. This avoids silently accepting corrupted or incomplete data.

== ADC controller state machine

The FPGA implements one common ADC acquisition controller and 20 parallel serial receivers. The high-level state machine is:

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + navy,
    fill: pale-blue,
    radius: 5pt,
  )[
    #table(
      columns: (1.5fr, 4.5fr),
      inset: 6pt,
      fill: (col, row) => { if row == 0 { navy } },
      align: left,
      table.header(
        text(fill: white)[*State*],
        text(fill: white)[*Function*]),

      [IDLE],
      [Wait until the next sampling tick generated from the FPGA sampling timer.],

      [START_CONVERSION],
      [Generate CONVST_HF or CONVST_LF and capture the timestamp counter.],

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
    )],
  caption: [FPGA acquisition controller state machine.]
) <table:adc-state-machine>

The individual serial receivers work in parallel. Each receiver captures the DOUT lines of one ADC and reconstructs the eight 18-bit samples. All receivers are triggered by the same global READ_ADC state, so the 20 ADCs are read in the same readout window.

== Readout timing calculation

The readout time must be shorter than the sampling period. For one AD7606C-18, the number of bits per frame is 144 bits. With 4 DOUT lines, the number of SCLK cycles is:

$ N_"cycles, 4-DOUT" = 144 / 4 = 36 " cycles" $

Assuming a conservative serial clock of 60 MHz, the readout time is:

$ t_"read, 4-DOUT" = 36 / (60 " MHz") = 0.6 mu s $

The high-frequency branch must cover signals up to 100 kHz. A sampling frequency of 256 kS/s is selected for the HF branch because it is above the Nyquist minimum and is an integer multiple of the LF sampling rate:

$ f_"s,HF" = 256 " kS/s" quad => quad T_"s,HF" = 3.906 mu s $

Therefore:

$ t_"read, 4-DOUT" = 0.6 mu s < T_"s,HF" = 3.906 mu s $

The low-frequency branch only needs to cover up to approximately 10 kHz. A sampling frequency of 51.2 kS/s is selected:

$ f_"s,LF" = 51.2 " kS/s" quad => quad T_"s,LF" = 19.531 mu s $

This gives even more timing margin. The selected rates satisfy:

$ f_"s,HF" = 5 dot f_"s,LF" $

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + green,
    fill: light-green,
    radius: 5pt,
  )[
    #table(
    columns: (1.4fr, 1.2fr, 1.4fr, 1.5fr, 1.5fr),
    inset: 6pt,
    fill: (col, row) => { if row == 0 { green }},
    align: left,
    table.header(
      text(fill: white)[*Branch*],
      text(fill: white)[*Selected $f_s$*],
      text(fill: white)[*Sampling period*],
      text(fill: white)[*4-DOUT readout*],
      text(fill: white)[*Timing margin*]),

    [HF],
    [256 kS/s],
    [3.906 µs],
    [0.6 µs],
    [Valid],

    [LF],
    [51.2 kS/s],
    [19.531 µs],
    [0.6 µs],
    [Large margin],
  )],
  caption: [Readout timing verification for the selected 4-DOUT configuration.]
) <table:readout-timing>

This timing calculation justifies the 4-DOUT configuration selected in the data-handling architecture.

== Timestamp and frame format

The FPGA includes a free-running timestamp counter. A 64-bit counter is proposed because it provides a very long time range even with a high-frequency FPGA system clock.

At every CONVST event, the current counter value is latched and stored as the timestamp of the corresponding acquisition frame:

$ "timestamp"[k] = "counter value at CONVST edge"[k] $

This is preferable to timestamping the data at the end of the readout, because the relevant physical time is the instant at which the analog inputs were sampled.

Because the HF and LF branches operate at different sampling rates, the frame timestamp must identify one acquisition event of one branch. In other words, the FPGA should not label every packet as if it contained one simultaneous 160-channel sample. A practical implementation is to generate branch-tagged frames: HF frames at 256 kS/s and LF frames at 51.2 kS/s, both referenced to the same FPGA counter. If a higher-level superframe is desired, it can be reconstructed later by grouping five consecutive HF frames with one LF frame.

The proposed frame structure is:

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + navy,
    fill: pale-blue,
    radius: 5pt,
  )[
    #table(
      columns: (1.4fr, 4.2fr),
      inset: 6pt,
      fill: (col, row) => { if row == 0 { navy } },
      align: left,
      table.header(
        text(fill: white)[*Field*],
        text(fill: white)[*Content*]),

      [Sync word],
      [Fixed pattern used by the PC software to find the beginning of each frame.],

      [Frame counter],
      [Incremented at every acquisition. It allows detection of lost frames.],

      [Timestamp],
      [64-bit value captured at the CONVST edge.],

      [Mode field],
      [Sampling mode, LF/HF rate configuration, branch identifier, DOUT mode and ADC configuration version.],

      [Status flags],
      [BUSY timeout, FIFO overflow, ADC CRC error, synchronization error, reset event.],

      [Payload length],
      [Number of payload bytes.],

      [Payload],
      [Samples ordered by zone and channel for the branch identified in the header.],

      [CRC / checksum],
      [Optional integrity check for the complete frame.],
  )],
  caption: [Proposed digital frame format.]
) <table:frame-format>

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
) <fig:payload-organization>

The global sensor index can be reconstructed as:

$ "sensor_id" = 8 dot "zone" + "local_channel" $

where $"zone" = 0 ... 9$ and $"local_channel" = 0 ... 7$. The frequency branch is stored separately in the frame header as LF or HF.

== FIFO buffering and clock domains

The FPGA must separate the deterministic acquisition domain from the host communication domain. The ADCs are sampled periodically, but Ethernet transmission can pause temporarily because of packet scheduling, arbitration, MAC buffering, operating-system latency or driver behavior. If these pauses are not absorbed, samples can be lost.

For this reason, the data path includes a FIFO:

#figure(
  align(center)[
    #box(inset: 8pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(90%))[
      #grid(
        columns: (1.2fr, 0.25fr, 1.2fr, 0.25fr, 1.2fr, 0.25fr, 1.2fr),
        column-gutter: 4pt,
        align: horizon,
        [#box(inset: 5pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(75%))[ADC receivers]],
        [$arrow.r$],
        [#box(inset: 5pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(75%))[Frame builder]],
        [$arrow.r$],
        [#box(inset: 5pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(75%))[Asynchronous FIFO]],
        [$arrow.r$],
        [#box(inset: 5pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(75%))[2.5G Ethernet packetizer]],
      )
    ]
  ],
  caption: [Internal FPGA data path from ADC readout to the host interface.]
) <fig:fpga-data-path>

The FIFO has two roles:

- It provides temporary storage when the output interface is not ready.
- It crosses clock domains if the ADC acquisition clock and the communication interface clock are different.

The FIFO must report at least three status conditions: almost full, full and overflow. If the FIFO reaches almost full, the FPGA can either stop acquisition in a controlled way or mark the outgoing stream with an overflow warning. If overflow occurs, the frame counter allows the PC software to detect the lost data interval.

== Data throughput

The output data rate is determined by the number of channels, the number of bits used to store each sample and the sampling frequency.

For the 18-bit AD7606C-18 samples, the general expression is:

$ R = N_"channels" dot 18 " bits/sample" dot f_s $

The selected sampling strategy uses different sampling frequencies for the two branches:

- HF branch: 80 channels at 256 kS/s.
- LF branch: 80 channels at 51.2 kS/s.

The payload throughput is then:

$ R_"HF" = 80 dot 18 dot 256 " kS/s" = 368.6 " Mbit/s" $

$ R_"LF" = 80 dot 18 dot 51.2 " kS/s" = 73.7 " Mbit/s" $

$ R_"total" = 368.6 " Mbit/s" + 73.7 " Mbit/s" = 442.3 " Mbit/s" $

After headers, timestamps, CRC and communication overhead, a 25 % margin gives:

$ R_"design" approx 1.25 dot 442.3 " Mbit/s" approx 553 " Mbit/s" $

This is below the nominal bandwidth of Gigabit Ethernet, but 2.5G Ethernet is selected to provide additional implementation margin, support robust industrial cabling and leave room for metadata, control traffic and future extensions.

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + navy,
    fill: pale-blue,
    radius: 5pt,
  )[
    #table(
      columns: (1.7fr, 1.7fr, 1.7fr, 2.7fr),
      fill: (col, row) => { if row == 0 { navy }},
      inset: 6pt,
      align: left,
      table.header(
        text(fill: white)[*Acquisition mode*],
        text(fill: white)[*Payload rate*],
        text(fill: white)[*Interface margin*],
        text(fill: white)[*Comment*]),

      [HF 256 kS/s + LF 51.2 kS/s, 18-bit samples],
      [442.3 Mbit/s],
      [High with 2.5G Ethernet],
      [Selected operating mode.],

      [Same mode with 25 % overhead margin],
      [≈553 Mbit/s],
      [Comfortable with 2.5G Ethernet],
      [Leaves margin for framing, status and control traffic.],

      [HF/LF with decimation in FPGA],
      [Lower],
      [High],
      [Useful if real-time spectral features are extracted before transmission.],
  )],
  caption: [Estimated payload data rates for 18-bit samples.]
) <table:data-rates>

== Output interface to PC or DAQ

The selected primary output interface is #strong[2.5G Ethernet]. It provides more bandwidth margin than standard Gigabit Ethernet and is more suitable than USB for a distributed wind-tunnel or flight-test instrumentation system because it supports longer cables, standard networking hardware and robust industrial connectors.

The role of the Ethernet block is not to define the measurement timing. Timing is defined internally by the FPGA and the CONVST signals. The communication interface only transports completed frames from the FIFO to the acquisition PC.

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + navy,
    fill: light-green,
    radius: 5pt,
  )[
    #table(
      columns: (1.2fr, 2.4fr, 2.4fr),
      inset: 6pt,
      fill: (col, row) => { if row == 0 { green }},
      align: left,
      table.header(
        text(fill: white)[*Interface*],
        text(fill: white)[*Advantages*],
        text(fill: white)[*Limitations*]),

      [1G Ethernet],
      [Long cable length, standard networking and robust connector options.],
      [Lower implementation margin for continuous acquisition and future extensions.],

      [2.5G Ethernet],
      [Selected option. Provides sufficient bandwidth margin while keeping FPGA and PHY complexity moderate.],
      [Requires a 2.5G-capable PHY, PCB routing discipline and compatible PC/network interface.],

      [USB 3.0 FIFO],
      [High practical throughput and simple laboratory connection.],
      [Less suitable for remote acquisition and less mechanically robust for the target environment.],
  )],
  caption: [Comparison of candidate output interfaces.]
) <table:output-interface>

The selected physical interface is:

```text
FPGA Ethernet MAC → 2.5G Ethernet PHY → shielded M12 X-coded connector → acquisition PC
```

Raw acquisition data are streamed using UDP packets. Configuration and status commands can use TCP or a lightweight UDP control channel.

== Error detection and diagnostic flags

The FPGA must include diagnostic logic because this is a large distributed acquisition system. With 20 ADCs, a single failing link should not invalidate the complete design silently. The following diagnostic flags are included in the frame header:

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + navy,
    fill: pale-blue,
    radius: 5pt,
  )[
    #table(
      columns: (1.7fr, 3.7fr),
      inset: 6pt,
      fill: (col, row) => { if row == 0 { navy } },
      align: left,
      table.header(
        text(fill: white)[*Flag*],
        text(fill: white)[*Meaning*]),

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
  )],
  caption: [Diagnostic flags generated by the FPGA acquisition subsystem.]
) <table:diagnostic-flags>

These flags support system verification and simplify debugging during laboratory tests.

== Final proposed FPGA architecture

The complete FPGA subsystem is summarized in @fig:fpga-complete.

#figure(
  align(center)[
    #box(inset: 8pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(90%))[
      #grid(
        columns: (1fr, 0.2fr, 1.2fr, 0.2fr, 1fr),
        column-gutter: 5pt,
        row-gutter: 8pt,
        align: center,

        [#box(inset: 5pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(75%))[20 AD7606C-18 \ 4 DOUT/ADC]],
        [$arrow.r$],
        [#box(inset: 5pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(75%))[Artix-7 FPGA \ timing + capture + frame builder]],
        [$arrow.r$],
        [#box(inset: 5pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(75%))[2.5G Ethernet PHY \ M12 X-coded connector]],

        [],
        [],
        [
          #box(inset: 5pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(75%))[
            CONVST_LF/HF generator \ ADC controller \ timestamp counter \ 4-DOUT serial receivers \ FIFO \ UDP packetizer \ diagnostics
          ]
        ],
        [],
        [],
      )
    ]
  ],
  caption: [Final FPGA-based digital acquisition architecture.]
) <fig:fpga-complete>

The selected architecture satisfies the digital requirements of the project. It provides synchronized LF and HF sampling through FPGA-generated CONVST signals, parallel 4-DOUT readout of the 20 ADCs, deterministic timestamping, ordered frame construction and buffered high-throughput transmission to the host computer through 2.5G Ethernet.

The main pending implementation check is the final package-level I/O validation. The selected 4-DOUT-per-ADC architecture requires approximately 158 to 173 FPGA I/O pins including the Ethernet PHY interface and debug margin. If the selected XC7A35T-1FTG256I package does not expose enough usable pins after power, configuration and clock pins are reserved, the design must reduce non-essential pins or move to a larger Artix-7 package.
