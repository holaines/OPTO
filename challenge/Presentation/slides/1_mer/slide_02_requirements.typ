// slides/1_mer/slide_02_requirements.typ

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
  text(size: 28pt, weight: "bold", fill: black)[Título de la diapositiva],
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
  text(size: 13pt, fill: theme_blue)[2],
)

// Contenido de la diapositiva
#table(
  columns: (1fr, 1.4fr),
  inset: 7pt,
  align: (left, left),
  [*Requirement*], [*Target*],
  [MEMS microphones], [80],
  [Outputs per MEMS], [LF + HF],
  [Total analog signals], [160],
  [Frequency range], [100 Hz – 100 kHz],
  [Dynamic range], [30 dB SPL – 170 dB SPL],
  [Target SNR], [90 dB WTT / 70 dB FT],
  [Power supply], [28 V aircraft bus / 24 V battery],
)

// Salto de página
#pagebreak()