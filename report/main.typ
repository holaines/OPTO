#import "lib/style.typ": setup
#import "cover.typ": cover

#let doc_title = "LabVIEW"
#let authors_portrait = ("Inés Menchero", "Javier del Río Tarque", "Mercedes Ramos", "Rubén Agustín")
#let authors_header = "Inés Menchero, Javier del Río, Mercedes Ramos, Rubén Agustín"
#let course = "Electronic instrumentation and optoelectronics"
#let date = "April 2026"

#show heading: set block(above: 1.2em, below: 1em)
#set heading(numbering: "1.")

#set par(justify: true)

#cover(title: doc_title, course: course, authors: authors_portrait, date: date, img_path: "img/cover.png")
#pagebreak()

#show: doc => setup(
  doc,
  course,
  authors_header,
  doc_title,
)

#outline()
#outline(title: "Table of Figures", target: figure.where(kind: image))
#pagebreak()

#include "chap/placeholder.typ"
