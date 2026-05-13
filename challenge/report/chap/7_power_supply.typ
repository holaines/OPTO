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

#let pblock(title, body, color: none) = box(
  width: 100%,
  inset: 6pt,
  stroke: 0.7pt,
  radius: 4pt,
  fill: if color == none { blue.lighten(75%) } else { color },
)[
  #strong[#title] \
  #text(size: 8.5pt)[#body]
]

#let custom-arrow = align(center + horizon)[$arrow.r$]
#let down-arrow = align(center)[$arrow.b$]
#let left-arrow = align(center + horizon)[$arrow.l$]

= Power supply and electrical integration

== Design objective

The instrumentation system must be powered either from the aircraft DC bus, nominally 28 V, or from an auxiliary 24 V battery. The power architecture must therefore tolerate a noisy high-voltage input and generate low-noise supply rails for the analog front-end, the AD7606C-18 acquisition ICs, the MEMS-adjacent LNAs, and the FPGA-based digital acquisition stage.

The proposed architecture uses a cascaded supply tree. A first switching converter reduces the 24 V / 28 V input to an intermediate 7 V rail. From this rail, separated analog and digital branches are generated. Sensitive analog rails are produced using low-noise linear regulators, while the high-current FPGA core rails are generated with dedicated switching regulators.

== Power tree

#figure(
  align(center)[
    #box(inset: 8pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(90%))[
      #grid(
        columns: (1fr,),
        row-gutter: 8pt,
        align: center,

        [#strong[24 V battery / 28 V aircraft bus]],
        [$arrow.b$],
        [#strong[Input protection + EMI filter]],
        [$arrow.b$],
        [#strong[Main buck converter: 24/28 V $arrow.r$ 7 V]],
        [$arrow.b$],
        [
          #grid(
            columns: (1fr, 1fr),
            column-gutter: 24pt,
            align: center,

            [
              #box(inset: 6pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(75%))[
                #strong[Analog branch] \
                7 V $arrow.r$ low-noise LDO $arrow.r$ $+5 V_A$ \
                7 V $arrow.r$ inverting converter $arrow.r$ $-5 V_A$ \
                $plus.minus 5 V_A$: AD8429 LNA / buffer \
                $+5 V_A$ only: #smallcaps[AD7606C-18] AVCC \
                ADC reference and bias
              ]
            ],
            [
              #box(inset: 6pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(75%))[
                #strong[Digital branch] \
                7 V $arrow.r$ $5 V_D$ \
                $5 V_D$ $arrow.r$ $3.3 V_D$ \
                $5 V_D$ $arrow.r$ 1.8 V / 1.0 V FPGA rails \
                #v(0.9em)
              ]
            ],
          )
        ],
      )
    ]
  ],
  caption: [Proposed cascaded power architecture.]
)

== Input stage

The input stage adapts the 24 V auxiliary battery or the nominal 28 V aircraft DC bus to the internal power tree. Its function is not only voltage conversion: it must also protect the instrumentation against reverse polarity, conducted transients, overcurrent faults and high-frequency conducted noise before the first regulator.

#figure(
  align(center)[
    #box(inset: 8pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(92%))[
      #grid(
        columns: (1.3fr, 0.25fr, 1.45fr, 0.25fr, 1.7fr),
        row-gutter: 10pt,
        column-gutter: 6pt,
        align: horizon,

        pblock([External input], [24 V battery \
        28 V aircraft DC bus]),
        custom-arrow,
        pblock([Primary protection], [Input fuse \
        TVS clamp]),
        custom-arrow,
        pblock([Electronic protection], [Reverse-polarity blocking \
        UV/OV protection \
        current limiting]),

        [], [], [], [], down-arrow,

        pblock([Protected output], [Protected 7 V \
        intermediate rail]),
        left-arrow,
        pblock([Pre-regulation], [Low-EMI buck converter \
        24/28 V $arrow.r$ 7 V]),
        left-arrow,
        pblock([Input filtering], [Common-mode choke \
        bulk + ceramic capacitors]),
      )
    ]
  ],
  caption: [Input power path from the 24/28 V source to the protected 7 V intermediate rail.]
)

Using the components listed in @table:component_list, the input stage provides robust protection against common electrical faults and transients while generating a protected 7 V intermediate rail for the downstream analog and digital regulators.

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + navy,
    fill: pale-blue,
    radius: 5pt,
  )[
    #table(
      columns: (1.4fr, 2.3fr, 2.5fr),
      inset: 7pt,
      align: left,

      table.cell(fill: navy)[#text(fill: white, weight: "bold")[Block]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[Selected components]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[Function]],

      [Primary protection],
      [F1: Littelfuse 0451010.MRL \
      D1: Littelfuse SMCJ33A],
      [Disconnects the board under hard faults and clamps positive input transients before they reach the active protection stage.],

      [Electronic protection],
      [U1: LTC4368-2 \
      Q1-Q2: BSC026N08NS5 \
      Rsense: WSL2512R0100FEA],
      [Provides reverse-polarity blocking, undervoltage/overvoltage lockout and active overcurrent protection.],

      [Input filtering],
      [L1: TDK ACM7060-301-2PL-TL01 \
      Cbulk + Cmid + Chf],
      [Attenuates conducted EMI and provides local input energy storage for the switching regulator.],

      [Pre-regulation],
      [U2: LT8645S \
      L2: Coilcraft XAL7070-472MEC],
      [Generates the 7 V intermediate rail with high efficiency and enough margin for the downstream 5 V regulators.],
    )
  ],
  caption: [Selected components for the input stage blocks.],
)<table:component_list>

The first protection element is a surface-mount fuse, selected as #strong[Littelfuse 0451010.MRL]. This device belongs to the 451 Nano2 family and is a very fast-acting 10 A SMD fuse. It is placed before the TVS and before the electronic protection stage so that a hard short-circuit or a destructive fault disconnects the board from the external supply. The fuse acts as the final non-resettable safety element.

The transient suppressor is #strong[Littelfuse SMCJ33A]. It is a unidirectional 1.5 kW TVS diode with 33 V reverse stand-off voltage. This value is above the nominal 28 V bus, so the diode remains off during normal operation, but its breakdown voltage is low enough to clamp positive transients before they reach the downstream regulators.

Reverse polarity, sustained overvoltage, undervoltage and active overcurrent protection are implemented with #strong[Analog Devices LTC4368-2]. This IC controls two external N-channel MOSFETs connected back-to-back. The back-to-back structure blocks current in both directions when the protection stage is off, unlike a single MOSFET arrangement where the body diode would still provide a conduction path.

The external MOSFETs are selected as #strong[Infineon BSC026N08NS5]. This is an 80 V N-channel MOSFET with low on-resistance. Two devices are used in series, source-to-source, as required by the bidirectional protection topology.

The overcurrent threshold is set using a current-sense resistor. The selected part is #strong[Vishay WSL2512R0100FEA], a 10 mΩ, 1 W current-sense resistor in 2512 package. With the LTC4368 forward overcurrent threshold of approximately 50 mV, the approximate trip current is:

$
I_"OC" approx (50 "mV") / (10 "m" Omega) = 5 "A"
$

This value is a protection threshold, not the expected nominal operating current of the system.

After the protection stage, a conducted EMI filter is placed before the switching converter. The common-mode element is #strong[TDK ACM7060-301-2PL-TL01], selected because it is intended for power-line common-mode noise suppression, supports several amperes of DC current and has an 80 V voltage rating. This component attenuates high-frequency common-mode noise both entering from the external supply and generated by the internal buck converter.

The input capacitors provide local energy storage and differential-mode noise reduction. A practical implementation is:

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + navy,
    fill: pale-blue,
    radius: 5pt,
  )[
    #table(
      columns: (1.1fr, 2.1fr, 3fr),
      inset: 7pt,
      align: left,

      table.cell(fill: navy)[#text(fill: white, weight: "bold")[Component]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[Proposed value / part]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[Function]],

      [$C_"bulk"$],
      [Panasonic EEH-ZS1J101P, 100 µF, 63 V],
      [Low-ESR bulk reservoir. It supports input current transients and reduces low-frequency ripple at the buck input.],

      [$C_"mid"$],
      [TDK C3216X7R2A105K160AE, 1 µF, 100 V, X7R],
      [Medium-frequency decoupling close to the buck input and EMI filter output.],

      [$C_"hf"$],
      [100 nF, 100 V, X7R],
      [High-frequency bypass placed physically close to the buck converter input pins.],
    )
  ],
  caption: [Input capacitor configuration.],
)

The first DC/DC converter is #strong[Analog Devices LT8645S]. It is selected as the main input buck because it accepts high input voltage, provides enough current margin for the complete acquisition system and uses a low-EMI Silent Switcher architecture. Its output is set to approximately 7 V. This rail is not used directly by sensitive analog loads; it is only an intermediate bus from which the clean analog and digital rails are generated.

The buck inductor is selected as #strong[Coilcraft XAL7070-472MEC], a shielded 4.7 µH power inductor with high current rating and low DC resistance. The exact switching frequency, compensation network and output capacitance must be dimensioned using the LT8645S datasheet design equations, but this inductor is a suitable preliminary choice for a compact, low-loss 7 V intermediate converter.

#quote(block: true)[
The input stage provides a protected and regulated 7 V intermediate rail. This rail is intentionally not used as a final low-noise supply; it only feeds the downstream analog and digital regulators.
]

== Analog supply branch

The analog branch supplies the sensitive parts of the system:

- The bipolar supply of the AD8429 LNA or high-impedance buffer placed close to each MEMS output.
- The analog supply of the AD7606C-18 devices.
- The ADC reference and analog bias circuitry.

The AD8429 instrumentation amplifier requires bipolar analog supplies, specified for $plus.minus 4 V$ to $plus.minus 18 V$ operation. Therefore, the analog branch must generate both a positive and a negative analog rail.

The proposed rails are:

```text
7 V → low-noise LDO     → +5 V_A
7 V → inverting DC-DC   → −5 V_A
```

The positive $+5 V_A$ rail feeds both the AD8429 positive supply and the AD7606C-18 AVCC pin. The negative $-5 V_A$ rail is required only by the AD8429 LNAs and must not be connected to the AD7606C-18, which operates from a single positive supply.

#quote(block: true)[
  The AD7606C-18 does not require a negative supply rail. Its internal architecture includes high-impedance input buffers that handle bipolar input voltage ranges (up to $plus.minus 12.5 V$ single-ended or $plus.minus 20 V$ differential) using only a single $+5 V$ analog supply. The negative supply is needed exclusively for the external AD8429 LNA stage.
]

The $-5 V_A$ rail can be generated using a low-noise inverting DC-DC converter. A suitable candidate is the #strong[TPS63710] (Texas Instruments), which accepts a positive input in the 2.7 V to 5.5 V range and generates a regulated negative output. For higher input voltage compatibility, the #strong[LT3462] (Analog Devices) accepts inputs up to 16 V and provides a low-noise inverting output suitable for analog instrumentation.

Both the $+5 V_A$ and $-5 V_A$ rails must be kept separate from the digital supply. Even if the positive rail has the same nominal voltage as $5 V_D$, the analog branch must not share high-current digital return paths with the FPGA or communication interface.

Each zone should include local filtering:

```text
+5 V_A global → ferrite / RC filter → local +5 V_A_zone
−5 V_A global → ferrite / RC filter → local −5 V_A_zone
```

Local decoupling must be placed close to every AD7606C-18 and every LNA. The LNA supply is especially critical because it is physically close to the MEMS transducer and directly affects the input-referred noise of the acquisition chain. Each AD8429 must have local bypass capacitors on both the positive and negative supply pins.

== Digital supply branch

The digital branch supplies the digital interface of the ADCs, the FPGA I/O banks, and the auxiliary logic.

The proposed cascade is:

```text
7 V → 5 V_D → 3.3 V_D
```

The 3.3 $V_D$ rail supplies:

- AD7606C-18 VDRIVE.
- FPGA I/O banks connected to the ADCs.
- Low-speed control logic.

The FPGA core rails should not be generated using linear regulators from 7 V or 5 V due to excessive power dissipation. Instead, dedicated switching regulators should be used:

```text
5 V_D → buck → 1.0 V FPGA core
5 V_D → buck or LDO → 1.8 V FPGA auxiliary rail
```

== Rail summary

#figure(
  box(
    width: 100%,
    inset: 6pt,
    stroke: 0.7pt + navy,
    fill: pale-blue,
    radius: 5pt,
  )[
    #table(
      columns: (1.2fr, 2.2fr, 2.5fr),
      inset: 7pt,
      align: left,

      table.cell(fill: navy)[#text(fill: white, weight: "bold")[Rail]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[Main loads]],
      table.cell(fill: navy)[#text(fill: white, weight: "bold")[Design notes]],

      [7 V],
      [Intermediate bus],
      [Generated by the main buck converter from 24/28 V. Not used directly for sensitive circuitry.],

      [$+5 V_A$],
      [AD7606C-18 AVCC, AD8429 positive supply, analog bias],
      [Low-noise LDO from 7 V. Local filtering per zone. Separated from digital return currents.],

      [$-5 V_A$],
      [AD8429 negative supply],
      [Inverting DC-DC from 7 V. Required only by the bipolar LNA stage. Not connected to the AD7606C-18.],

      [$5 V_D$],
      [Digital pre-regulation rail],
      [Feeds $3.3 V_D$ and FPGA regulators. Can be generated with a switching regulator.],

      [$3.3 V_D$],
      [AD7606C-18 VDRIVE, FPGA I/O],
      [Must match the selected FPGA I/O voltage.],

      [1.8 V],
      [FPGA auxiliary supply, optional logic],
      [Generated according to FPGA requirements.],

      [1.0 V],
      [FPGA core],
      [Dedicated high-efficiency buck regulator.],
    )
  ],
  caption: [Summary of the proposed supply rails.],
)

== Distribution to the acquisition zones

The system is divided into ten identical acquisition zones. Each zone contains two AD7606C-18 devices: one for the LF outputs and one for the HF outputs. Therefore, the power distribution must be replicated carefully across the ten zones.

Per zone:

```text
+5 V_A_zone → 2 x AD7606C-18 AVCC + AD8429 positive supply
−5 V_A_zone → AD8429 negative supply (not connected to AD7606C-18)
 3.3 V_D_zone → 2 x AD7606C-18 VDRIVE + digital interface
 GND_A / GND_D → controlled return connection
```

The analog supplies should be filtered locally in each zone to prevent noise coupling between zones. Both the positive and negative analog rails require per-zone filtering. The digital supply can be distributed more globally, but it still requires local decoupling close to every ADC.

== Grounding and layout considerations

The PCB layout must prevent digital switching currents from flowing through the analog reference path. The recommended strategy is to use a solid ground plane with careful partitioning of current return paths, rather than isolated ground islands connected unpredictably.

Key layout rules:

- Place the LNA or buffer as close as possible to the MEMS output.
- Place decoupling capacitors close to every supply pin.
- Keep ADC reference routing short and shielded from digital lines.
- Separate fast FPGA/ADC digital buses from MEMS and LNA inputs.
- Route analog inputs symmetrically inside each zone.
- Avoid sharing narrow return paths between FPGA currents and analog front-end currents.

== Power sequencing and monitoring

The FPGA and ADCs require a defined power-up sequence. The power system should therefore include voltage supervision and reset generation.

Recommended signals:

```text
POWER_GOOD_5V_A
POWER_GOOD_NEG5V_A
POWER_GOOD_3V3_D
POWER_GOOD_FPGA
GLOBAL_RESET
```

The $-5 V_A$ rail should be supervised independently. The LNA stage must not be enabled until both $+5 V_A$ and $-5 V_A$ are within specification. Operating the AD8429 with an asymmetric supply during power-up transients could damage the device or produce incorrect output voltages that stress the AD7606C-18 inputs.

The FPGA should remain in reset until all required rails are stable. Optionally, the FPGA can monitor voltage and current sensors to detect failures in the acquisition zones.

== Preliminary design conclusion

#quote(block: true)[
The input stage provides a protected 7 V intermediate rail that acts as the common pre-regulation node. From this point, the analog and digital domains are regulated separately, allowing the sensitive MEMS front-end and AD7606C-18 devices to be isolated from FPGA and interface switching noise.
]

This architecture reduces dissipation, isolates the sensitive analog front-end from digital noise, and provides suitable supply rails for the AD7606C-18 devices, the MEMS-adjacent LNAs, and the FPGA acquisition system.
