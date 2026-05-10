#let theme_blue = rgb("#1f4f6b")
#let light_blue = theme_blue.transparentize(90%)
#let soft_blue = theme_blue.transparentize(86%)
#let green = rgb("#3A7D44")
#let soft_green = green.transparentize(88%)
#let orange = rgb("#B86B00")
#let soft_orange = orange.transparentize(88%)

== AD7606C-18 selection

#grid(
  columns: (1fr, 1fr),
  gutter: 0.65cm,
  [
    #rect(
      width: 100%,
      height: 7.6cm,
      radius: 8pt,
      stroke: theme_blue + 1pt,
      fill: light_blue,
      inset: 0.35cm,
    )[
      #text(size: 20pt, weight: "bold", fill: theme_blue)[Why this ADC?]

      #v(0.25cm)

      #text(size: 15pt)[The AD7606C-18 is used as an integrated acquisition block because it includes:]

      #v(0.25cm)

      #grid(
        columns: (1fr, 1fr),
        gutter: 0.25cm,
        [
          #rect(
            width: 100%,
            height: 1.25cm,
            radius: 6pt,
            stroke: theme_blue + 0.8pt,
            fill: white,
            inset: 0.12cm,
          )[
            #align(center + horizon)[#text(size: 14pt, weight: "bold")[8 input channels]]
          ]

          #v(0.18cm)

          #rect(
            width: 100%,
            height: 1.25cm,
            radius: 6pt,
            stroke: theme_blue + 0.8pt,
            fill: white,
            inset: 0.12cm,
          )[
            #align(center + horizon)[#text(size: 14pt, weight: "bold")[18-bit SAR ADC]]
          ]

          #v(0.18cm)

          #rect(
            width: 100%,
            height: 1.25cm,
            radius: 6pt,
            stroke: theme_blue + 0.8pt,
            fill: white,
            inset: 0.12cm,
          )[
            #align(center + horizon)[#text(size: 14pt, weight: "bold")[Programmable ranges]]
          ]
        ],
        [
          #rect(
            width: 100%,
            height: 1.25cm,
            radius: 6pt,
            stroke: green + 0.8pt,
            fill: soft_green,
            inset: 0.12cm,
          )[
            #align(center + horizon)[#text(size: 14pt, weight: "bold", fill: green)[Simultaneous sampling]]
          ]

          #v(0.18cm)

          #rect(
            width: 100%,
            height: 1.25cm,
            radius: 6pt,
            stroke: green + 0.8pt,
            fill: soft_green,
            inset: 0.12cm,
          )[
            #align(center + horizon)[#text(size: 14pt, weight: "bold", fill: green)[Internal PGA + LPF]]
          ]

          #v(0.18cm)

          #rect(
            width: 100%,
            height: 1.25cm,
            radius: 6pt,
            stroke: green + 0.8pt,
            fill: soft_green,
            inset: 0.12cm,
          )[
            #align(center + horizon)[#text(size: 14pt, weight: "bold", fill: green)[Digital interface]]
          ]
        ],
      )

      #v(0.28cm)

      #rect(
        width: 100%,
        radius: 6pt,
        stroke: theme_blue + 0.8pt,
        fill: white,
        inset: 0.18cm,
      )[
        #text(size: 14.5pt)[
          One device can acquire the 8 LF or 8 HF outputs of one zone.
        ]
      ]
    ]
  ],
  [
    #rect(
      width: 100%,
      height: 3.1cm,
      radius: 8pt,
      stroke: orange + 1pt,
      fill: soft_orange,
      inset: 0.3cm,
    )[
      #text(size: 19pt, weight: "bold", fill: orange)[MUX removal]

      #v(0.15cm)

      #text(size: 15pt)[The external 8:1 analog multiplexer is not needed, because each AD7606C-18 already has 8 simultaneous ADC channels.]
    ]

    #v(0.35cm)

    #rect(
      width: 100%,
      height: 4.15cm,
      radius: 8pt,
      stroke: theme_blue + 1pt,
      fill: white,
      inset: 0.3cm,
    )[
      #text(size: 19pt, weight: "bold", fill: theme_blue)[Channel count]

      #v(0.25cm)

      #align(center)[
        #text(size: 17pt)[$10 " zones" dot 2 " ADCs/zone" = 20 " ADCs"$]

        #v(0.28cm)

        #text(size: 17pt)[$20 " ADCs" dot 8 " channels" = 160 " channels"$]
      ]

      #v(0.25cm)

      #rect(
        width: 100%,
        radius: 6pt,
        stroke: theme_blue + 0.8pt,
        fill: light_blue,
        inset: 0.16cm,
      )[
        #align(center)[
          #text(size: 14.5pt, weight: "bold", fill: theme_blue)[The ADC count exactly matches the 160 analog MEMS outputs.]
        ]
      ]
    ]
  ],
)

#v(0.15cm)

#align(center)[
  #text(size: 14.5pt)[The selected ADC simplifies the acquisition stage while preserving channel-to-channel timing.]
]