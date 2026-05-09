#let theme_blue = rgb("#1f4f6b")

== FPGA

#grid(
  columns: (1fr, 1fr),
  gutter: 0.55cm,
  [
    #rect(
      width: 100%,
      radius: 8pt,
      stroke: theme_blue + 0.9pt,
      fill: theme_blue.transparentize(92%),
      inset: 0.22cm,
    )[
      #text(size: 16pt, weight: "bold", fill: theme_blue)[Role of the FPGA]
      #v(0.0cm)
      - #text(size: 15pt)[The chain is #strong[80 MEMS -> 160 outputs -> 20 ADCs -> 1 FPGA].]
      - #text(size: 15pt)[The FPGA guarantees #strong[synchronized acquisition] for the whole array.]
      - #text(size: 15pt)[It generates the common timing and reads all ADCs in #strong[parallel].]
      - #text(size: 15pt)[It concentrates the data into one ordered stream for the PC.]

      #v(0.00cm)
      #rect(
        width: 100%,
        radius: 6pt,
        stroke: theme_blue + 0.7pt,
        fill: white,
        inset: 0.14cm,
      )[
        #text(size: 14pt)[#strong[Key numbers:] 80 MEMS | 160 channels | 20 AD7606C-18 | 1 Artix-7]
      ]
    ]
  ],
  [
    #rect(
      width: 100%,
      radius: 8pt,
      stroke: theme_blue + 0.9pt,
      fill: none,
      inset: 0.22cm,
    )[
      #align(center)[#text(size: 16pt, weight: "bold", fill: theme_blue)[Acquisition hierarchy]]
      #v(0.14cm)
      #align(center)[
        #text(size: 15pt, weight: "bold")[10 zones]
      #v(-0.04cm)
        #text(size: 14pt, fill: theme_blue)[↓]
        #v(0.02cm)
        #text(size: 15pt)[8 MEMS per zone]
        #v(0.02cm)
        #text(size: 14pt, fill: theme_blue)[↓]
        #v(0.02cm)
        #text(size: 15pt)[LF ADC + HF ADC per zone]
        #v(0.02cm)
        #text(size: 14pt, fill: theme_blue)[↓]
        #v(0.02cm)
        #text(size: 15pt, weight: "bold")[20 ADCs -> Artix-7 FPGA]
      ]
      #v(0.10cm)
      #align(center)[
        #rect(
          width: 78%,
          radius: 6pt,
          stroke: theme_blue + 0.8pt,
          fill: white,
          inset: 0.13cm,
        )[
          #text(size: 14pt)[Baseline: #strong[2 DOUT/ADC]]
          #linebreak()
          #text(size: 13pt)[Best trade-off between timing margin and FPGA I/O budget]
        ]
      ]
    ]
  ],
)
