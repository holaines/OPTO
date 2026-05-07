
= Summary of completed objectives

The following table summarizes the main laboratory objectives and the degree of completion achieved in the project.

#table(
  columns: (2.3fr, 1.2fr, 3.5fr),
  inset: 6pt,
  align: left,
  fill: (col, row) => {if row == 0 {gray.lighten(50%)}},
  [*Objective*], [*Status*], [*Comment*],

  [LabVIEW programs and DAQ tests],
  [Completed],
  [MAX analog input/output tests, LabVIEW acquisition, continuous acquisition and analog output generation were implemented and tested.],

  [Measurements in acoustic units],
  [Completed],
  [The acquired voltage signal was represented in Pa and dB-SPL using the assumed sensitivity of 5 mV/Pa. The FFT was also displayed.],

  [Analog signal conditioning],
  [Partially completed],
  [The INA131 conditioning circuit was implemented and tested with an analog MEMS microphone. The circuit amplified the microphone signal correctly, although a more detailed theoretical design could be improved.],

  [Sensor implementation and tests],
  [Completed],
  [The analog microphones were connected to their conditioning circuits and tested with acoustic tones. The output signals were observed with the oscilloscope.],

  [Acquisition strategy],
  [Completed],
  [The conditioned microphone signals were acquired using the NI-USB-6009 DAQ and represented in LabVIEW. Two microphones were also acquired simultaneously.],

  [Signal processing and measurement analysis],
  [Partially completed],
  [The system displayed the time-domain signal, FFT and SPL values. Calibration and data storage were not fully developed and are proposed as future improvements.],

  [Complete system integration],
  [Completed],
  [The microphones, conditioning circuits, DAQ and LabVIEW interface were connected and tested as a complete instrumentation system.],

  [Self-evaluation],
  [Completed],
  [A final self-evaluation was included, describing the group organization, task distribution and possible improvements.],
)
