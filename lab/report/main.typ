#import "@preview/acrostiche:0.7.0": *

#import "lib/style.typ": setup
#import "cover.typ": cover
#import "acronym.typ": acronyms

#let doc_title = "LabVIEW"
#let authors_portrait = ("Inés Menchero", "Javier del Río", "Mercedes Ramos", "Rubén Agustín")
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

#init-acronyms(acronyms)

#print-index(sorted: "up", title: "Acronyms Table")
#pagebreak()

#include "chap/sesion_1.typ"
#include "chap/sesion_2.typ"
#include "chap/sesion_3.typ"
#include "chap/sesion_4.typ"
#include "chap/at_home.typ"
