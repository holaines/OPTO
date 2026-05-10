#let theme_blue = rgb("#1f4f6b")
#let light_blue = theme_blue.transparentize(91%)
#let soft_blue = theme_blue.transparentize(86%)
#let orange = rgb("#B86B00")
#let soft_orange = orange.transparentize(88%)

== One acquisition zone

#v(0.4cm)

#grid(
  columns: (1.2fr, 0.8fr),
  column-gutter: 0.6cm,

  // --- COLUMNA IZQUIERDA: ESTRUCTURA ---
  rect(
    width: 100%,
    radius: 8pt,
    stroke: theme_blue + 1pt,
    fill: light_blue,
    inset: 0.3cm,
  )[
    #text(size: 18pt, weight: "bold", fill: theme_blue)[Zone structure]
    #v(0.3cm)

    #align(center)[
      #rect(
        width: 95%,
        radius: 6pt,
        stroke: theme_blue + 0.8pt,
        fill: white,
        inset: 0.2cm,
      )[
        #text(size: 14pt, weight: "bold", fill: theme_blue)[8 dual-frequency MEMS microphones]
      ]

      #v(0.1cm)
      #text(size: 15pt, fill: theme_blue)[$arrow.b$]
      #v(0.1cm)

      #grid(
        columns: (1fr, 1fr),
        gutter: 0.3cm,
        rect(
          width: 100%,
          radius: 6pt,
          stroke: theme_blue + 0.8pt,
          fill: soft_blue,
          inset: 0.2cm,
        )[
          #text(size: 13pt, weight: "bold", fill: theme_blue)[8 LF outputs] \
          #text(size: 10pt)[low-frequency branch]
        ],
        rect(
          width: 100%,
          radius: 6pt,
          stroke: orange + 0.8pt,
          fill: soft_orange,
          inset: 0.2cm,
        )[
          #text(size: 13pt, weight: "bold", fill: orange)[8 HF outputs] \
          #text(size: 10pt)[high-frequency branch]
        ],
      )

      #v(0.1cm)
      #text(size: 15pt, fill: theme_blue)[$arrow.b$]
      #v(0.1cm)

      #grid(
        columns: (1fr, 1fr),
        gutter: 0.3cm,
        rect(
          width: 100%,
          radius: 6pt,
          stroke: theme_blue + 0.8pt,
          fill: white,
          inset: 0.2cm,
        )[
          #text(size: 12pt, weight: "bold")[AD7606C-18 LF]
        ],
        rect(
          width: 100%,
          radius: 6pt,
          stroke: orange + 0.8pt,
          fill: white,
          inset: 0.2cm,
        )[
          #text(size: 12pt, weight: "bold")[AD7606C-18 HF]
        ],
      )
    ]
  ],

  // --- COLUMNA DERECHA: DATOS ---
  stack(
    spacing: 0.35cm,
    rect(
      width: 100%,
      radius: 8pt,
      stroke: theme_blue + 1pt,
      fill: white,
      inset: 0.3cm,
    )[
      #align(center)[
        #text(size: 14pt, weight: "bold", fill: theme_blue)[Per zone] \
        #text(size: 11pt)[8 MEMS $times$ 2 outputs] \
        #text(size: 13pt, weight: "bold")[16 analog channels]
      ]
    ],
    rect(
      width: 100%,
      radius: 8pt,
      stroke: theme_blue + 1pt,
      fill: light_blue,
      inset: 0.3cm,
    )[
      #align(center)[
        #text(size: 14pt, weight: "bold", fill: theme_blue)[ADC allocation] \
        #text(size: 11pt)[1 ADC for LF] \
        #text(size: 11pt)[1 ADC for HF]
      ]
    ],
    rect(
      width: 100%,
      radius: 8pt,
      stroke: theme_blue + 1pt,
      fill: white,
      inset: 0.3cm,
    )[
      #align(center)[
        #text(size: 14pt, weight: "bold", fill: theme_blue)[Full array] \
        #text(size: 11pt)[10 zones] \
        #text(size: 13pt, weight: "bold")[20 AD7606C-18]
      ]
      #text(size: 13pt, weight: "bold", fill: orange)[Key idea:]
    #text(size: 13pt)[ One zone converts 16 MEMS outputs using two 8-channel ADCs.]
    ]
    
  )
)

#v(0.5cm)

