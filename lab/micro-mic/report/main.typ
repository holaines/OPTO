#import "lib/style.typ": setup
#import "cover.typ": cover

#let doc_title = "Micro-Mic: Mixed-Signal Network Oscilloscope"
#let authors_portrait = ("Rubén Agustín",)
#let authors_header = "Rubén Agustín"
#let course = "Opto-Lab"
#let date = "May 2026"

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
#pagebreak()

#include "chap/01_intro.typ"
#include "chap/02_firmware.typ"
#include "chap/03_frontend.typ"
#include "chap/04_conclusions.typ"
