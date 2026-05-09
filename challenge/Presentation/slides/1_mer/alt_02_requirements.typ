#let theme_blue = rgb("#1f4f6b")

== Main system requirements

#table(
  columns: (1fr, 1fr),
  inset: 8pt,
  stroke: 0.6pt + theme_blue,
  align: (left, left),
  table.header(
    table.cell(fill: theme_blue.transparentize(88%))[#text(size: 15pt, weight: "bold", fill: theme_blue)[Requirement]],
    table.cell(fill: theme_blue.transparentize(88%))[#text(size: 15pt, weight: "bold", fill: theme_blue)[Target]],
  ),
  [#text(size: 17pt)[MEMS microphones]], [#text(size: 17pt)[80]],
  [#text(size: 17pt)[Outputs per MEMS]], [#text(size: 17pt)[LF + HF]],
  [#text(size: 17pt)[Total analog signals]], [#text(size: 17pt)[160]],
  [#text(size: 17pt)[Frequency range]], [#text(size: 17pt)[100 Hz – 100 kHz]],
  [#text(size: 17pt)[Dynamic range]], [#text(size: 17pt)[30 dB SPL – 170 dB SPL]],
  [#text(size: 17pt)[Target SNR]], [#text(size: 17pt)[90 dB WTT / 70 dB FT]],
  [#text(size: 14pt)[Power supply]], [#text(size: 14pt)[28 V aircraft bus / 24 V battery]],
)

#v(0.1cm)

#align(center)[
  #block(width: 82%)[
    #grid(
      columns: (1fr, 1fr),
      gutter: 0.6cm,
      [
        #rect(
        width: 100%,
        height: 2.3cm,
        radius: 6pt,
        stroke: theme_blue + 1pt,
        fill: theme_blue.transparentize(88%),
        inset: 0.25cm,
      )[
        #align(center + horizon)[
          #text(size: 15pt, weight: "bold", fill: theme_blue)[80 MEMS × 2 outputs]
          #v(0.06cm)
          #text(size: 15pt, weight: "bold")[160 signals]
        ]
      ]
    ],
    [
      #rect(
        width: 100%,
        height: 2.3cm,
        radius: 6pt,
        stroke: theme_blue + 1pt,
        fill: none,
        inset: 0.25cm,
      )[
        #align(center + horizon)[
          #text(size: 15pt, weight: "bold", fill: theme_blue)[Most demanding case]
          #v(0.06cm)
          #text(size: 15pt)[WTT closed section · 100 Hz – 100 kHz]
        ]
      ]
      ],
    )
  ]
]