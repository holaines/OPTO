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

#let diagram-box(body) = align(center)[
  #box(
    width: 92%,
    inset: 10pt,
    stroke: 0.8pt + blue,
    fill: pale-blue,
    radius: 6pt,
  )[
    #text(font: "Courier", size: 8pt, fill: navy)[#body]
  ]
]

#let equation-box(body, color: blue, fill-color: light-blue) = align(center)[
  #box(
    inset: 8pt,
    stroke: 0.7pt + color,
    fill: fill-color,
    radius: 5pt,
  )[
    #body
  ]
]

#let note-box(title, body, color: blue, fill-color: light-blue) = box(
  width: 100%,
  inset: 9pt,
  stroke: 0.7pt + color,
  fill: fill-color,
  radius: 5pt,
)[
  #text(fill: color, weight: "bold")[#title] \
  #body
]

#set heading(numbering: "1.1")

= AD7606C-18 acquisition stage

== Objective of the acquisition stage

The acquisition stage converts the conditioned analog MEMS signals into synchronized digital samples. The selected converter is the AD7606C-18.

The AD7606C-18 is used as an integrated data acquisition device because it includes:

#note-box(
  [Integrated acquisition functions],
  [
    - 8 analog input channels.
    - Simultaneous sampling.
    - 18-bit SAR ADC conversion.
    - Programmable input ranges.
    - Internal input buffer and PGA.
    - Internal analog low-pass filtering.
    - Internal reference and reference buffer.
    - Parallel or serial digital interface.
    - Per-channel calibration features.
  ],
  color: navy,
  fill-color: pale-blue,
)

This makes the AD7606C-18 suitable for the proposed zone-based architecture, where each group of 8 MEMS outputs from one frequency band is connected to one ADC device.

== ADC allocation per acquisition zone

Each acquisition zone contains 8 dual-frequency MEMS microphones. Therefore, each zone provides 16 analog signals:

#equation-box[
  $
  8 " LF signals" + 8 " HF signals" = 16 " analog signals"
  $
]

Since the AD7606C-18 has 8 input channels, two ADC devices are required per zone: one converter for the 8 LF channels and one converter for the 8 HF channels. The resulting acquisition structure for one zone is:

#figure(
  align(center)[
    #box(
      width: 95%,
      inset: 12pt,
      stroke: 0.8pt + blue,
      fill: pale-blue,
      radius: 6pt,
    )[
      #grid(
        columns: (1fr, 0.25fr, 1.3fr),
        column-gutter: 10pt,
        row-gutter: 10pt,
        align: center,

        // Left block: MEMS
        grid.cell(rowspan: 2)[
          #box(
            width: 100%,
            inset: 10pt,
            stroke: 0.9pt + navy,
            fill: rgb("#EAF3F8"),
            radius: 6pt,
          )[
            #align(center)[
              #text(weight: "bold", fill: navy)[8 MEMS microphones] \
              #text(size: 8pt, fill: navy)[dual-frequency outputs]
            ]
          ]
        ],

        // LF arrow
        [
          #text(size: 15pt, fill: blue)[→]
        ],

        // LF branch
        [
          #box(
            width: 100%,
            inset: 8pt,
            stroke: 0.9pt + blue,
            fill: rgb("#EAF3F8"),
            radius: 6pt,
          )[
            #align(center)[
              #text(weight: "bold", fill: blue)[8 LF conditioned outputs] \
              #text(size: 8pt, fill: blue)[→ AD7606C-18 LF]
            ]
          ]
        ],

        // HF arrow
        [
          #text(size: 15pt, fill: orange)[→]
        ],

        // HF branch
        [
          #box(
            width: 100%,
            inset: 8pt,
            stroke: 0.9pt + orange,
            fill: rgb("#FFF4E3"),
            radius: 6pt,
          )[
            #align(center)[
              #text(weight: "bold", fill: orange)[8 HF conditioned outputs] \
              #text(size: 8pt, fill: orange)[→ AD7606C-18 HF]
            ]
          ]
        ],
      )
    ]
  ],
  caption: [ADC allocation in one acquisition zone.]
)

For the complete 10-zone system:

#equation-box[
  $
  10 " zones" dot 2 " ADCs/zone" = 20 " AD7606C-18 devices"
  $
]

Since each AD7606C-18 has 8 channels:

#equation-box[
  $
  20 " ADCs" dot 8 " channels/ADC" = 160 " acquired channels"
  $
]

This exactly matches the 160 analog outputs of the 80 dual-frequency MEMS microphones.

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + navy,
    fill: pale-blue,
    radius: 5pt,
  )[
    #table(
      columns: (1.4fr, 1.3fr, 1.3fr, 1.3fr),
      inset: 7pt,
      align: center,

      table.cell(fill: navy)[#text(fill: white, weight: "bold")[Level]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[MEMS]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[Analog channels]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[AD7606C-18]],

      [One zone],
      [8],
      [16],
      [2],

      [Full system],
      [80],
      [160],
      [20],
    )
  ],
  caption: [ADC allocation per zone and for the complete MEMS array.]
) <table:adc_allocation>

== Removal of external analog multiplexers

The reference case study uses analog multiplexers to concentrate the outputs of 8 microphones before sending them to a remote acquisition system. In the proposed architecture, these external analog multiplexers are removed.

The reason is that the AD7606C-18 already integrates 8 simultaneously sampled ADC channels. Therefore, one AD7606C-18 can directly acquire the 8 LF outputs of a zone, and another AD7606C-18 can directly acquire the 8 HF outputs of the same zone.

This change has several advantages:

#note-box(
  [Advantages of removing the external analog multiplexer],
  [
    - It removes the delay between channels caused by analog time multiplexing.
    - It avoids settling errors after switching a multiplexer.
    - It reduces analog routing complexity.
    - It improves synchronization between microphones in the same zone.
    - It simplifies digital demultiplexing, because each ADC channel is permanently assigned to one MEMS output.
  ],
  color: green,
  fill-color: light-green,
)

The final architecture is therefore not:

#figure(
  diagram-box[
    8 MEMS outputs → analog MUX → one ADC channel
  ],
  caption: [Rejected multiplexed acquisition approach.]
)

but:

#figure(
  diagram-box[
    8 MEMS outputs → 8 simultaneous ADC channels
  ],
  caption: [Selected simultaneous acquisition approach.]
)

This is especially important for acoustic array measurements, where relative timing between channels affects phase and spatial analysis.

== Simultaneous sampling

All eight SAR ADCs inside the AD7606C-18 sample their respective inputs simultaneously on the rising edge of the CONVST signal. This means that the 8 channels of one frequency band and one zone are sampled at the same instant.

For one zone:

#figure(
  diagram-box[
    CONVST_LF rising edge → simultaneous sampling of 8 LF channels \
    CONVST_HF rising edge → simultaneous sampling of 8 HF channels
  ],
  caption: [Simultaneous sampling command per zone.]
)

For the complete system, the FPGA distributes synchronized CONVST signals to the 20 ADC devices. This allows the acquisition system to maintain a common time base across the 160 channels.

The FPGA also reads the BUSY signal from the ADCs. The BUSY signal indicates that conversion is in progress. Once BUSY returns low, the conversion data can be read through the selected digital interface.

The basic acquisition sequence is:

#figure(
  diagram-box[
    1. FPGA asserts CONVST. \
    2. AD7606C-18 samples all 8 channels simultaneously. \
    3. BUSY goes high during conversion. \
    4. BUSY goes low when conversion is complete. \
    5. FPGA reads the 8 conversion results. \
    6. FPGA adds timestamp and channel metadata. \
    7. Data are written to FIFO and sent to the PC/DAQ.
  ],
  caption: [Basic acquisition sequence controlled by the FPGA.]
)

== LF and HF ADC configuration

The LF and HF bands have different bandwidth requirements. Therefore, the two AD7606C-18 devices in each zone are configured differently.

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + blue,
    fill: pale-blue,
    radius: 5pt,
  )[
    #table(
      columns: (1fr, 1.5fr, 1.5fr, 1.7fr),
      inset: 7pt,
      align: center,

      table.cell(fill: navy)[#text(fill: white, weight: "bold")[Band]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[MEMS useful bandwidth]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[ADC bandwidth mode]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[Proposed sample rate]],

      [LF],
      [Up to 10 kHz],
      [Low-bandwidth mode, 25 kHz],
      [50 kS/s to 100 kS/s per channel],

      [HF],
      [Up to 100 kHz],
      [High-bandwidth mode, 220 kHz],
      [500 kS/s to 1 MS/s per channel],
    )
  ],
  caption: [Proposed AD7606C-18 configuration for LF and HF acquisition.]
) <table:adc_lf_hf_configuration>

The LF output only requires acquisition up to 10 kHz. A sample rate of 50 kS/s gives 5 samples per period at 10 kHz, while 100 kS/s gives 10 samples per period. Since the AD7606C-18 supports up to 1 MS/s per channel, the LF channels can also use oversampling or averaging if required.

The HF output requires acquisition up to 100 kHz. The minimum theoretical sampling frequency according to the Nyquist criterion is:

#equation-box[
  $
  f_s > 2 dot 100 " kHz" = 200 " kS/s"
  $
]

However, using a higher sampling frequency improves waveform representation and simplifies digital filtering. A practical target is therefore:

#equation-box[
  $
  f_"s,HF" = 500 " kS/s to " 1 " MS/s"
  $
]

At 1 MS/s, the number of samples per period at 100 kHz is:

#equation-box[
  $
  N = f_s / f_"max" = 1 " MHz" / 100 " kHz" = 10 " samples/period"
  $
]

Therefore, the AD7606C-18 is compatible with the HF bandwidth if a maximum of 10 samples per period at 100 kHz is accepted. If the design requirement were 20 samples per period at 100 kHz, the required sampling frequency would be:

#equation-box[
  $
  f_s = 20 dot 100 " kHz" = 2 " MS/s"
  $
]

This would exceed the 1 MS/s per-channel throughput of the AD7606C-18. Therefore, the selected ADC is valid for Nyquist-compliant acquisition and 10 samples per period at 100 kHz, but not for a strict 20-samples-per-period requirement at the maximum HF frequency.

== Input range selection

The AD7606C-18 provides several selectable input ranges. The most relevant ranges for this design are:

#note-box(
  [Relevant input ranges],
  [
    - Bipolar single-ended: ±12.5 V, ±10 V, ±6.25 V, ±5 V and ±2.5 V.
    - Unipolar single-ended: 0 V to 12.5 V, 0 V to 10 V and 0 V to 5 V.
    - Bipolar differential: ±20 V, ±12.5 V, ±10 V and ±5 V.
  ],
  color: blue,
  fill-color: light-blue,
)

The preliminary proposal is to use bipolar acquisition because the MEMS outputs are AC-coupled acoustic signals. A practical configuration is:

#figure(
  diagram-box[
    Preferred preliminary range: ±10 V or ±5 V single-ended \
    Alternative for higher margin: ±20 V differential, if the analog front-end is implemented differentially
  ],
  caption: [Preliminary ADC input range selection.]
)

The final input range must be selected together with the gain/attenuation of the analog front-end. The design rule is:

#equation-box(color: orange, fill-color: light-orange)[
  $
  abs(V_"ADC,in") <= V_"ADC,FS"
  $
]

where $V_"ADC,FS"$ is the selected ADC full-scale voltage.

For example, with the ±10 V range, the ADC input must remain inside:

#equation-box(color: orange, fill-color: light-orange)[
  $
  -10 " V" <= V_"ADC,in" <= +10 " V"
  $
]

Therefore, high-SPL signals require analog attenuation before the ADC input.

== Resolution and LSB size

The AD7606C-18 has 18-bit resolution. For a bipolar input range, the approximate LSB size is:

#equation-box[
  $
  "LSB" = "FSR" / 2^18
  $
]

where FSR is the full-scale span.

For the ±10 V range:

$
"FSR" = 20 " V"
$

$
"LSB" = 20 " V" / 2^18 = 76.3 " µV"
$

For the ±5 V range:

$
"FSR" = 10 " V"
$

$
"LSB" = 10 " V" / 2^18 = 38.1 " µV"
$

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + green,
    fill: light-green,
    radius: 5pt,
  )[
    #table(
      columns: (1.3fr, 1.3fr, 1.3fr),
      inset: 7pt,
      align: center,

      table.cell(fill: green)[#text(fill: white, weight: "bold")[ADC range]],
      table.cell(fill: green)[#text(fill: white, weight: "bold")[Full-scale span]],
      table.cell(fill: green)[#text(fill: white, weight: "bold")[Approximate LSB]],

      [±10 V],
      [20 V],
      [76.3 µV],

      [±5 V],
      [10 V],
      [38.1 µV],
    )
  ],
  caption: [Approximate LSB size for two relevant AD7606C-18 bipolar input ranges.]
) <table:adc_lsb>

This resolution is significantly better than the 14-bit DAQ used in the reference case study. However, the LSB size must be compared with the conditioned signal at the ADC input, not with the raw MEMS output. This is why the analog gain state is important.

== Digital filter and calibration

The AD7606C-18 includes a flexible digital filter and oversampling options. These features are useful mainly for the LF path, where the required bandwidth is lower and more samples can be averaged to improve noise performance.

The device also includes per-channel calibration features:

#note-box(
  [Per-channel calibration features],
  [
    - Offset calibration.
    - Gain calibration.
    - Phase calibration.
    - Open-circuit detection.
  ],
  color: green,
  fill-color: light-green,
)

These functions are useful because the complete system contains 160 analog channels, and small mismatches between channels are expected. During calibration, known acoustic or electrical test signals can be applied, and the correction coefficients can be stored in the acquisition software.

The corrected voltage can be represented as:

#equation-box[
  $
  V_"corrected" = a dot V_"measured" + b
  $
]

where:

- $a$ is the gain correction factor.
- $b$ is the offset correction term.

The final acoustic pressure is then reconstructed as:

#equation-box[
  $
  p = V_"corrected" / (S dot G_"AFE")
  $
]

where $S$ is the MEMS sensitivity and $G_"AFE"$ is the analog front-end gain or attenuation.

== Digital interface with the FPGA

The AD7606C-18 supports both parallel and serial digital interfaces. For this system, the interface selection must be coordinated with the FPGA I/O budget.

The parallel interface provides faster readout but requires more FPGA pins per ADC. The serial interface reduces the number of FPGA pins but requires higher serial clock frequency and careful timing management.

For a system with 20 ADC devices, the recommended preliminary choice is to use the serial interface with shared control signals where possible:
#figure(
  align(center)[
    #box(
      width: 92%,
      inset: 10pt,
      stroke: 0.8pt + blue,
      fill: pale-blue,
      radius: 6pt,
    )[
      #grid(
        columns: (1fr, 1fr),
        column-gutter: 24pt,
        align: top,

        [
          #text(fill: navy, weight: "bold")[Shared signals] \
          #table(
            columns: (1fr,),
            inset: 4pt,
            stroke: none,
            align: left,
            [CONVST],
            [RESET],
            [SCLK],
            [SDI / configuration lines, if used],
          )
        ],

        [
          #text(fill: navy, weight: "bold")[Per-ADC or grouped signals] \
          #table(
            columns: (1fr,),
            inset: 4pt,
            stroke: none,
            align: left,
            [CS],
            [BUSY],
            [DOUT lines],
          )
        ],
      )
    ]
  ],
  caption: [Preliminary digital interface signal allocation.]
)

This reduces the FPGA I/O requirement while keeping all ADCs synchronized from the same sampling command.

The exact digital pin count is developed in the FPGA section of the report. From the analog/acquisition point of view, the important requirement is that all ADCs receive a synchronized CONVST signal and that the FPGA can read all conversion results before the next sampling instant.

== Power and reference requirements

Each AD7606C-18 requires:

#note-box(
  [AD7606C-18 supply and reference requirements],
  [
    - AVCC = 5 V analog supply.
    - VDRIVE = 1.71 V to 5.25 V digital interface supply.
    - Internal or external 2.5 V reference.
  ],
  color: blue,
  fill-color: light-blue,
)

In this design:

#figure(
  diagram-box[
    AVCC → 5 V_A analog rail \
    VDRIVE → 3.3 V_D digital rail \
    Reference → internal reference for preliminary design, external precision reference as improvement
  ],
  caption: [Power and reference allocation for the AD7606C-18.]
)

The analog and digital supplies must be decoupled locally. Each ADC must have local ceramic decoupling capacitors close to its supply pins. The reference node must be routed carefully and kept away from fast digital lines.

== Thermal and operating-temperature compatibility

The AD7606C-18 is specified for operation from -40 °C to +125 °C. This is compatible with the wind tunnel test temperature range of -20 °C to +70 °C.

#note-box(
  [Temperature limitation],
  [
    However, the flight test requirement includes temperatures down to -65 °C. Therefore, the selected AD7606C-18 does not fully cover the lowest flight-test temperature requirement. This must be stated as a limitation of the preliminary design.

    The same limitation applies to the proposed AD8429 low-noise amplifier candidate, which is also specified from -40 °C to +125 °C.
  ],
  color: red,
  fill-color: light-red,
)

Therefore, the preliminary design is suitable for WTT operation and for FT operation only if the electronics are kept within their specified temperature range by placement, insulation, heating, or component replacement with extended-temperature alternatives.

== Main limitations of the selected ADC solution

The AD7606C-18 is a strong candidate for this project because it integrates 8 simultaneous 18-bit ADC channels, analog input conditioning and digital filtering. However, the following limitations must be considered:

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + red,
    fill: light-red,
    radius: 5pt,
  )[
    #table(
      columns: (1.5fr, 2.5fr),
      inset: 7pt,
      align: left,

      table.cell(fill: red)[#text(fill: white, weight: "bold")[Limitation]],
      table.cell(fill: red)[#text(fill: white, weight: "bold")[Impact on the design]],

      [1 MS/s maximum per channel],
      [Valid for 100 kHz acquisition with 10 samples per period, but not enough for a strict 20 samples per period at 100 kHz.],

      [-40 °C minimum operating temperature],
      [Compatible with WTT, but not fully compatible with the -65 °C FT requirement.],

      [ADC input range limited to selected full-scale voltage],
      [External gain/attenuation is required because raw MEMS outputs can reach tens of volts at high SPL.],

      [High number of ADC devices],
      [20 devices are required for the complete 160-channel system, so FPGA I/O and PCB routing must be carefully planned.],
    )
  ],
  caption: [Main limitations of the AD7606C-18 acquisition solution.]
) <table:adc_limitations>

== Acquisition-stage conclusion

#note-box(
  [Conclusion],
  [
    The proposed acquisition architecture uses two AD7606C-18 devices per zone: one for the 8 LF outputs and one for the 8 HF outputs. Across 10 zones, the full system uses 20 AD7606C-18 devices and acquires 160 analog channels.

    The use of the AD7606C-18 removes the need for external analog multiplexers because each ADC provides 8 simultaneous sampling channels. This improves timing alignment between microphones and avoids the sampling delay introduced by multiplexed acquisition.

    The LF ADCs can operate at lower sample rates, typically 50 kS/s to 100 kS/s per channel, while the HF ADCs can operate at 500 kS/s to 1 MS/s per channel. At 1 MS/s, the system obtains 10 samples per period at 100 kHz, which is acceptable for Nyquist-compliant acquisition but below a strict 20-samples-per-period criterion.

    The main unresolved issue is not the number of channels but the analog dynamic range. The MEMS outputs can be extremely small at low SPL and too large at high SPL. Therefore, the AD7606C-18 must be used together with a calibrated analog front-end providing low-noise amplification, attenuation, protection and filtering.
  ],
  color: navy,
  fill-color: light-grey,
)