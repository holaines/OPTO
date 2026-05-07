#import "@preview/acrostiche:0.7.0": *

= Session 4
#let img_path = "../img/session-4/"

In this session, we integrated the different parts of the laboratory work into a complete instrumentation system. The conditioned microphones were connected to the NI-USB-6009 #acr("DAQ") and the acquired signals were displayed in LabVIEW.

The main goal was to check that the complete system worked correctly, from the microphone and conditioning circuit to the acquisition and visualization stage.

== Block diagram

The complete system can be divided into the following blocks: the acoustic signal is detected by the MEMS microphones, the signal is amplified by the INA131 conditioning circuit, the NI-USB-6009 DAQ acquires the conditioned signal and LabVIEW displays the waveform and the FFT.

#figure(
  image(img_path + "block_diagram.png", width: 100%),
  caption: [Block diagram of the complete instrumentation system]
)
The interface between the microphone and the conditioning circuit is an analog voltage. The interface between the conditioning circuit and the DAQ is also an analog voltage, connected to the analog input of the NI-USB-6009. Finally, the DAQ sends the acquired data to LabVIEW, where the signal is represented in the time and frequency domains.

== Complete system

First, the different microphone conditioning circuits were connected together with the #acr("DAQ"). The complete setup included the #acr("MEMS") microphones, the INA131 amplification stages, the NI-USB-6009 module and the LabVIEW program.

#figure(
  image(img_path + "complete_setup.jpeg", width: 70%),
  caption: [Complete setup with the conditioning circuits and the DAQ]
)

We also checked the microphone board and its connections before acquiring the signal.

#figure(
  image(img_path + "mems_microphone_on_breadboard.jpeg", width: 70%),
  caption: [MEMS microphone connected on the protoboard]
)

== LabVIEW acquisition

After connecting the complete system, we used LabVIEW to acquire the signals from the microphones. The program displayed the signal in the time domain and also the #acr("FFT"), so the acoustic signal could be observed more clearly.

#figure(
  image(img_path + "labview_acquisition_fft.jpeg", width: 100%),
  caption: [LabVIEW acquisition with time-domain signal and FFT]
)

== Oscilloscope test

The oscilloscope was also used to check the output signals of the complete system. Two channels were observed at the same time, which allowed us to compare the signals from the different conditioning circuits.

#figure(
  grid(
    columns: (1fr, 1fr),
    gutter: 1em,
    image(img_path + "oscilloscope_two_channels_1.jpeg", width: 100%),
    image(img_path + "oscilloscope_two_channels_3.jpeg", width: 100%),
  ),
  caption: [Oscilloscope measurements of the complete system]
)

The signals changed depending on the acoustic excitation and on the position of the sound source. This confirmed that the microphones and their conditioning circuits were detecting the acoustic signal.
