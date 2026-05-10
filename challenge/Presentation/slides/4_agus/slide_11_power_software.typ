== Power supply

#figure(
  align(center)[
    #scale(90%, reflow: true)[
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
              column-gutter: 1pt,
              align: center,

              [
                #box(inset: 6pt, stroke: 0.7pt, radius: 4pt, fill: blue.lighten(75%))[
                  #strong[Analog branch] \
                  7 V $arrow.r$ low-noise LDO $arrow.r$ $5 V_A$ \
                  #smallcaps[AD7606C-18] AVCC \
                  MEMS LNA / buffer \
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
    ]
  ]
)

== Software

// ── colour palette ──
#let fpga-fill = rgb("#d6e8f0")
#let pc-fill   = blue.lighten(78%)
#let out-fill  = rgb("#e3f0d8")
#let ctrl-fill = rgb("#fff4d6")

// ── compact block helpers ──
#let bk(title, body, fill: pc-fill, w: 2.7cm) = box(
  width: w, inset: 5pt, stroke: 0.55pt, radius: 3pt, fill: fill,
)[
  #align(center + horizon)[
    #text(size: 8pt, weight: "bold")[#title] \
    #v(1pt)
    #text(size: 6.5pt)[#body]
  ]
]

#let harr(label: none) = box(width: 0.85cm, height: 0.6cm)[
  #align(center + horizon)[
    #if label != none [
      #stack(dir: ttb, spacing: 0pt,
        text(size: 5.5pt)[#label],
        text(size: 11pt)[→],
      )
    ] else [
      #text(size: 11pt)[→]
    ]
  ]
]

#let varr = box(width: 2.7cm, height: 0.45cm)[
  #align(center + horizon)[#text(size: 11pt)[↓]]
]

#figure(
  align(center)[
    #scale(155%, reflow: true)[
      #grid(
        columns: (2.7cm, 0.85cm, 2.7cm, 0.85cm, 2.7cm, 0.85cm, 2.7cm, 0.85cm, 2.7cm),
        rows: (auto, 0.45cm, auto),
        column-gutter: 0pt,
        row-gutter: 0pt,
        align: center + horizon,

        // ── Row 1: reception pipeline ──
        bk([FPGA stream], [160 ch × 18 bit\ framed data], fill: fpga-fill),
        harr(label: [2.5G ETH]),
        bk([Packet receiver], [UDP socket\ packet buffering]),
        harr(),
        bk([Frame parser], [sync word\ header decoding\ payload extract.]),
        harr(),
        bk([Integrity check], [CRC-32\ frame counter\ status flags]),
        harr(),
        bk([Channel mapper], [LF / HF branch\ zone · sensor idx]),

        // ── Row 2: arrows down ──
        [], [], [], [], [], [], [], [],
        varr,

        // ── Row 3: outputs ──
        bk([Configuration], [start / stop\ sampling rates\ metadata], fill: ctrl-fill),
        harr(),
        bk([Status monitor], [data rate\ FIFO level\ error counters], fill: ctrl-fill),
        [],
        bk([Visualization], [time signals\ spectra\ status display], fill: out-fill),
        box(width: 0.85cm, height: 0.6cm)[
          #align(center + horizon)[#text(size: 11pt)[←]]
        ],
        bk([HDF5 storage], [LF / HF raw arrays\ timestamps\ calibration], fill: out-fill),
        box(width: 0.85cm, height: 0.6cm)[
          #align(center + horizon)[#text(size: 11pt)[←]]
        ],
        bk([Acquisition buf.], [time-aligned ring\ LF + HF samples]),
      )
    ]
  ],
)

