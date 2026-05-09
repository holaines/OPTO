#let theme_blue = rgb("#1f4f6b")

== Project context and objective

#grid(
  columns: (1fr, 1fr),
  gutter: 0.85cm,
  [
    #rect(
      width: 100%,
      height: 4cm,
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
      height: 4cm,
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
      height: 4cm,
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
      height: 4cm,
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