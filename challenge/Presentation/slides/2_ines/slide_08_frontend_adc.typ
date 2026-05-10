#let theme_blue = rgb("#1f4f6b")
#let light_blue = theme_blue.transparentize(91%)
#let green = rgb("#3A7D44")
#let soft_green = green.transparentize(88%)
#let orange = rgb("#B86B00")
#let soft_orange = orange.transparentize(88%)
#let red = rgb("#9B2C2C")
#let soft_red = red.transparentize(88%)

== Front-end and ADC compatibility

#grid(
  columns: (0.95fr, 1.05fr),
  gutter: 0.55cm,

  [
    #rect(
      width: 100%,
      height: 12cm,
      radius: 7pt,
      stroke: theme_blue + 1pt,
      fill: light_blue,
      inset: 0.25cm,
    )[
      #text(size: 18pt, weight: "bold", fill: theme_blue)[Analog front-end]

#v(0.2cm)

#align(center)[
  #stack(
    dir: ttb,
    spacing: 0.1cm, // <--- Controla el espacio total entre bloques y flechas
    
    // Bloque 1
    rect(width: 82%, radius: 5pt, stroke: theme_blue + 0.8pt, fill: white, inset: 0.2cm,
      text(size: 12.5pt, weight: "bold")[MEMS LF/HF output]),
    
    text(size: 12pt, fill: theme_blue)[↓],
    
    // Bloque 2
    rect(width: 82%, radius: 5pt, stroke: green + 0.8pt, fill: soft_green, inset: 0.2cm,
      text(size: 12.5pt, weight: "bold", fill: green)[High-impedance buffer / LNA]),
    
    text(size: 12pt, fill: theme_blue)[↓],
    
    // Bloque 3
    rect(width: 82%, radius: 5pt, stroke: orange + 0.8pt, fill: soft_orange, inset: 0.2cm,
      text(size: 12.5pt, weight: "bold", fill: orange)[Gain or attenuation]),
    
    text(size: 12pt, fill: theme_blue)[↓],
    
    // Bloque 4
    rect(width: 82%, radius: 5pt, stroke: theme_blue + 0.8pt, fill: white, inset: 0.2cm,
      text(size: 12.5pt, weight: "bold")[Protection + RC filter]),
    
    text(size: 12pt, fill: theme_blue)[↓],
    
    // Bloque 5
    rect(width: 82%, radius: 5pt, stroke: red + 0.8pt, fill: soft_red, inset: 0.2cm,
      text(size: 12.5pt, weight: "bold", fill: red)[AD7606C-18 input])
  )
]

      #v(0.18cm)

      #rect(
        width: 100%,
        radius: 5pt,
        stroke: theme_blue + 0.7pt,
        fill: white,
        inset: 0.13cm,
      )[
        #text(size: 12.5pt)[The external front-end adapts impedance, signal level and protection before conversion.]
      ]
    ]
  ],

  [
    #rect(
      width: 100%,
      height: 1.85cm,
      radius: 7pt,
      stroke: theme_blue + 1pt,
      fill: white,
      inset: 0.22cm,
    )[
      #text(size: 17pt, weight: "bold", fill: theme_blue)[Why gain/attenuation?]

      #v(-0.5cm)

      #text(size: 13pt)[Low SPL signals are very small, while high SPL signals can exceed the ADC range.]
    ]

    #v(0.25cm)

    #rect(
      width: 100%,
      height: 2.5cm,
      radius: 7pt,
      stroke: orange + 1pt,
      fill: soft_orange,
      inset: 0.22cm,
    )[
      #text(size: 17pt, weight: "bold", fill: orange)[Input range rule]

      #v(0.12cm)

      #align(center)[
        #text(size: 16pt)[$abs(V_"ADC,in") <= V_"ADC,FS"$]
      ]

      #v(0.08cm)

      #text(size: 12.7pt)[For a ±10 V range, the ADC input must remain between −10 V and +10 V.]
    ]

    #v(0.2cm)

    #rect(
      width: 100%,
      height: 2.25cm,
      radius: 7pt,
      stroke: green + 1pt,
      fill: soft_green,
      inset: 0.22cm,
    )[
      #text(size: 17pt, weight: "bold", fill: green)[Sampling compatibility]

      #v(0cm)

      #text(size: 12pt)[LF: 50–100 kS/s for signals up to 10 kHz.]

      #v(0cm)

      #text(size: 13pt)[HF: 500 kS/s–1 MS/s for signals up to 100 kHz.]
    ]

    #v(0.25cm)

    #rect(
      width: 100%,
      height: 1.1cm,
      radius: 7pt,
      stroke: theme_blue + 0.9pt,
      fill: light_blue,
      inset: 0.14cm,
    )[
      #align(center + horizon)[
        #text(size: 12pt, weight: "bold", fill: theme_blue)[]
        #text(size: 12.8pt)[ ADC channel count is solved, but analog conditioning is still required.]
      ]
    ]
  ],
)