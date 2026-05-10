#let theme_blue = rgb("#1f4f6b")
#let light_blue = theme_blue.transparentize(91%)
#let soft_blue = theme_blue.transparentize(86%)
#let green = rgb("#3A7D44")
#let soft_green = green.transparentize(88%)
#let orange = rgb("#B86B00")
#let soft_orange = orange.transparentize(88%)

== AD7606C-18 selection

#grid(
  columns: (1fr, 1fr),
  gutter: 0.55cm,

  [
    #rect(
      width: 100%,
      height: 7.25cm,
      radius: 7pt,
      stroke: theme_blue + 1pt,
      fill: light_blue,
      inset: 0.28cm,
    )[
      #text(size: 18pt, weight: "bold", fill: theme_blue)[Why this ADC?]

      #v(0.18cm)

      #text(size: 13.7pt)[
        The AD7606C-18 is used as an integrated acquisition block for each LF or HF group of one zone.
      ]

      #v(0.24cm)

      #grid(
        columns: (1fr, 1fr),
        gutter: 0.22cm,

        [
          #rect(
            width: 100%,
            height: 1.05cm,
            radius: 5pt,
            stroke: theme_blue + 0.8pt,
            fill: white,
            inset: 0.1cm,
          )[#align(center + horizon)[#text(size: 13.2pt, weight: "bold")[8 analog inputs]]]

          #v(0.16cm)

          #rect(
            width: 100%,
            height: 1.05cm,
            radius: 5pt,
            stroke: theme_blue + 0.8pt,
            fill: white,
            inset: 0.1cm,
          )[#align(center + horizon)[#text(size: 13.2pt, weight: "bold")[18-bit SAR ADC]]]

          #v(0.16cm)

          #rect(
            width: 100%,
            height: 1.05cm,
            radius: 5pt,
            stroke: theme_blue + 0.8pt,
            fill: white,
            inset: 0.1cm,
          )[#align(center + horizon)[#text(size: 13.2pt, weight: "bold")[Programmable ranges]]]
        ],

        [
          #rect(
            width: 100%,
            height: 1.05cm,
            radius: 5pt,
            stroke: green + 0.8pt,
            fill: soft_green,
            inset: 0.1cm,
          )[#align(center + horizon)[#text(size: 13.2pt, weight: "bold", fill: green)[Simultaneous sampling]]]

          #v(0.16cm)

          #rect(
            width: 100%,
            height: 1.05cm,
            radius: 5pt,
            stroke: green + 0.8pt,
            fill: soft_green,
            inset: 0.1cm,
          )[#align(center + horizon)[#text(size: 13.2pt, weight: "bold", fill: green)[PGA + low-pass filter]]]

          #v(0.16cm)

          #rect(
            width: 100%,
            height: 1.05cm,
            radius: 5pt,
            stroke: green + 0.8pt,
            fill: soft_green,
            inset: 0.1cm,
          )[#align(center + horizon)[#text(size: 13.2pt, weight: "bold", fill: green)[Digital interface]]]
        ],
      )

      #v(0.25cm)

      #rect(
        width: 100%,
        height: 0.95cm,
        radius: 5pt,
        stroke: theme_blue + 0.8pt,
        fill: white,
        inset: 0.12cm,
      )[
        #align(center + horizon)[
          #text(size: 12pt)[One device acquires all 8 LF or all 8 HF outputs of one zone.]
        ]
      ]
    ]
  ],

  [
    #rect(
      width: 100%,
      height: 2.35cm,
      radius: 7pt,
      stroke: orange + 1pt,
      fill: soft_orange,
      inset: 0.25cm,
    )[
      #text(size: 18pt, weight: "bold", fill: orange)[MUX removal]

      #v(-0.5cm)

      #text(size: 13pt)[
        The external 8:1 analog multiplexer is removed because each ADC already samples 8 channels simultaneously.
      ]
    ]

    #v(0.35cm)

    #rect(
      width: 100%,
      height: 4.55cm,
      radius: 7pt,
      stroke: theme_blue + 1pt,
      fill: white,
      inset: 0.28cm,
    )[
      #text(size: 18pt, weight: "bold", fill: theme_blue)[Channel count]

      #v(0.35cm)

      #align(center)[
        #text(size: 16pt)[$10 " zones" dot 2 " ADCs/zone" = 20 " ADCs"$]

        #v(0.3cm)

        #text(size: 16pt)[$20 " ADCs" dot 8 " channels" = 160 " channels"$]
      ]

      #v(0.4cm)

      #rect(
        width: 100%,
        height: 0.95cm,
        radius: 5pt,
        stroke: theme_blue + 0.8pt,
        fill: light_blue,
        inset: 0.12cm,
      )[
        #align(center + horizon)[
          #text(size: 10pt, weight: "bold", fill: theme_blue)[The ADC count exactly matches the 160 MEMS analog outputs.]
        ]
      ]
    ]
  ],
)

#v(0.80cm)

#align(center)[
  #text(size: 13.5pt)[The AD7606C-18 simplifies acquisition while preserving channel-to-channel timing.]
]