#let setup(
  body,
  course,
  author,
  title,
) = {
  set page(
    paper: "a4",
    margin: (top: 22mm, bottom: 20mm, left: 22mm, right: 22mm),
    numbering: "1",
    header-ascent: 15%,
    footer-descent: 12%,

    header: context {
      let (p,) = counter(page).get()
      let even = calc.rem(p, 2) == 0
      let left-text = if even { course } else { author }
      let right-text = if even { author } else { title }

      set text(size: 9pt, fill: gray)

      stack(
        spacing: 3pt,
        grid(
          columns: (1fr, 1fr),
          align: (left, right),
          left-text,
          right-text,
        ),
        line(length: 100%, stroke: 0.25pt + gray),
      )
    },

    footer: context {
      set text(size: 9pt, fill: gray)
      align(center)[#counter(page).display()]
    },
  )

  set text(font: "Libertinus Serif", size: 10.5pt)
  set par(justify: true)

  counter(page).update(1)
  body
}
