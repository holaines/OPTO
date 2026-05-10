#let navy = rgb("#17324D")
#let blue = rgb("#2F6F9F")
#let light-blue = rgb("#EAF3F8")
#let pale-blue = rgb("#F6FAFD")
#let orange = rgb("#B86B00")
#let light-orange = rgb("#FFF4E3")
#let green = rgb("#3A7D44")
#let light-green = rgb("#ECF7EF")

// --- DIAPOSITIVA 1: ESTRUCTURA DE ADQUISICIÓN ---
== One acquisition zone: System Architecture

#grid(
  columns: (1.2fr, 0.8fr),
  column-gutter: 0.6cm,

  // Bloque Izquierdo: Flujo de Señal
  rect(
    width: 100%, radius: 8pt, stroke: navy + 1.5pt, fill: pale-blue, inset: 0.4cm,
  )[
    #text(size: 16pt, weight: "bold", fill: navy)[Zone structure (1 of 10)]
    #v(0.4cm)
    #align(center)[
      #stack(
        spacing: 0.2cm,
        rect(width: 95%, radius: 6pt, stroke: blue + 1pt, fill: white, inset: 0.2cm)[
          #text(size: 13pt, weight: "bold", fill: blue)[8 dual-frequency MEMS microphones]
        ],
        text(size: 15pt, fill: blue)[$arrow.b$],
        rect(width: 85%, radius: 6pt, stroke: grey + 0.8pt, fill: white, inset: 0.15cm)[
          #text(size: 11pt, style: "italic")[LF and HF branches are acquired separately]
        ],
        text(size: 15pt, fill: blue)[$arrow.b$],
        grid(
          columns: (1fr, 1fr), gutter: 0.3cm,
          rect(width: 100%, radius: 6pt, stroke: blue + 1pt, fill: light-blue, inset: 0.2cm)[
            #text(size: 12pt, weight: "bold", fill: blue)[8 LF outputs] \
            #text(size: 9pt)[Up to 10 kHz]
          ],
          rect(width: 100%, radius: 6pt, stroke: orange + 1pt, fill: light-orange, inset: 0.2cm)[
            #text(size: 12pt, weight: "bold", fill: orange)[8 HF outputs] \
            #text(size: 9pt)[Up to 100 kHz]
          ]
        ),
        text(size: 15pt, fill: blue)[$arrow.b$],
        grid(
          columns: (1fr, 1fr), gutter: 0.3cm,
          rect(width: 100%, radius: 6pt, stroke: blue + 1pt, fill: white, inset: 0.2cm,
            text(size: 11pt, weight: "bold")[AD7606C-18 (LF)]),
          rect(width: 100%, radius: 6pt, stroke: orange + 1pt, fill: white, inset: 0.2cm,
            text(size: 11pt, weight: "bold")[AD7606C-18 (HF)])
        )
      )
    ]
  ],

  // Bloque Derecho: Resumen numérico
  stack(
    spacing: 0.3cm,
    rect(width: 100%, radius: 6pt, stroke: navy + 1pt, fill: white, inset: 0.25cm)[
      #text(weight: "bold", fill: navy)[System Totals] \
      #v(0.1cm)
      #set text(size: 10pt)
      - 80 MEMS microphones
      - 160 Analog channels
      - *20 AD7606C-18 ADCs*
    ],
    rect(width: 100%, radius: 6pt, stroke: orange + 1.2pt, fill: light-orange, inset: 0.25cm)[
      #text(weight: "bold", fill: orange)[Key Concept] \
      #v(0.1cm)
      #text(size: 10pt)[No external multiplexing is used. Each ADC handles 8 simultaneous channels to preserve phase.]
    ]
  )
)

#pagebreak()

// --- DIAPOSITIVA 2: ACONDICIONAMIENTO ANALÓGICO ---
== One acquisition zone: Analog Front-End (AFE)

#grid(
  columns: (1.1fr, 0.9fr),
  column-gutter: 0.6cm,

  // Bloque Izquierdo: Cadena por canal
  rect(width: 100%, radius: 8pt, stroke: navy + 1.5pt, fill: light-grey, inset: 0.4cm)[
    #text(size: 16pt, weight: "bold", fill: navy)[Signal Chain (per channel)]
    #v(0.3cm)
    #align(center)[
      #set text(size: 11pt, weight: "bold")
      #stack(
        spacing: 0.15cm,
        rect(width: 80%, fill: white, stroke: navy + 0.8pt, [MEMS Output]),
        text(fill: blue)[$arrow.b$],
        rect(width: 80%, fill: light-green, stroke: green + 0.8pt, [Buffer / LNA (AD8429)]),
        text(fill: blue)[$arrow.b$],
        rect(width: 80%, fill: light-orange, stroke: orange + 0.8pt, [Gain / Attenuation Stage]),
        text(fill: blue)[$arrow.b$],
        rect(width: 80%, fill: pale-blue, stroke: blue + 0.8pt, [Protection + RC Filter]),
        text(fill: blue)[$arrow.b$],
        rect(width: 80%, fill: white, stroke: red + 1pt, [AD7606C-18 Input])
      )
    ]
  ],

  // Bloque Derecho: Justificación y Rango
  stack(
    spacing: 0.4cm,
    rect(width: 100%, radius: 6pt, stroke: blue + 1pt, fill: pale-blue, inset: 0.25cm)[
      #text(weight: "bold", fill: blue)[Dynamic Range Challenge]
      #v(0.1cm)
      #set text(size: 9pt)
      - *Low SPL (30 dB):* Signals in the $mu V$ range. Requires low-noise amplification.
      - *High SPL (170 dB):* Raw output up to *63V*. Requires significant attenuation.
    ],
    rect(width: 100%, radius: 6pt, stroke: green + 1pt, fill: light-green, inset: 0.25cm)[
      #text(weight: "bold", fill: green)[Gain Strategy]
      #v(0.1cm)
      #set text(size: 9pt)
      - *High-Gain:* For low SPL signals.
      - *Unity-Gain:* For medium SPL.
      - *Attenuation:* To prevent ADC saturation at high SPL.
    ]
  )
)