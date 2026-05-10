#let theme_blue = rgb("#1f4f6b")
#let light_blue = theme_blue.transparentize(90%)
#let soft_blue = theme_blue.transparentize(86%)
#let green = rgb("#3A7D44")
#let soft_green = green.transparentize(88%)
#let orange = rgb("#B86B00")
#let soft_orange = orange.transparentize(88%)
#let red = rgb("#9B2C2C")
#let soft_red = red.transparentize(88%)

== Front-end and ADC compatibility

#grid(
  columns: (0.95fr, 1.05fr),
  gutter: 0.6cm,
  [
    #rect(
      width: 100%,
      height: 7.9cm,
      radius: 8pt,
      stroke: theme_blue + 1pt,
      fill: light_blue,
      inset: 0.32cm,
    )[
      #text(size: 20pt, weight: "bold", fill: theme_blue)[Analog front-end]

      #v(0.25cm)

      #align(center)[
        #rect(
          width: 82%,
          height: 0.9cm,
          radius: 5pt,
          stroke: theme_blue + 0.8pt,
          fill: white,
          inset: 0.1cm,
        )[
          #align(center + horizon)[#text(size: 13.5pt, weight: "bold")[MEMS LF/HF output]]
        ]

        #text(size: 13pt, fill: theme_blue)[↓]

        #rect(
          width: 82%,
          height: 0.9cm,
          radius: 5pt,
          stroke: green + 0.8pt,
          fill: soft_green,
          inset: 0.1cm,
        )[
          #align(center + horizon)[#text(size: 13.5pt, weight: "bold", fill: green)[High-impedance buffer / LNA]]
        ]

        #text(size: 13pt, fill: theme_blue)[↓]

        #rect(
          width: 82%,
          height: 0.9cm,
          radius: 5pt,
          stroke: orange + 0.8pt,
          fill: soft_orange,
          inset: 0.1cm,
        )[
          #align(center + horizon)[#text(size: 13.5pt, weight: "bold", fill: orange)[Gain or attenuation]]
        ]

        #text(size: 13pt, fill: theme_blue)[↓]

        #rect(
          width: 82%,
          height: 0.9cm,
          radius: 5pt,
          stroke: theme_blue + 0.8pt,
          fill: white,
          inset: 0.1cm,
        )[
          #align(center + horizon)[#text(size: 13.5pt, weight: "bold")[Protection + RC filter]]
        ]

        #text(size: 13pt, fill: theme_blue)[↓]

        #rect(
          width: 82%,
          height: 0.9cm,
          radius: 5pt,
          stroke: red + 0.8pt,
          fill: soft_red,
          inset: 0.1cm,
        )[
          #align(center + horizon)[#text(size: 13.5pt, weight: "bold", fill: red)[AD7606C-18 input]]
        ]
      ]

      #v(0.2cm)

      #text(size: 13.5pt)[The external front-end adapts the MEMS output before conversion.]
    ]
  ],
  [
    #rect(
      width: 100%,
      height: 2.25cm,
      radius: 8pt,
      stroke: theme_blue + 1pt,
      fill: white,
      inset: 0.25cm,
    )[
      #text(size: 18pt, weight: "bold", fill: theme_blue)[Why gain/attenuation?]

      #v(0.12cm)

      #text(size: 14.5pt)[Low SPL signals are very small, while high SPL signals can exceed the ADC input range.]
    ]

    #v(0.28cm)

    #rect(
      width: 100%,
      height: 2.7cm,
      radius: 8pt,
      stroke: orange + 1pt,
      fill: soft_orange,
      inset: 0.25cm,
    )[
      #text(size: 18pt, weight: "bold", fill: orange)[Input range rule]

      #v(0.2cm)

      #align(center)[
        #text(size: 17pt)[$abs(V_"ADC,in") <= V_"ADC,FS"$]
      ]

      #v(0.15cm)

      #text(size: 14pt)[For a ±10 V ADC range, the conditioned signal must stay between −10 V and +10 V.]
    ]

    #v(0.28cm)

    #rect(
      width: 100%,
      height: 2.7cm,
      radius: 8pt,
      stroke: green + 1pt,
      fill: soft_green,
      inset: 0.25cm,
    )[
      #text(size: 18pt, weight: "bold", fill: green)[Sampling compatibility]

      #v(0.12cm)

      #text(size: 14.5pt)[LF branch: 50–100 kS/s for signals up to 10 kHz.]

      #v(0.08cm)

      #text(size: 14.5pt)[HF branch: 500 kS/s–1 MS/s for signals up to 100 kHz.]
    ]
  ],
)

#v(0.15cm)

#align(center)[
  #rect(
    width: 88%,
    radius: 6pt,
    stroke: theme_blue + 0.9pt,
    fill: theme_blue.transparentize(88%),
    inset: 0.18cm,
  )[
    #align(center)[
      #text(size: 14.5pt, weight: "bold", fill: theme_blue)[Final message:]
      #text(size: 14.5pt)[ the AD7606C-18 solves the channel-count problem, but the analog front-end is still necessary for impedance, dynamic range and protection.]
    ]
  ]
]