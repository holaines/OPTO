= Session 1
#let img_path = "../img/session-1/"


//Nos piden esto: MAX AI, MAX AO, VI express AI, VI DAQmx AI, continuous, AO [75%] • Measurements in Pa or dB-SPL, different frequencies [25%] • Extra: VI display similar to sound level meter [25%]

In this session we wanted to learn how to use the NI-USB-6009 acquisition board together with Measurement and Automation Explorer (MAX) and LabVIEW to acquire and generate analog signals. 

The acquired voltage signals were also converted into acoustic pressure (Pa) and sound pressure level (dB-SPL), assuming a microphone sensitivity of 5 mV/Pa.

Test frequencies used during the session were 100 Hz, 1 kHz and 10 kHz, which are representative audio frequencies.

#figure(
  image(img_path + "E0.png", width: 70%),
  caption: [AI0 configuration in MAX]
)

