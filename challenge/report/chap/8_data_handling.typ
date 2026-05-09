#let block-w = 4.0cm

#let table-fill = (col, row) => {
  if row == 0 {
    gray.lighten(50%)
  } else if col == 0 {
    gray.lighten(80%)
  }
}

#let stage(title, body) = box(
  width: block-w,
  inset: 6pt,
  stroke: 0.65pt,
  radius: 4pt,
  fill: blue.lighten(75%)
)[
  #align(center + horizon)[
    #strong[#title] \
    #v(3pt)
    #text(size: 8pt)[#body]
  ]
]

#let rarr(label: none) = box(
  width: 1.6cm,
  height: 0.8cm,
)[
  #align(center + horizon)[
    #if label != none [
      #stack(
        dir: ttb,
        spacing: 1pt,
        text(size: 7.5pt)[#label],
        text(size: 14pt)[→],
      )
    ] else [
      #text(size: 14pt)[→]
    ]
  ]
]

#let darr = box(
  height: 0.65cm,
  width: block-w,
)[
  #align(center + horizon)[
    #text(size: 14pt)[↓]
  ]
]

= Data handling and acquisition strategy

== Design objective

The data handling stage connects the digitized outputs of the 20 AD7606C-18 devices to the acquisition computer through the FPGA. Its main objective is to preserve the temporal coherence of the 160 microphone channels while providing a continuous, ordered and verifiable data stream.

The FPGA is responsible for synchronizing the ADC conversions, reading the converted samples, assigning each value to its corresponding zone, sensor and frequency branch, and buffering the data before transmission to the PC. The PC-side software then receives the stream, checks its integrity, stores the raw data and provides basic visualization and control.

This section defines the acquisition architecture, timing strategy, data framing, bandwidth requirements and software interface needed to operate the complete MEMS microphone array.

== Acquisition architecture

The acquisition system is organized around a central FPGA that controls and reads all ADC devices in parallel. The analog front-end is divided into 10 identical acquisition zones. Each zone contains 8 dual-output MEMS microphones and two AD7606C-18 devices: one dedicated to the LF outputs and one dedicated to the HF outputs.

```text
10 acquisition zones
  ├── 10 x AD7606C-18 for LF channels
  └── 10 x AD7606C-18 for HF channels
```

The complete system therefore contains 20 ADC devices. Since each AD7606C-18 digitizes 8 simultaneous input channels, the full array provides 160 digitized channels per acquisition instant.

All AD7606C-18 devices are connected to the FPGA. The FPGA provides the common conversion control signals, reads the digital outputs, stores the samples in internal buffers and forwards the resulting stream to the acquisition PC.

#figure(
  align(center)[
    #grid(
      columns: (block-w, 0.9cm, block-w, 1.6cm, block-w),
      rows: (
        auto,
        0.65cm,
        auto,
      ),
      column-gutter: 0pt,
      row-gutter: 0pt,
      align: center + horizon,

      // Row 1
      stage([MEMS array], [80 dual-output\ microphones]),
      rarr(),
      stage([ADC stage], [20 x AD7606C-18\ 160 channels]),
      [],
      [],

      // Row 2
      [],
      [],
      darr,
      [],
      [],

      // Row 3
      [],
      [],
      stage([FPGA controller], [synchronization\ readout\ buffering\ framing]),
      rarr(label: [Ethernet]),
      stage([PC software], [acquisition\ storage\ visualization]),
    )
  ],
  caption: [Global acquisition path from the MEMS array to the acquisition computer.]
)

The selected output interface is industrial 2.5G Ethernet using a shielded M12 X-coded connector. This choice provides more bandwidth margin than standard Gigabit Ethernet, better mechanical robustness than USB, and easier FPGA implementation than a full industrial fieldbus such as EtherCAT G. Raw acquisition data are streamed using UDP packets, while configuration and status commands are handled through a lightweight TCP/UDP control channel.

== ADC-to-FPGA interface

=== Number of ADC devices and channels

The acquisition front-end uses 20 AD7606C-18 devices. Each device digitizes 8 simultaneous analog inputs with 18-bit resolution, so the complete array produces 160 digitized channels per acquisition instant.

Each acquisition zone contains two ADC devices: one for the 8 LF outputs and one for the 8 HF outputs. This keeps the LF and HF branches separated while preserving simultaneous sampling inside each group of 8 sensors.

=== Digital interface configuration

The AD7606C-18 supports flexible serial and parallel digital interfaces. In this design, the serial interface is preferred to reduce the number of FPGA pins while keeping enough readout bandwidth. The selected configuration uses four serial data outputs per ADC.

```text
1 x AD7606C-18 → 4 x DOUT
20 x AD7606C-18 → 80 FPGA data inputs
```

This is a compromise between the minimum-pin configuration, using one DOUT per ADC, and the maximum-throughput configuration, using eight DOUT lines per ADC. Four DOUT lines per device reduce the FPGA I/O count while allowing the converted data to be read with enough margin after each conversion.

The main shared and per-device signals are listed in @tab-adc-fpga-signals.

#figure(
  table(
    columns: (1.4fr, 1fr, 3fr),
    inset: 6pt,
    align: left,
    fill: table-fill,

    table.header([*Signal*], [*Direction*], [*Function*]),

    [CONVST],
    [FPGA → ADC],
    [Common conversion start signal. It synchronizes the sampling instant of all ADC devices.],

    [SCLK],
    [FPGA → ADC],
    [Serial clock used to read the conversion data.],

    [CS],
    [FPGA → ADC],
    [Chip-select signal. One independent CS line is assigned to each ADC device.],

    [DOUT[3:0]],
    [ADC → FPGA],
    [Four serial data outputs per ADC device.],

    [BUSY],
    [ADC → FPGA],
    [Indicates that the conversion is still in progress. It is used to start readout only after valid data are available.],

    [RESET],
    [FPGA → ADC],
    [Common reset signal for ADC initialization.]
  ),
  caption: [Main digital signals between the AD7606C-18 devices and the FPGA.],
) <tab-adc-fpga-signals>

=== FPGA I/O requirements

With four data outputs per AD7606C-18, the estimated FPGA I/O requirement is summarized in @tab-fpga-io-requirements.

#figure(
  table(
    columns: (2fr, 1.2fr, 1.2fr),
    inset: 6pt,
    fill: table-fill,
    align: center,
    table.header([*Signal group*], [*Count*], [*Direction*]),

    [ADC data lines],
    [20 x 4 = 80],
    [input],

    [BUSY lines],
    [20],
    [input],

    [CS lines],
    [20],
    [output],

    [Common CONVST],
    [1],
    [output],

    [Common SCLK],
    [1],
    [output],

    [Common RESET],
    [1],
    [output],

    [#strong[Total]],
    [#strong[123]],
    [#strong[input/output]],
  ),
  caption: [Estimated FPGA I/O requirement for the selected four-DOUT ADC interface.],
) <tab-fpga-io-requirements>

The selected Artix-7 device provides enough user I/O for this configuration, while still leaving margin for the Ethernet interface, trigger signals, status lines and debugging pins. The 8-DOUT configuration is avoided because it would require approximately 160 ADC data inputs alone, significantly reducing the available I/O margin.

== Sampling and synchronization

The acquisition timing is generated inside the FPGA from a single master clock. All ADC control signals are derived from this timebase, so the sampling instants, frame counters and output timestamps remain coherent across the complete array.

Since the LF and HF branches have different bandwidth requirements, the system uses two synchronized conversion groups:

```text
CONVST_HF → 10 AD7606C-18 devices connected to the HF channels
CONVST_LF → 10 AD7606C-18 devices connected to the LF channels
```

Both signals are generated by the FPGA. The LF trigger is aligned with the HF timebase, so every LF sample has a timestamp that coincides with a known HF sample instant.

=== Common conversion trigger

The FPGA generates the conversion start signals for the ADCs. Within each branch, all ADCs receive the same conversion pulse. Therefore, the 80 HF channels are sampled simultaneously, and the 80 LF channels are also sampled simultaneously.

The proposed sampling plan is shown in @tab-sampling-plan.

#figure(
  table(
    columns: (1.2fr, 1.3fr, 1.5fr, 1.5fr),
    inset: 6pt,
    fill: table-fill,
    align: center,
    table.header([*Branch*], [*ADC devices*], [*Selected sampling rate*], [*Conversion trigger*]),

    [LF],
    [10],
    [51.2 kS/s],
    [CONVST_LF],

    [HF],
    [10],
    [256 kS/s],
    [CONVST_HF],
  ),
  caption: [Preliminary sampling rates and conversion trigger groups.]
) <tab-sampling-plan>

The selected rates provide margin above the required signal bandwidths while keeping the data rate manageable. The HF sampling rate is five times the LF sampling rate, which simplifies timestamp alignment and frame generation:

$
f_"HF" = 5 dot f_"LF"
$

=== Clocking strategy

The FPGA uses a local low-jitter oscillator as the acquisition timebase. From this clock, it derives the LF and HF conversion triggers, the ADC serial readout clock, the timestamp counter and the Ethernet packet timing logic.

The ADC readout clock does not define the sampling instant. It only transfers data after the conversion is complete. The sampling instant is defined by the conversion trigger generated by the FPGA.

=== External trigger support

An external trigger input can be used to start the acquisition synchronously with the test setup. The trigger does not directly clock the ADCs. Instead, it arms or starts the internal FPGA timing engine.

```text
external trigger → FPGA trigger synchronizer → acquisition start
```

This avoids asynchronous timing at the ADC interface and keeps all conversion pulses generated from the same internal timebase.

=== Timing coherence across the array

Temporal coherence is preserved by three design decisions:

- All ADCs in the same branch share the same conversion trigger.
- LF and HF triggers are generated from the same FPGA clock.
- Every transmitted data block is tagged with a common timestamp or sample counter.

For each acquisition instant, the FPGA stores the samples with their corresponding branch, zone and sensor index. This allows the PC software to reconstruct the complete array data without relying on Ethernet packet arrival time.

== FPGA data pipeline

The FPGA implements the real-time acquisition pipeline between the ADC devices and the Ethernet output interface. Its role is to keep the sampling process deterministic and independent from the latency of the PC or the communication link.

The internal pipeline is:

```text
ADC control → ADC readout → channel mapping → timestamping → FIFO buffering → Ethernet packetizer
```

=== ADC readout controller

The ADC readout controller generates the digital control signals required by the 20 AD7606C-18 devices. After each conversion trigger, the FPGA waits for the corresponding BUSY signals to deassert and then reads the converted data using the selected four-DOUT serial configuration.

The readout process is performed in parallel for all ADC devices in the active branch. This avoids sequential polling from the PC and ensures that all samples belonging to the same acquisition instant are grouped together inside the FPGA.

#figure(
  table(
    columns: (1.6fr, 3fr),
    inset: 6pt,
    fill: table-fill,
    align: left,

    table.header([*FPGA block*], [*Function*]),

    [Conversion control],
    [Generates CONVST_LF and CONVST_HF from the FPGA acquisition clock.],

    [ADC status check],
    [Monitors BUSY signals and starts readout only when conversion data are valid.],

    [Serial readout],
    [Reads the 20 ADC devices using four serial data outputs per device.],

    [Sample grouping],
    [Groups the samples belonging to the same acquisition instant before forwarding them to the frame builder.],
  ),
  caption: [Main functions of the FPGA ADC readout controller.]
) <tab-adc-readout-controller>

=== Channel mapping

The FPGA assigns a fixed logical address to every acquired sample. This avoids ambiguity in the PC software and allows the raw stream to be stored without additional reordering.

Each sample is identified by:

```text
branch ∈ {LF, HF}
zone_id ∈ [0, 9]
sensor_id ∈ [0, 7]
sample_counter
adc_value
```

The channel mapping follows the physical structure of the array:

```text
LF branch:
  ADC_LF_0 → zone 0 → sensors 0..7
  ADC_LF_1 → zone 1 → sensors 0..7
  ...
  ADC_LF_9 → zone 9 → sensors 0..7

HF branch:
  ADC_HF_0 → zone 0 → sensors 0..7
  ADC_HF_1 → zone 1 → sensors 0..7
  ...
  ADC_HF_9 → zone 9 → sensors 0..7
```

This mapping is static and stored both in the FPGA firmware and in the metadata file used by the PC acquisition software.

=== Timestamping and sample counters

The FPGA maintains a global acquisition counter derived from the master sampling clock. This counter is attached to every data block and allows the PC to reconstruct the time axis without using the packet arrival time.

For the proposed sampling rates, the HF counter advances at every CONVST_HF event. The LF samples are aligned to the same timebase, since CONVST_LF is generated as an integer subdivision of the HF trigger.

```text
HF sample counter: increments every HF conversion
LF sample counter: aligned with every fifth HF conversion
```

This approach keeps both branches synchronized while allowing different sampling rates for LF and HF.

=== FIFO buffering

The FPGA includes FIFO buffers between the deterministic acquisition logic and the Ethernet output logic. This is required because ADC readout is periodic and timing-critical, while Ethernet transmission may introduce variable latency.

```text
ADC readout domain → acquisition FIFO → Ethernet packetizer domain
```

The FIFO absorbs short-term variations in packet transmission time and prevents data loss as long as the average Ethernet throughput is higher than the generated data rate.

=== Status and error flags

Each transmitted frame includes basic status information generated by the FPGA. These flags allow the PC software to detect acquisition problems during the test instead of discovering them only during post-processing.

#figure(
  table(
    columns: (1.5fr, 3fr),
    inset: 6pt,
    fill: table-fill,
    align: left,

    table.header([*Status field*], [*Meaning*]),

    [busy_timeout],
    [One or more ADC devices did not finish conversion within the expected time.],

    [fifo_overflow],
    [The acquisition FIFO overflowed and at least one frame was lost.],

    [frame_counter],
    [Monotonic counter used by the PC to detect missing frames.],

    [power_good],
    [Indicates whether the monitored supply rails are within their valid range.],

    [trigger_state],
    [Reports whether the system is idle, armed or acquiring.],
  ),
  caption: [Status and error fields included in the FPGA data stream.]
) <tab-fpga-status-fields>

The FPGA does not perform acoustic processing. Its task is limited to deterministic control, data ordering, buffering and transmission. Signal processing, calibration, visualization and storage are handled by the acquisition PC.

== Frame format

The FPGA output stream is organized into transport frames. Each frame groups a block of consecutive samples and includes the metadata required to verify ordering, timing and data integrity on the PC side. The design avoids one Ethernet packet per acquisition instant, because that would create an unnecessarily high packet rate.

=== Frame structure

Each transmitted frame contains a fixed-size header, the acquired ADC samples, status information and an integrity field. A fixed header simplifies parsing in the PC software and makes lost or corrupted frames easier to detect.

The proposed structure is shown in @tab-frame-structure.

#figure(
  table(
    columns: (1.4fr, 1.2fr, 3fr),
    inset: 6pt,
    fill: table-fill,
    align: left,

    table.header([*Field*], [*Size*], [*Description*]),

    [sync_word],
    [32 bit],
    [Fixed marker used to identify the beginning of a frame.],

    [frame_counter],
    [32 bit],
    [Monotonic counter incremented for every transmitted frame.],

    [timestamp_start],
    [64 bit],
    [FPGA timebase counter associated with the first sample in the frame.],

    [frame_type],
    [8 bit],
    [Identifies whether the payload contains LF data, HF data or status-only information.],

    [samples_per_frame],
    [16 bit],
    [Number of acquisition instants grouped in the payload.],

    [payload_length],
    [16 bit],
    [Number of payload bytes following the header.],

    [status_flags],
    [32 bit],
    [FIFO, ADC, trigger and power-status flags.],

    [payload],
    [variable],
    [Packed ADC samples ordered according to the channel map.],

    [crc32],
    [32 bit],
    [Frame integrity check computed over header and payload.],
  ),
  caption: [Proposed acquisition frame structure.]
) <tab-frame-structure>

=== Channel ordering

Samples are ordered by branch, zone and sensor index. This ordering follows the physical structure of the acquisition system and avoids run-time channel discovery on the PC.

```text
LF frame:
  zone 0: sensor 0..7
  zone 1: sensor 0..7
  ...
  zone 9: sensor 0..7

HF frame:
  zone 0: sensor 0..7
  zone 1: sensor 0..7
  ...
  zone 9: sensor 0..7
```

With this convention, the logical channel index can be reconstructed as:

```text
channel_index = branch_offset + 8 x zone_id + sensor_id
```

where `branch_offset` is 0 for LF and 80 for HF.

=== Metadata fields

Dynamic information required for stream validation is included in each frame. Static information such as sensor positions, calibration constants, ADC configuration and channel names is stored once in the acquisition metadata file.

#figure(
  table(
    columns: (1.6fr, 3fr),
    inset: 6pt,
    fill: table-fill,
    align: left,

    table.header([*Metadata*], [*Purpose*]),

    [frame_counter],
    [Detects missing or duplicated frames.],

    [timestamp_start],
    [Reconstructs the time axis independently from Ethernet packet arrival time.],

    [frame_type],
    [Distinguishes LF, HF and status frames.],

    [samples_per_frame],
    [Defines how many acquisition instants are included in the payload.],

    [status_flags],
    [Reports acquisition errors and power/trigger state.],

    [payload_length],
    [Allows the receiver to validate the expected frame size.],
  ),
  caption: [Minimum metadata fields included in each frame.]
) <tab-frame-metadata>

=== CRC and integrity checks

Each frame ends with a crc32 field. The PC software verifies this field before storing the payload. Frames with an invalid CRC are discarded and counted as corrupted.

The receiver also checks:

```text
sync word
payload length
monotonic frame counter
expected frame type sequence
FIFO and ADC error flags
```

These checks are required because the selected Ethernet streaming mode prioritizes continuous throughput. The frame counter and timestamp allow the software to detect data loss and preserve the correct time axis even if one or more packets are lost.

== Data rate estimation

The data-rate estimation determines the required output interface and the size of the internal buffers. Two values are considered: the theoretical raw data rate using 18-bit samples, and the practical packed rate using 32-bit words for simpler alignment.

=== Raw data rate

The raw data rate is calculated as:

$
R = N_"ch" dot N_"bits" dot f_s
$

For separate LF and HF sampling groups, the result is shown in @tab-raw-data-rate.

#figure(
  table(
    columns: (1.1fr, 1.3fr, 1.2fr, 1.6fr),
    inset: 6pt,
    fill: table-fill,
    align: center,

    table.header([*Branch*], [*Channels*], [*Sample size*], [*Raw rate*]),

    [LF],
    [80],
    [18 bit],
    [73.7 Mbit/s],

    [HF],
    [80],
    [18 bit],
    [368.6 Mbit/s],

    [#strong[Total]],
    [#strong[160]],
    [#strong[18 bit]],
    [#strong[442.4 Mbit/s]],
  ),
  caption: [Raw data-rate estimate for the selected sampling rates.]
) <tab-raw-data-rate>

=== Packed data rate

In the FPGA and PC software, samples are packed into 32-bit words. This avoids bit-level unpacking in the receiver and simplifies memory alignment, at the cost of a higher transport rate.

#figure(
  table(
    columns: (1.1fr, 1.3fr, 1.2fr, 1.8fr),
    inset: 6pt,
    fill: table-fill,
    align: center,

    table.header([*Branch*], [*Channels*], [*Packed size*], [*Packed rate*]),

    [LF],
    [80],
    [32 bit],
    [131.1 Mbit/s],

    [HF],
    [80],
    [32 bit],
    [655.4 Mbit/s],

    [#strong[Total]],
    [#strong[160]],
    [#strong[32 bit]],
    [#strong[786.4 Mbit/s]],
  ),
  caption: [Packed data-rate estimate using 32-bit sample words.]
) <tab-packed-data-rate>

The packed data rate does not include Ethernet, UDP/IP, frame headers, CRC fields or status packets. A design margin of approximately 25 % is considered for protocol overhead and implementation margin:

$
R_"design" approx 1.25 dot 786.4 " Mbit/s" approx 983 " Mbit/s"
$

=== Interface bandwidth margin

Standard Gigabit Ethernet is therefore too close to the expected upper limit. The selected 2.5G Ethernet link provides enough margin while avoiding the complexity and power consumption of a 10G interface.

#figure(
  table(
    columns: (1.5fr, 1.6fr, 2.4fr),
    inset: 6pt,
    fill: table-fill,
    align: left,

    table.header([*Interface*], [*Nominal bandwidth*], [*Assessment*]),

    [1G Ethernet],
    [1 Gbit/s],
    [Technically possible only with tight packing and little margin. Not selected.],

    [2.5G Ethernet],
    [2.5 Gbit/s],
    [Selected option. Provides sufficient margin for packed data and protocol overhead.],

    [10G Ethernet],
    [10 Gbit/s],
    [High margin, but higher cost, power and FPGA complexity. Not required for this design.],
  ),
  caption: [Output-interface bandwidth comparison.]
) <tab-interface-bandwidth>

== Output interface to the acquisition PC

The acquisition PC receives the data stream through a dedicated Ethernet connection. The FPGA sends acquisition frames continuously during a test and accepts configuration commands before and during acquisition.

=== USB 3.0 FIFO bridge option

A USB 3.0 FIFO bridge would provide high throughput with a simple PC connection. However, it is less convenient for remote acquisition in a wind-tunnel or flight-test setup, and the connector/cable ecosystem is less robust than industrial Ethernet.

For this reason, USB 3.0 is considered a valid development option but not the selected final interface.

=== Ethernet option

Ethernet is more appropriate for a distributed instrumentation system. It supports longer cables, remote PC placement, standard networking hardware and mechanically robust industrial connectors.

The selected physical interface is:

```text
FPGA Ethernet MAC → 2.5G Ethernet PHY → shielded M12 X-coded connector → acquisition PC
```

The raw data stream uses UDP because it has low overhead and allows continuous streaming. Reliability is handled at the application level using frame counters, timestamps and CRC checks. Configuration and status can use TCP or a lightweight UDP command protocol.

=== Selected interface

The selected output interface is 2.5G Ethernet. The data link is divided into two logical channels:

#figure(
  table(
    columns: (1.5fr, 1.7fr, 2.4fr),
    inset: 6pt,
    fill: table-fill,
    align: left,

    table.header([*Channel*], [*Protocol*], [*Purpose*]),

    [Data stream],
    [UDP],
    [Continuous transmission of acquisition frames from FPGA to PC.],

    [Control/status],
    [TCP or UDP commands],
    [Configuration, start/stop control, gain/range settings and status monitoring.],
  ),
  caption: [Logical communication channels over the selected Ethernet link.]
) <tab-ethernet-logical-channels>

This separation keeps the high-rate acquisition stream simple while allowing the PC to configure and monitor the instrument through the same physical link.

== PC-side acquisition software

The PC software acts as the user-facing acquisition and storage layer. It does not control the individual ADCs directly; that task remains inside the FPGA. The PC only configures the acquisition, receives frames, validates them and stores the resulting data with the required metadata.

=== Configuration and control

The control interface provides:

```text
load configuration
arm acquisition
start/stop acquisition
set sampling rates
select ADC range/gain configuration
read status flags
reset counters and FIFOs
```

The configuration sent to the FPGA must be stored together with the acquired data, so the measurement can be reproduced during post-processing.

=== Real-time monitoring

During a test, the software should display basic acquisition information:

```text
current data rate
frame counter
lost/corrupted frames
FIFO level / overflow flag
power-good state
trigger state
selected LF/HF sampling rates
```

Only lightweight visualization should be performed in real time, such as a small subset of time-domain channels and online spectra. Full beamforming or advanced acoustic processing is left for offline analysis.

=== Data storage format

The proposed storage format is HDF5. It is suitable for long acquisitions because it supports large multidimensional arrays, compression, metadata and hierarchical organization.

A possible file structure is:

```text
/acquisition/raw/LF
/acquisition/raw/HF
/acquisition/time/HF_counter
/acquisition/time/LF_counter
/metadata/channel_map
/metadata/sensor_positions
/metadata/sampling_rates
/metadata/adc_configuration
/metadata/calibration
/metadata/status_log
```

=== Metadata and calibration data

The metadata must be stored with the raw samples. At minimum, the file should contain the channel map, zone map, LF/HF branch assignment, sampling rates, ADC configuration, gain/range configuration, timestamp origin and calibration constants.

#figure(
  table(
    columns: (1.6fr, 3fr),
    inset: 6pt,
    fill: table-fill,
    align: left,

    table.header([*Metadata group*], [*Contents*]),

    [Channel map],
    [Relationship between branch, zone, sensor index and stored channel index.],

    [Geometry],
    [Physical position of each MEMS sensor in the array.],

    [Acquisition setup],
    [Sampling rates, frame size, trigger mode and selected data interface.],

    [ADC configuration],
    [Input range, digital interface mode and status/error configuration.],

    [Calibration],
    [Sensitivity, correction factors and calibration date for each channel.],
  ),
  caption: [Metadata groups stored with the acquired data.]
) <tab-storage-metadata>

== Preliminary design conclusion

The proposed data-handling architecture uses the FPGA as a deterministic acquisition controller and the PC as the storage and visualization unit. The FPGA synchronizes the 20 AD7606C-18 devices, reads the 160 digitized channels, maps each sample to its physical sensor, buffers the stream and sends framed data through 2.5G Ethernet.

#quote(block: true)[
The selected strategy separates time-critical acquisition from non-deterministic PC tasks. Sampling, readout and framing are handled inside the FPGA, while the acquisition computer focuses on reception, verification, storage and user interaction.
]
