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
  image(img_path + "tono digital 1khz.png", width: 100%),
  caption: [Acquisition of a 1 kHz digital tone in LabVIEW]
)

== Data storage and calibration

In addition to displaying the signal, the LabVIEW program was also used to store the acquired data. The samples obtained during the measurement were saved in a binary file, so the complete acquisition could be processed or reviewed later.

#figure(
  image(img_path + "data_storage.png", width: 70%),
  caption: [LabVIEW processing pipeline including signal analysis and data storage]
)

The calibration was not implemented as a complete automatic process. However, the acquired voltage values were related to acoustic units using the assumed microphone sensitivity. A more accurate calibration could be performed in future work by using a reference sound level meter and adjusting the conversion factor between the measured voltage and the real acoustic pressure.

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

== Final characterization results

The complete system was tested with acoustic tones and with the two conditioned microphone signals connected to the DAQ. The main results are summarized in the following table.

#table(
  columns: (2.2fr, 2.2fr, 3fr),
  inset: 6pt,
  align: left,
  fill: (col, row) => {if row == 0 {gray.lighten(50%)}},
  [*Test*], [*Observed result*], [*Conclusion*],

  [Single microphone acquisition],
  [The signal was displayed in LabVIEW in the time domain and in the FFT.],
  [The complete acquisition chain worked correctly for one conditioned microphone.],

  [1 kHz tone test],
  [The tone was visible in the acquired signal and in the frequency-domain representation.],
  [The system was able to detect the main frequency component of the acoustic signal.],

  [Two-channel oscilloscope test],
  [Two signals were observed at the same time using the oscilloscope.],
  [The outputs of the conditioning circuits could be compared simultaneously.],

  [Change in sound-source position],
  [The signal amplitude changed when the acoustic source was moved.],
  [The microphones responded differently depending on their distance from the source.],

  [Data storage],
  [The acquired samples were saved in a binary file.],
  [The measurement could be stored for later analysis.],
)

Overall, the final characterization confirmed that the integrated system was able to detect acoustic signals, condition them, acquire them with the NI-USB-6009 DAQ and display the results in LabVIEW.
