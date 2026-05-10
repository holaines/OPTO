#let theme_blue = rgb("#1f4f6b")
#let light_blue = theme_blue.transparentize(90%)
#let soft_blue = theme_blue.transparentize(86%)
#let orange = rgb("#B86B00")
#let soft_orange = orange.transparentize(88%)

== One acquisition zone

#grid(
  columns: (1.15fr, 0.85fr),
  gutter: 0.65cm,
  [
    #rect(
      width: 100%,
      height: 7.8cm,
      radius: 8pt,
      stroke: theme_blue + 1pt,
      fill: light_blue,
      inset: 0.35cm,
    )[
      #text(size: 20pt, weight: "bold", fill: theme_blue)[Zone structure]

      #v(0.35cm)

      #align(center)[
        #rect(
          width: 88%,
          height: 1.1cm,
          radius: 6pt,
          stroke: theme_blue + 0.9pt,
          fill: white,
          inset: 0.16cm,
        )[
          #align(center + horizon)[
            #text(size: 16pt, weight: "bold", fill: theme_blue)[8 dual-frequency MEMS microphones]
          ]
        ]

        #v(0.18cm)
        #text(size: 18pt, fill: theme_blue)[↓]

        #grid(
          columns: (1fr, 1fr),
          gutter: 0.35cm,
          [
            #rect(
              width: 100%,
              height: 2.25cm,
              radius: 6pt,
              stroke: theme_blue + 0.9pt,
              fill: soft_blue,
              inset: 0.2cm,
            )[
              #align(center + horizon)[
                #text(size: 16pt, weight: "bold", fill: theme_blue)[8 LF outputs]
                #linebreak()
                #text(size: 13.5pt)[low-frequency branch]
              ]
            ]
          ],
          [
            #rect(
              width: 100%,
              height: 2.25cm,
              radius: 6pt,
              stroke: orange + 0.9pt,
              fill: soft_orange,
              inset: 0.2cm,
            )[
              #align(center + horizon)[
                #text(size: 16pt, weight: "bold", fill: orange)[8 HF outputs]
                #linebreak()
                #text(size: 13.5pt)[high-frequency branch]
              ]
            ]
          ],
        )

        #v(0.18cm)
        #text(size: 18pt, fill: theme_blue)[↓]

        #grid(
          columns: (1fr, 1fr),
          gutter: 0.35cm,
          [
            #rect(
              width: 100%,
              height: 1.5cm,
              radius: 6pt,
              stroke: theme_blue + 0.9pt,
              fill: white,
              inset: 0.18cm,
            )[
              #align(center + horizon)[
                #text(size: 15pt, weight: "bold")[AD7606C-18 LF]
              ]
            ]
          ],
          [
            #rect(
              width: 100%,
              height: 1.5cm,
              radius: 6pt,
              stroke: orange + 0.9pt,
              fill: white,
              inset: 0.18cm,
            )[
              #align(center + horizon)[
                #text(size: 15pt, weight: "bold")[AD7606C-18 HF]
              ]
            ]
          ],
        )
      ]
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
      #align(center + horizon)[
        #text(size: 17pt, weight: "bold", fill: theme_blue)[Per zone]
        #linebreak()
        #text(size: 16pt)[8 MEMS × 2 outputs]
        #linebreak()
        #text(size: 18pt, weight: "bold")[16 analog channels]
      ]
    ]

    #v(0.28cm)

    #rect(
      width: 100%,
      height: 2.25cm,
      radius: 8pt,
      stroke: theme_blue + 1pt,
      fill: light_blue,
      inset: 0.25cm,
    )[
      #align(center + horizon)[
        #text(size: 17pt, weight: "bold", fill: theme_blue)[ADC allocation]
        #linebreak()
        #text(size: 16pt)[1 ADC for LF]
        #linebreak()
        #text(size: 16pt)[1 ADC for HF]
      ]
    ]

    #v(0.28cm)

    #rect(
      width: 100%,
      height: 2.25cm,
      radius: 8pt,
      stroke: theme_blue + 1pt,
      fill: white,
      inset: 0.25cm,
    )[
      #align(center + horizon)[
        #text(size: 17pt, weight: "bold", fill: theme_blue)[Full array]
        #linebreak()
        #text(size: 16pt)[10 zones]
        #linebreak()
        #text(size: 18pt, weight: "bold")[20 AD7606C-18]
      ]
    ]
  ],
)

#v(0.18cm)

#align(center)[
  #rect(
    width: 88%,
    radius: 6pt,
    stroke: theme_blue + 0.9pt,
    fill: theme_blue.transparentize(88%),
    inset: 0.18cm,
  )[
    #align(center)[
      #text(size: 15pt, weight: "bold", fill: theme_blue)[Key idea:]
      #text(size: 15pt)[ one zone converts 16 MEMS outputs using two 8-channel ADCs.]
    ]
  ]
]