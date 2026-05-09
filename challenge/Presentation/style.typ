#import "@preview/touying:0.7.3": *

#let theme_blue = rgb("#1f4f6b")

#let custom-theme(
  aspect-ratio: "16-9",
  body,
) = {
  show: touying-slides.with(
    config-page(
      ..utils.page-args-from-aspect-ratio(aspect-ratio),
      margin: (top: 3.45cm, left: 2.15cm, right: 2.15cm, bottom: 2.0cm),
      header: none,
      footer: none,
      background: context {
        let page_num = counter(page).get().first()
        if page_num > 0 {
          // Barra Azul Superior
          place(top + left, dx: 1.1cm, dy: 1.1cm, rect(width: 100% - 2.2cm, height: 0.22cm, fill: theme_blue.transparentize(12%), stroke: none))
          
          place(top + left, dx: 2.15cm, dy: 1.75cm, {
            set text(size: 28pt, weight: "bold", fill: black)
            set block(above: 0pt, below: 0pt)
            utils.display-current-heading(level: 2)
          })

          // Logo UC3M
          place(bottom + left, dx: 1.95cm, dy: -1.65cm, image("figures/Logo_UC3M.png", width: 1.8cm))
          
          // Número de Página
          place(bottom + right, dx: -2cm, dy: -1.65cm, text(size: 13pt, fill: theme_blue)[#page_num])
        }
      }
    )
  )

  set text(
    font: "New Computer Modern",
    size: 22pt,
  )
  set par(justify: true)

  body
}