#let theme_blue = rgb("#1f4f6b")

== Proposed global architecture

#v(0.4cm)
#grid(
  columns: (1.45fr, 0.75fr),
  gutter: 0.7cm,
  [
    #align(center)[
      #image("../../figures/system_diagram.png", width: 90%)
    ]
  ],
  [
    #v(0.75cm)

    #rect(
      width: 100%,
      height: 1.45cm,
      radius: 6pt,
      stroke: theme_blue + 1pt,
      fill: theme_blue.transparentize(88%),
      inset: 0.2cm,
    )[
      #align(center + horizon)[
        #text(size: 16pt, weight: "bold", fill: theme_blue)[10 zones]
      ]
    ]

    #v(0.05cm)

    #rect(
      width: 100%,
      height: 1.45cm,
      radius: 6pt,
      stroke: theme_blue + 1pt,
      fill: none,
      inset: 0.2cm,
    )[
      #align(center + horizon)[
        #text(size: 16pt, weight: "bold", fill: theme_blue)[8 MEMS per zone]
      ]
    ]

    #v(0.05cm)

    #rect(
      width: 100%,
      height: 1.45cm,
      radius: 6pt,
      stroke: theme_blue + 1pt,
      fill: theme_blue.transparentize(88%),
      inset: 0.2cm,
    )[
      #align(center + horizon)[
        #text(size: 16pt, weight: "bold", fill: theme_blue)[2 ADCs per zone]
      ]
    ]
  ],
)

#v(0.15cm)

#align(center)[
  #text(size: 15pt)[
    Each acquisition zone separates the LF and HF outputs and sends the digitized data to the Artix-7 FPGA.
  ]
]
