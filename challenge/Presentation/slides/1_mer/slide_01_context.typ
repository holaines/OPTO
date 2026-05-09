// slides/1_mer/slide_01_context.typ


// Formato de la diapositiva
#let theme_blue = rgb("#1f4f6b")

#place(
  top + left,
  rect(
    width: 100%,
    height: 0.22cm,
    fill: theme_blue.transparentize(12%),
    stroke: none,
  ),
)

#place(
  top + left,
  dx: 1.05cm,
  dy: 0.65cm,
  text(size: 28pt, weight: "bold", fill: black)[Project context and objective],
)// Título de la diapositiva

#place(
  left + bottom,
  dx: 0.85cm,
  dy: -0.55cm,
  image("../../figures/Logo_UC3M.png", width: 1.8cm),
)

#place(
  right + bottom,
  dx: -0.9cm,
  dy: -0.55cm,
  text(size: 13pt, fill: theme_blue)[1],
)

// Contenido de la diapositiva
#block(
  width: 100%,
  inset: (top: 1.75cm, left: 1.05cm, right: 1.05cm, bottom: 1.2cm),
)[
  #grid(
    columns: (1fr, 1fr),
    gutter: 0.8cm,
    [
      #text(size: 21pt)[
        This project is focused on the design of an electronic instrumentation system for aero-acoustic measurements.
      ]

      #v(0.35cm)

      - Wind tunnel tests
      - Flight test applications
      - MEMS microphone arrays
      - Synchronized acquisition of many acoustic signals
    ],
    [
      #rect(
        width: 100%,
        height: 4.6cm,
        radius: 6pt,
        stroke: theme_blue + 1pt,
        fill: theme_blue.transparentize(88%),
        inset: 0.45cm,
      )[
        #align(center + horizon)[
          #text(size: 25pt, weight: "bold", fill: theme_blue)[Objective]

          #v(0.25cm)

          #text(size: 19pt)[
            Design a scalable acquisition system for 80 dual-output MEMS microphones.
          ]
        ]
      ]
    ],
  )
]

// Salto de página
#pagebreak()
