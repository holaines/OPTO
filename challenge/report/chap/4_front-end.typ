#let navy = rgb("#17324D")
#let blue = rgb("#2F6F9F")
#let light-blue = rgb("#EAF3F8")
#let pale-blue = rgb("#F6FAFD")
#let green = rgb("#3A7D44")
#let light-green = rgb("#ECF7EF")
#let orange = rgb("#B86B00")
#let light-orange = rgb("#FFF4E3")
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

= Sensor MEMS and analog front-end

== Objective

The objective of the analog front-end is to interface the dual-frequency MEMS microphones with the acquisition stage while preserving the acoustic information in both frequency bands. Each MEMS microphone provides two independent AC-coupled outputs:

- LF output: low-frequency section.
- HF output: high-frequency section.

Therefore, each physical MEMS microphone generates two analog electrical signals. Since the complete system contains 80 MEMS microphones, the acquisition system must process:

#align(center)[
  #box(
    inset: 8pt,
    stroke: 0.7pt + blue,
    fill: light-blue,
    radius: 5pt,
  )[
    $
    80 " MEMS" dot 2 " outputs/MEMS" = 160 " analog channels"
    $
  ]
]

The system is divided into 10 identical acquisition zones. Each zone contains 8 MEMS microphones. Therefore, each zone contains:

#align(center)[
  #box(
    inset: 8pt,
    stroke: 0.7pt + blue,
    fill: light-blue,
    radius: 5pt,
  )[
    $
    8 " MEMS" dot 2 " outputs/MEMS" = 16 " analog channels per zone"
    $
  ]
]

The proposed analog architecture for one zone is:

#figure(
  diagram-box[
    One acquisition zone \
    8 dual-frequency MEMS microphones \
    ├── 8 LF outputs → LF analog conditioning → AD7606C-18 LF \
    └── 8 HF outputs → HF analog conditioning → AD7606C-18 HF
  ],
  caption: [Analog architecture of one acquisition zone.]
)

This architecture is repeated 10 times in the complete array.

== Dual-frequency MEMS characteristics

The selected sensing technology is based on dual-frequency piezoelectric MEMS microphones. The sensor has two mechanical and electrical sections:

- A low-frequency section, intended for the LF output.
- A high-frequency section, intended for the HF output.

The LF and HF sections are treated as independent analog outputs. The design assumptions used for this project are summarized in @table:mems_characteristics.

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + blue,
    fill: pale-blue,
    radius: 5pt,
  )[
    #table(
      columns: (1.4fr, 1.3fr, 1.3fr),
      inset: 7pt,
      align: center,

      table.cell(fill: navy)[#text(fill: white, weight: "bold")[Parameter]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[LF output]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[HF output]],

      [Useful frequency range],
      [Up to 10 kHz],
      [Up to 100 kHz],

      [Sensitivity],
      [10 mV/Pa],
      [5 mV/Pa],

      [Equivalent capacitance],
      [1.9 nF],
      [785 pF],

      [Equivalent resistance],
      [90 kΩ],
      [47 kΩ],
    )
  ],
  caption: [Electrical characteristics assumed for the dual-frequency MEMS outputs.]
) <table:mems_characteristics>

The LF output has higher sensitivity, which is useful for low-frequency acoustic components. The HF output has lower sensitivity but wider useful bandwidth, which is required to cover the upper part of the aeroacoustic spectrum.

== Analog chain per channel

Each MEMS output is connected to an individual analog conditioning path before the ADC input. The proposed path is:

#figure(
  align(center)[
    #grid(
      columns: (1fr,),
      row-gutter: 6pt,
      align: center,

      [
        #box(
          width: 65%,
          inset: 8pt,
          stroke: 0.9pt + navy,
          fill: rgb("#EAF3F8"),
          radius: 6pt,
        )[
          #align(center)[
            #text(weight: "bold", fill: navy)[MEMS LF/HF output]
          ]
        ]
      ],

      [#text(size: 15pt, fill: blue)[↓]],

      [
        #box(
          width: 65%,
          inset: 8pt,
          stroke: 0.9pt + green,
          fill: rgb("#ECF7EF"),
          radius: 6pt,
        )[
          #align(center)[
            #text(weight: "bold", fill: green)[High-impedance buffer / LNA]
          ]
        ]
      ],

      [#text(size: 15pt, fill: blue)[↓]],

      [
        #box(
          width: 65%,
          inset: 8pt,
          stroke: 0.9pt + orange,
          fill: rgb("#FFF4E3"),
          radius: 6pt,
        )[
          #align(center)[
            #text(weight: "bold", fill: orange)[Gain or attenuation stage]
          ]
        ]
      ],

      [#text(size: 15pt, fill: blue)[↓]],

      [
        #box(
          width: 65%,
          inset: 8pt,
          stroke: 0.9pt + blue,
          fill: rgb("#F6FAFD"),
          radius: 6pt,
        )[
          #align(center)[
            #text(weight: "bold", fill: blue)[Protection + small RC filter]
          ]
        ]
      ],

      [#text(size: 15pt, fill: blue)[↓]],

      [
        #box(
          width: 65%,
          inset: 8pt,
          stroke: 1pt + red,
          fill: rgb("#FDECEC"),
          radius: 6pt,
        )[
          #align(center)[
            #text(weight: "bold", fill: red)[AD7606C-18 input]
          ]
        ]
      ],
    )
  ],
  caption: [Proposed analog front-end per MEMS output.]
)

The analog front-end is required for four reasons:

#note-box(
  [Design rationale],
  [
    1. The MEMS outputs are piezoelectric and have a non-negligible equivalent impedance. The ADC must not directly load the sensor.
    2. At low sound pressure levels, the MEMS output voltage is in the microvolt range. A low-noise amplification stage is required to use the ADC resolution efficiently.
    3. At high sound pressure levels, the MEMS output voltage can exceed the ADC input range. Therefore, attenuation or gain control is required to avoid saturation.
    4. The analog input must be protected against overload, electrostatic discharge and out-of-range transients.
  ],
)

The AD7606C-18 includes an internal input buffer, PGA and low-pass filter, but these blocks do not completely remove the need for an external analog interface. They simplify the acquisition stage, but the MEMS signal still requires impedance adaptation and range scaling before entering the ADC.

== Sound pressure and MEMS output range

The acoustic sound pressure level is defined as:

#align(center)[
  #box(
    inset: 8pt,
    stroke: 0.7pt + green,
    fill: light-green,
    radius: 5pt,
  )[
    $
    "SPL" = 20 log_10(p / p_0)
    $
  ]
]

where:

$
p_0 = 20 " µPa"
$

Therefore, the acoustic pressure corresponding to a given SPL is:

$
p = p_0 dot 10^("SPL" / 20)
$

For the minimum wind tunnel test input level of 30 dB SPL:

$
p_"min" = 20 " µPa" dot 10^(30 / 20) = 632 " µPa"
$

For the maximum wind tunnel test input level of 170 dB SPL:

$
p_"max" = 20 " µPa" dot 10^(170 / 20) = 6324 " Pa" = 6.324 " kPa"
$

The open-loop MEMS output voltage is approximately:

#align(center)[
  #box(
    inset: 8pt,
    stroke: 0.7pt + green,
    fill: light-green,
    radius: 5pt,
  )[
    $
    V_"MEMS" = S dot p
    $
  ]
]

where $S$ is the MEMS sensitivity.

For the LF output:

$
V_"LF,min" = 10 " mV/Pa" dot 632 " µPa" = 6.32 " µV"
$

$
V_"LF,max" = 10 " mV/Pa" dot 6324 " Pa" = 63.24 " V"
$

For the HF output:

$
V_"HF,min" = 5 " mV/Pa" dot 632 " µPa" = 3.16 " µV"
$

$
V_"HF,max" = 5 " mV/Pa" dot 6324 " Pa" = 31.62 " V"
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
      columns: (1.5fr, 1.5fr, 1.5fr),
      inset: 7pt,
      align: center,

      table.cell(fill: green)[#text(fill: white, weight: "bold")[Case]],
      table.cell(fill: green)[#text(fill: white, weight: "bold")[LF output, 10 mV/Pa]],
      table.cell(fill: green)[#text(fill: white, weight: "bold")[HF output, 5 mV/Pa]],

      [30 dB SPL],
      [6.32 µV],
      [3.16 µV],

      [170 dB SPL],
      [63.24 V],
      [31.62 V],
    )
  ],
  caption: [Estimated raw MEMS output voltage at the minimum and maximum WTT SPL levels.]
) <table:mems_output_range>

These voltages are worst-case linear extrapolations obtained from the nominal MEMS sensitivities. They should not be interpreted as guaranteed linear sensor output voltages over the complete acoustic range. In practice, the MEMS mechanical response, the piezoelectric interface, the LNA input range, the protection network and the ADC input range may limit the usable voltage before these values are reached. Therefore, this calculation is mainly used to justify the need for selectable gain, attenuation and input protection.

This calculation shows that the analog front-end cannot be a fixed-gain amplifier only. At low SPL, the signals are very small and require low-noise amplification. At high SPL, the raw MEMS output may exceed the ADC input range and requires attenuation or a lower gain state.

== Gain and attenuation strategy

The proposed solution is a selectable-gain analog front-end. The gain state is selected according to the expected acoustic level or during a calibration/acquisition setup phase.

A practical preliminary strategy is shown in @table:gain_strategy.

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + orange,
    fill: light-orange,
    radius: 5pt,
  )[
    #table(
      columns: (1.2fr, 1.6fr, 2.3fr),
      inset: 7pt,
      align: left,

      table.cell(fill: orange)[#text(fill: white, weight: "bold")[Mode]],
      table.cell(fill: orange)[#text(fill: white, weight: "bold")[Purpose]],
      table.cell(fill: orange)[#text(fill: white, weight: "bold")[Description]],

      [High-gain mode],
      [Low SPL acquisition],
      [Amplifies microvolt-level MEMS signals to improve ADC code utilization.],

      [Unity-gain mode],
      [Medium SPL acquisition],
      [Uses the ADC input range without excessive amplification.],

      [Attenuation mode],
      [High SPL acquisition],
      [Prevents ADC saturation when the acoustic pressure is high.],
    )
  ],
  caption: [Proposed gain strategy for the analog front-end.]
) <table:gain_strategy>

The selected gain or attenuation value must be stored together with the acquired data. This allows the software to reconstruct the acoustic pressure from the ADC code during post-processing.

The pressure reconstruction can be written as:

#align(center)[
  #box(
    inset: 8pt,
    stroke: 0.7pt + orange,
    fill: light-orange,
    radius: 5pt,
  )[
    $
    p = V_"ADC,in" / (S dot G_"AFE")
    $
  ]
]

where:

- $p$ is the acoustic pressure.
- $V_"ADC,in"$ is the voltage at the ADC input.
- $S$ is the MEMS sensitivity.
- $G_"AFE"$ is the total analog front-end gain, including amplification or attenuation.

== Low-noise amplifier selection

A low-noise instrumentation amplifier is required close to the MEMS output. A suitable candidate is the AD8429 because it provides:

- Input voltage noise of 1 nV/√Hz.
- Programmable gain from 1 to 10000.
- 15 MHz small-signal bandwidth at gain 1.
- 1.2 MHz bandwidth at gain 100.
- Operation over the industrial temperature range from -40 °C to +125 °C.

However, the AD8429 requires bipolar analog supplies because it is specified for ±4 V to ±18 V operation. Therefore, if this amplifier is finally selected, the power architecture must include positive and negative analog rails, for example ±5 V_A or ±12 V_A. If the final power tree only provides a single 5 V_A rail, then the AD8429 should be treated only as a representative low-noise candidate and replaced by a single-supply low-noise amplifier compatible with the final supply architecture.

The gain of the AD8429 is set by a resistor according to:

#align(center)[
  #box(
    inset: 8pt,
    stroke: 0.7pt + blue,
    fill: light-blue,
    radius: 5pt,
  )[
    $
    G = 1 + 6 " kΩ" / R_G
    $
  ]
]

Therefore:

$
R_G = 6 " kΩ" / (G - 1)
$

Example values are shown in @table:ad8429_gain_examples.

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + blue,
    fill: pale-blue,
    radius: 5pt,
  )[
    #table(
      columns: (1fr, 1fr, 2fr),
      inset: 7pt,
      align: left,

      table.cell(fill: navy)[#text(fill: white, weight: "bold")[Target gain]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[$R_G$]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[Use case]],

      [$G = 1$],
      [Open circuit],
      [Unity-gain buffer / medium SPL operation.],

      [$G = 2$],
      [6 kΩ],
      [Moderate amplification.],

      [$G = 10$],
      [667 Ω],
      [Low-level signal acquisition.],

      [$G = 100$],
      [60.6 Ω],
      [Very low-level signal acquisition, only if output swing and bandwidth remain compatible.],
    )
  ],
  caption: [Example gain-setting resistor values for the AD8429.]
) <table:ad8429_gain_examples>

For this preliminary design, the AD8429 is used as a representative low-noise amplifier candidate. The final gain values must be selected after defining the exact maximum ADC input range, expected SPL during each test and required calibration procedure.

== ADC input range compatibility

The AD7606C-18 supports several input ranges, including bipolar single-ended ranges of ±12.5 V, ±10 V, ±6.25 V, ±5 V and ±2.5 V, and differential bipolar ranges up to ±20 V.

Because the raw MEMS voltage can reach tens of volts at the maximum SPL, direct connection to the ADC is not acceptable for the full dynamic range.

Although the AD7606C-18 includes analog input clamp protection, this protection must be treated as an overload or transient protection feature, not as a normal operating condition. The analog front-end must ensure that the steady-state ADC input voltage remains inside the selected full-scale input range.

 Therefore, the analog front-end must guarantee:

#align(center)[
  #box(
    inset: 8pt,
    stroke: 0.7pt + orange,
    fill: light-orange,
    radius: 5pt,
  )[
    $
    abs(V_"ADC,in") <= V_"ADC,FS"
    $
  ]
]

where $V_"ADC,FS"$ is the selected full-scale input range of the AD7606C-18.


For example, if the ±10 V single-ended range is selected, the maximum allowed ADC input magnitude is 10 V. The required attenuation at 170 dB SPL is then:

For LF:

$
A_"LF" <= 10 " V" / 63.24 " V" = 0.158
$

$
20 log_10(A_"LF") = -16.0 " dB"
$

For HF:

$
A_"HF" <= 10 " V" / 31.62 " V" = 0.316
$

$
20 log_10(A_"HF") = -10.0 " dB"
$

Therefore, high-SPL operation requires attenuation. The LF path requires stronger attenuation than the HF path because the LF MEMS sensitivity is higher.

== Protection and input filtering

Each ADC input should include a small passive network between the analog front-end and the AD7606C-18. This network has three purposes:

- Limit input current during overload.
- Reduce high-frequency interference before the ADC input.
- Improve robustness against electrostatic discharge and cable/PCB coupling.

A preliminary implementation is:

#figure(
  diagram-box[
    Analog front-end output \
    $arrow.b$ \ 
    small series resistor \
    $arrow.b$ \ 
    optional RC low-pass filter \
    $arrow.b$ \ 
    AD7606C-18 analog input
  ],
  caption: [Preliminary protection and input filtering network.]
)

The cutoff frequency must be chosen above the useful signal bandwidth:

- LF path: cutoff above 10 kHz.
- HF path: cutoff above 100 kHz.

This external RC network is not intended to define the measurement bandwidth. Its cutoff frequency must be placed above the useful acoustic band and its main role is to reduce RF interference, limit input current during overload and improve robustness. The main bandwidth limitation is defined by the MEMS response, the analog front-end and the AD7606C-18 internal filter mode.

== Component count

The analog component count follows directly from the 10-zone architecture. Each zone contains 8 dual-frequency MEMS microphones, therefore 16 analog signal paths. Each zone uses one AD7606C-18 for the 8 LF channels and one AD7606C-18 for the 8 HF channels.

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + navy,
    fill: light-grey,
    radius: 5pt,
  )[
    #table(
      columns: (1.1fr, 0.8fr, 1.5fr, 2.1fr, 1.2fr),
      inset: 7pt,
      align: center,

      table.cell(fill: navy)[#text(fill: white, weight: "bold")[System level]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[MEMS]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[Analog outputs]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[Analog conditioning paths]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[AD7606C-18]],

      [One zone],
      [8],
      [16],
      [16],
      [2],

      [Full system],
      [80],
      [160],
      [160],
      [20],
    )
  ],
  caption: [Analog front-end and ADC count per zone and for the full 80-MEMS system.]
) <table:component_count_frontend>

== Analog front-end conclusion

#note-box(
  [Conclusion],
  [
    The proposed analog front-end keeps the LF and HF outputs separated, preserving the dual-frequency behavior of the MEMS microphones. Each zone contains 16 analog paths: 8 LF paths and 8 HF paths. The external analog multiplexer is not used in the final architecture because each AD7606C-18 already acquires 8 channels simultaneously.

    However, the external analog interface is still necessary. Using a linear extrapolation from the nominal MEMS sensitivity, the MEMS output can range from microvolts at low SPL to tens of volts at high SPL. This does not mean that the sensor is guaranteed to remain linear up to these voltages, but it justifies the need for gain control, attenuation and protection.. Therefore, each channel requires a low-noise buffer/LNA, selectable gain or attenuation, protection and local filtering before the AD7606C-18 input.

    The main design limitation is the very wide acoustic dynamic range. The front-end must be calibrated and the selected gain state must be stored with the acquired data so that the acoustic pressure can be reconstructed accurately during post-processing.
  ],
  color: navy,
  fill-color: light-grey,
)
