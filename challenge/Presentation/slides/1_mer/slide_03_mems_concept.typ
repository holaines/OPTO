#let theme_blue = rgb("#1f4f6b")

== Dual-frequency MEMS concept

#v(0.35cm)

#grid(
  columns: (1fr, 1fr),
  gutter: 0.7cm,
  [
    #rect(
      width: 100%,
      height: 7cm,
      radius: 6pt,
      stroke: theme_blue + 1pt,
      fill: theme_blue.transparentize(90%),
      inset: 0.4cm,
    )[
      #text(size: 22pt, weight: "bold", fill: theme_blue)[Sensor output]

      #v(0.25cm)

      #text(size: 19pt)[
        Each MEMS microphone provides two independent AC-coupled outputs:
      ]

      #v(0.25cm)

      #text(size: 19pt)[• LF output: low-frequency band]
      #linebreak()
      #text(size: 19pt)[• HF output: high-frequency band]
    ]
  ],
  [
    #rect(
      width: 100%,
      height: 7cm,
      radius: 6pt,
      stroke: theme_blue + 1pt,
      fill: none,
      inset: 0.4cm,
    )[
      #text(size: 22pt, weight: "bold", fill: theme_blue)[Main values]

      #v(0.25cm)

      #table(
        columns: (1fr, 1fr),
        inset: 6pt,
        stroke: 0.5pt + theme_blue,
        align: (left, left),
        table.header(
          table.cell(fill: theme_blue.transparentize(88%))[#text(size: 19pt, weight: "bold", fill: theme_blue)[Output]],
          table.cell(fill: theme_blue.transparentize(88%))[#text(size: 19pt, weight: "bold", fill: theme_blue)[Sensitivity]],
        ),
        [#text(size: 19pt)[LF]], [#text(size: 19pt)[10 mV/Pa]],
        [#text(size: 19pt)[HF]], [#text(size: 19pt)[5 mV/Pa]],
      )

      #v(0.3cm)

      #text(size: 19pt)[Target bandwidth: 100 Hz – 100 kHz]
    ]
  ],
)

#v(0.35cm)

#align(center)[
  #rect(
    width: 80%,
    height: 1.5cm,
    radius: 6pt,
    stroke: theme_blue + 1pt,
    fill: theme_blue.transparentize(88%),
    inset: 0.25cm,
  )[
    #align(center + horizon)[
      #text(size: 19pt, weight: "bold", fill: theme_blue)[80 MEMS x 2 outputs = 160 analog channels]
    ]
  ]
]