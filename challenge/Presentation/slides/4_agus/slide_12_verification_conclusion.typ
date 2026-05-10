#let theme_blue = rgb("#1f4f6b")

== Verification and Conclusion
=== #text(fill: theme_blue)[Design verification]

#v(0.15cm)

#table(
  columns: (0.9fr, 1.8fr, 1.3fr),
  inset: 7pt,
  stroke: 0.6pt + theme_blue,
  align: (left, left, left),
  table.header(
    table.cell(fill: theme_blue.transparentize(88%))[#text(size: 13pt, weight: "bold", fill: theme_blue)[Check level]],
    table.cell(fill: theme_blue.transparentize(88%))[#text(size: 13pt, weight: "bold", fill: theme_blue)[Analysis]],
    table.cell(fill: theme_blue.transparentize(88%))[#text(size: 13pt, weight: "bold", fill: theme_blue)[Result]],
  ),
  [#text(size: 13pt, weight: "bold")[Throughput]],
  [#text(size: 13pt)[
    Packed data rate: 786 Mbit/s \
    +25 % overhead → ~983 Mbit/s \
    1G Ethernet insufficient
  ]],
  [#text(size: 13pt, fill: rgb("#2e7d32"), weight: "bold")[2.5G ETH ✓ \ margin available]],

  [#text(size: 13pt, weight: "bold")[Timing]],
  [#text(size: 13pt)[
    4-DOUT readout: 36 SCLK cycles \
    $t_"read"$ = 0.6 µs @ 60 MHz \
    $T_"s,HF"$ = 3.9 µs
  ]],
  [#text(size: 13pt, fill: rgb("#2e7d32"), weight: "bold")[0.6 µs ≪ 3.9 µs ✓]],

  [#text(size: 13pt, weight: "bold")[Data integrity]],
  [#text(size: 13pt)[
    Frame counter → lost frames \
    CRC-32 → corruption \
    FPGA status flags → anomalies
  ]],
  [#text(size: 13pt, fill: rgb("#2e7d32"), weight: "bold")[End-to-end \ verification ✓]],
)

#v(0.25cm)

=== #text(fill: theme_blue)[Key design points]

#v(1.3cm)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 0.5cm,
  row-gutter: 0.35cm,

  rect(
    width: 100%, radius: 5pt,
    stroke: 0.8pt + theme_blue,
    fill: theme_blue.transparentize(92%),
    inset: 8pt,
  )[
    #align(center + horizon)[
      #text(size: 13pt, weight: "bold", fill: theme_blue)[160 ch simultaneous] \
      #text(size: 11pt)[Common temporal reference]
    ]
  ],
  rect(
    width: 100%, radius: 5pt,
    stroke: 0.8pt + theme_blue,
    fill: theme_blue.transparentize(92%),
    inset: 8pt,
  )[
    #align(center + horizon)[
      #text(size: 13pt, weight: "bold", fill: theme_blue)[Analog / digital isolation] \
      #text(size: 11pt)[Separate power and data domains]
    ]
  ],

  rect(
    width: 100%, radius: 5pt,
    stroke: 0.8pt + theme_blue,
    fill: theme_blue.transparentize(92%),
    inset: 8pt,
  )[
    #align(center + horizon)[
      #text(size: 13pt, weight: "bold", fill: theme_blue)[Artix-7 FPGA] \
      #text(size: 11pt)[Deterministic sync & throughput]
    ]
  ],
  rect(
    width: 100%, radius: 5pt,
    stroke: 0.8pt + theme_blue,
    fill: theme_blue.transparentize(92%),
    inset: 8pt,
  )[
    #align(center + horizon)[
      #text(size: 13pt, weight: "bold", fill: theme_blue)[2.5G ETH + M12 connector] \
      #text(size: 11pt)[Industrial robustness]
    ]
  ],

  grid.cell(colspan: 2)[
    #rect(
      width: 100%, radius: 5pt,
      stroke: 0.8pt + theme_blue,
      fill: theme_blue.transparentize(92%),
      inset: 8pt,
    )[
      #align(center + horizon)[
        #text(size: 13pt, weight: "bold", fill: theme_blue)[PC software with per-frame integrity] \
        #text(size: 11pt)[CRC-32 verification · HDF5 storage with full metadata for reproducibility]
      ]
    ]
  ],
)
