#import "@preview/acrostiche:0.7.0": *

= Session 1
#let img_path = "../img/session-1/"

In this session, we used the NI-USB-6009 #acr("DAQ") with MAX and LabVIEW. The main goal was to acquire and generate simple analog signals and check that the programs worked correctly.

== MAX tests

First, we created tasks in MAX to test the #acr("DAQ"). One task was used for analog input acquisition and another one for analog output generation. With these tests, we verified that the #acr("DAQ") was working correctly.

#figure(
  image(img_path + "E0.png", width: 75%),
  caption: [Analog input acquisition task in MAX]
)

#figure(
  image(img_path + "E1.png", width: 75%),
  caption: [Analog output generation task in MAX]
)

== LabVIEW acquisition

Once the #acr("DAQ") had been tested in MAX, we repeated the acquisition in LabVIEW. The first #acr("VI") was used to read the analog input signal and display the waveform.

#figure(
  image(img_path + "Ej6.png", width: 75%),
  caption: [LabVIEW VI for analog input acquisition]
)

We also used a continuous acquisition #acr("VI"), where the waveform was refreshed while the program was running.

#figure(
  image(img_path + "E7.png", width: 75%),
  caption: [Continuous analog input acquisition in LabVIEW]
)

== Analog output generation

We also tested the analog output of the #acr("DAQ") using LabVIEW. A simple signal was generated and measured to check that the output was working correctly.

#figure(
  image(img_path + "E8.png", width: 75%),
  caption: [Analog output generation and acquisition test]
)

== Acoustic units

Finally, the acquired voltage signal was converted into acoustic pressure and sound pressure level. For this conversion, we assumed a sensitivity of 5 mV/Pa, as indicated in class.

#figure(
  grid(
    columns: (1fr,),
    gutter: 1em,
    image(img_path + "Pascales.png", width: 75%),
    image(img_path + "dBspl.png", width: 75%),
  ),
  caption: [Signal represented in Pa and dB-SPL]
)

We also displayed the #acr("FFT") to observe the main frequency component of the acquired signal.

#figure(
  image(img_path + "3Hz spl.png", width: 75%),
  caption: [FFT representation of the acquired signal]
)