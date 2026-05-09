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
    gutter: 0.75cm,
    [
      #rect(
        width: 100%,
        height: 2.15cm,
        radius: 6pt,
        stroke: theme_blue + 1pt,
        fill: theme_blue.transparentize(90%),
        inset: 0.35cm,
      )[
        #text(size: 18pt, weight: "bold", fill: theme_blue)[Context]

        #v(0.12cm)

        #text(size: 15.5pt)[
          Aero-acoustic tests need microphone arrays to measure noise at many points of the aircraft structure.
        ]
      ]

      #v(0.35cm)

      #rect(
        width: 100%,
        height: 2.15cm,
        radius: 6pt,
        stroke: theme_blue + 1pt,
        fill: theme_blue.transparentize(90%),
        inset: 0.35cm,
      )[
        #text(size: 18pt, weight: "bold", fill: theme_blue)[Applications]

        #v(0.12cm)

        #text(size: 15.5pt)[
          The system is intended for wind tunnel tests and flight test applications.
        ]
      ]
    ],
    [
      #rect(
        width: 100%,
        height: 2.15cm,
        radius: 6pt,
        stroke: theme_blue + 1pt,
        fill: theme_blue.transparentize(90%),
        inset: 0.35cm,
      )[
        #text(size: 18pt, weight: "bold", fill: theme_blue)[Main challenge]

        #v(0.12cm)

        #text(size: 15.5pt)[
          The system has to acquire many acoustic signals with enough bandwidth, dynamic range and synchronization.
        ]
      ]

      #v(0.35cm)

      #rect(
        width: 100%,
        height: 2.15cm,
        radius: 6pt,
        stroke: theme_blue + 1pt,
        fill: theme_blue.transparentize(90%),
        inset: 0.35cm,
      )[
        #text(size: 18pt, weight: "bold", fill: theme_blue)[Objective]

        #v(0.12cm)

        #text(size: 15.5pt)[
          Design a scalable instrumentation system for 80 dual-output MEMS microphones.
        ]
      ]
    ],
  )
]

// Salto de página
#pagebreak()
