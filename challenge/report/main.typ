#import "lib/style.typ": setup
#import "cover.typ": cover

#let doc_title = "INSTRUMENTATION WITH MEMS MICROPHONE ARRAYS FOR AERONAUTICAL TESTING"
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
#pagebreak()
#outline(title: "Table of Figures", target: figure.where(kind: image))
#pagebreak()
#outline(title: "Table of Tables", target: figure.where(kind: table))
#pagebreak()

#include "chap/1_introduction.typ"
#include "chap/2_requirements.typ"
#include "chap/3_architecture.typ"
#include "chap/4_front-end.typ"
#include "chap/5_acquisition.typ"
#include "chap/6_FPGA.typ"
#include "chap/7_power_supply.typ"
#include "chap/8_data_handling.typ"
#include "chap/9_verification.typ"
