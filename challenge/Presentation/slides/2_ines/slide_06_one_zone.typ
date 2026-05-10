#let theme_blue = rgb("#1f4f6b")
#let light_blue = theme_blue.transparentize(90%)
#let soft_blue = theme_blue.transparentize(86%)
#let orange = rgb("#B86B00")
#let soft_orange = orange.transparentize(88%)

== One acquisition zone

#grid(
  columns: (1.15fr, 0.85fr),
  gutter: 0.55cm,

  [
    #rect(
      width: 100%,
      height: 6.9cm,
      radius: 8pt,
      stroke: theme_blue + 1pt,
      fill: light_blue,
      inset: 0.28cm,
    )[
      #text(size: 18pt, weight: "bold", fill: theme_blue)[Zone structure]

      #v(0.22cm)

      #align(center)[
        #rect(
          width: 86%,
          height: 0.95cm,
          radius: 6pt,
          stroke: theme_blue + 0.9pt,
          fill: white,
          inset: 0.12cm,
        )[
          #align(center + horizon)[
            #text(size: 14.5pt, weight: "bold", fill: theme_blue)[8 dual-frequency MEMS microphones]
          ]
        ]

        #v(0.12cm)
        #text(size: 16pt, fill: theme_blue)[↓]
        #v(0.08cm)

        #grid(
          columns: (1fr, 1fr),
          gutter: 0.28cm,

          [
            #rect(
              width: 100%,
              height: 1.55cm,
              radius: 6pt,
              stroke: theme_blue + 0.9pt,
              fill: soft_blue,
              inset: 0.14cm,
            )[
              #align(center)[
                #text(size: 14.5pt, weight: "bold", fill: theme_blue)[8 LF outputs]
                #v(0.02cm)
                #text(size: 12pt)[low-frequency branch]
              ]
            ]
          ],

          [
            #rect(
              width: 100%,
              height: 1.55cm,
              radius: 6pt,
              stroke: orange + 0.9pt,
              fill: soft_orange,
              inset: 0.14cm,
            )[
              #align(center)[
                #text(size: 14.5pt, weight: "bold", fill: orange)[8 HF outputs]
                #v(0.02cm)
                #text(size: 12pt)[high-frequency branch]
              ]
            ]
          ],
        )

        #v(0.12cm)
        #text(size: 16pt, fill: theme_blue)[↓]
        #v(0.08cm)

        #grid(
          columns: (1fr, 1fr),
          gutter: 0.28cm,

          [
            #rect(
              width: 100%,
              height: 1.05cm,
              radius: 6pt,
              stroke: theme_blue + 0.9pt,
              fill: white,
              inset: 0.12cm,
            )[
              #align(center + horizon)[
                #text(size: 13.8pt, weight: "bold")[AD7606C-18 LF]
              ]
            ]
          ],

          [
            #rect(
              width: 100%,
              height: 1.05cm,
              radius: 6pt,
              stroke: orange + 0.9pt,
              fill: white,
              inset: 0.12cm,
            )[
              #align(center + horizon)[
                #text(size: 13.8pt, weight: "bold")[AD7606C-18 HF]
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
      height: 1.8cm,
      radius: 8pt,
      stroke: theme_blue + 1pt,
      fill: white,
      inset: 0.22cm,
    )[
      #align(center)[
        #text(size: 16pt, weight: "bold", fill: theme_blue)[Per zone]
        #v(0.04cm)
        #text(size: 14pt)[8 MEMS × 2 outputs]
        #v(0.02cm)
        #text(size: 16pt, weight: "bold")[16 analog channels]
      ]
    ]

    #v(0.22cm)

    #rect(
      width: 100%,
      height: 1.8cm,
      radius: 8pt,
      stroke: theme_blue + 1pt,
      fill: light_blue,
      inset: 0.22cm,
    )[
      #align(center)[
        #text(size: 16pt, weight: "bold", fill: theme_blue)[ADC allocation]
        #v(0.04cm)
        #text(size: 14pt)[1 ADC for LF]
        #v(0.02cm)
        #text(size: 14pt)[1 ADC for HF]
      ]
    ]

    #v(0.22cm)

    #rect(
      width: 100%,
      height: 1.8cm,
      radius: 8pt,
      stroke: theme_blue + 1pt,
      fill: white,
      inset: 0.22cm,
    )[
      #align(center)[
        #text(size: 16pt, weight: "bold", fill: theme_blue)[Full array]
        #v(0.04cm)
        #text(size: 14pt)[10 zones]
        #v(0.02cm)
        #text(size: 16pt, weight: "bold")[20 AD7606C-18]
      ]
    ]
  ],
)

#v(0.12cm)

#align(center)[
  #rect(
    width: 84%,
    height: 0.72cm,
    radius: 6pt,
    stroke: theme_blue + 0.9pt,
    fill: theme_blue.transparentize(88%),
    inset: 0.08cm,
  )[
    #align(center + horizon)[
      #text(size: 13.2pt, weight: "bold", fill: theme_blue)[Key idea:]
      #text(size: 13.2pt)[ one zone converts 16 MEMS outputs using two 8-channel ADCs.]
    ]
  ]
]