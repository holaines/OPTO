#let theme_blue = rgb("#1f4f6b")

== Digital acquisition

#grid(
  columns: (1fr, 1fr),
  gutter: 0.55cm,
  [
    #rect(
      width: 100%,
      radius: 8pt,
      stroke: theme_blue + 0.9pt,
      fill: none,
      inset: 0.22cm,
    )[
      #text(size: 16pt, weight: "bold", fill: theme_blue)[Controller and synchronization]
      #v(0.12cm)
      #text(size: 14pt)[#strong[Sequence:] Timer -> CONVST -> BUSY check -> readout -> frame + FIFO]
      #v(0.12cm)
      - #text(size: 14pt)[`IDLE -> START_CONVERSION -> WAIT_BUSY`]
      - #text(size: 14pt)[`READ_ADC -> BUILD_FRAME -> WRITE_FIFO`]
      - #text(size: 14pt)[The real sampling instant is fixed by #strong[CONVST].]
      - #text(size: 14pt)[Flags report late ADCs or FIFO saturation.]
    ]
  ],
  [
    #rect(
      width: 100%,
      radius: 8pt,
      stroke: theme_blue + 0.9pt,
      fill: theme_blue.transparentize(92%),
      inset: 0.22cm,
    )[
      #text(size: 16pt, weight: "bold", fill: theme_blue)[Timing and throughput]
      #v(0.12cm)
      #text(size: 14pt)[For one AD7606C-18:]
      #v(0.05cm)
      #text(size: 14pt)[$8 " channels" dot 18 " bits" = 144 " bits/frame"$]
      #v(0.10cm)
      #text(size: 14pt)[With #strong[2 DOUT] per ADC:]
      #v(0.05cm)
      #text(size: 14pt)[$144 / 2 = 72 " SCLK cycles"$]
      #v(0.10cm)
      #text(size: 14pt)[At `60 MHz`:]
      #v(0.05cm)
      #text(size: 14pt)[$t_"read" = 72 / (60 " MHz") = 1.2 mu s$]
      #v(0.12cm)
      - #text(size: 14pt)[HF: `250 kS/s` -> `T_s = 4 us`]
      - #text(size: 14pt)[LF: `50 kS/s` -> `T_s = 20 us`]
      - #text(size: 14pt, weight: "bold")[`1.2 us < 4 us`: the baseline is valid.]

      #v(0.10cm)
      #rect(
        width: 100%,
        radius: 6pt,
        stroke: theme_blue + 0.7pt,
        fill: theme_blue.transparentize(94%),
        inset: 0.14cm,
      )[
        #text(size: 12pt)[Throughput: `HF 480 Mbit/s + LF 96 Mbit/s = 576 Mbit/s`. Output through #strong[Ethernet].]
      ]
    ]
  ],
)
