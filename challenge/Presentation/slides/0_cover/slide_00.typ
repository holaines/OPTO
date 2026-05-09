// slides/0_cover/slide_00.typ

#set page(
  paper: "presentation-16-9",
  margin: 0cm,
)

#set text(font: "New Computer Modern")

#place(
  top + left,
  image("../../figures/cover.png", width: 100%, height: 100%, fit: "cover"),
)

#place(
  top + left,
  rect(
    width: 100%,
    height: 100%,
    fill: rgb("#1f4f6b").transparentize(35%),
    stroke: none,
  ),
)

#place(
  top + center,
  dy: 1.5cm,
  block(width: 86%)[
    #align(center)[
      #text(size: 41pt, weight: "bold", fill: white)[
        Instrumentation system with\
        MEMS microphone arrays for\
        aeronautical testing
      ]
    ]
  ],
)

#place(
  left + bottom,
  dx: 1.25cm,
  dy: -1.85cm,
  image("../../figures/Fondo de “Logo_UC3M” eliminado.png", width: 5.0cm),
)

#place(
  bottom + center,
  dy: -5.5cm,
  block(width: 15cm)[
    #align(center)[
      #text(size: 25pt, fill: white, weight: "bold")[
        Electronic instrumentation and optoelectronics
      ]
    ]
  ],
)

#place(
  bottom + center,
  dy: -1.20cm,
  rect(
    width: 10cm,
    height: 3.4cm,
    stroke: white + 1.2pt,
    fill: none,
    inset: 0.35cm,
  )[
    #align(center)[
      #text(size: 16pt, fill: white, weight: "bold")[
        Rubén Agustín,\ Javier del Río,\ Inés Menchero,\ Mercedes Ramos
      ]
    ]
  ],
)

#pagebreak()

#set page(
  paper: "presentation-16-9",
  margin: 1.1cm,
)
