= Session 1
#let img_path = "../img/session-1/"


//Nos piden haber hecho esto para tener la puntuacion completa de la sesion: 1. MAX AI, MAX AO, VI express AI, VI DAQmx AI, continuous, AO [75%] 2. Measurements in Pa or dB-SPL, different frequencies [25%] 3. Extra: VI display similar to sound level meter [25%]

// nos falta por hacer bien lo  de dbSPL y lo de Pa !

In this session we wanted to learn how to use the NI-USB-6009 acquisition board together with Measurement and Automation Explorer (MAX) and LabVIEW to acquire and generate analog signals. 

The acquired voltage signals were also converted into acoustic pressure (Pa) and sound pressure level (dB-SPL), assuming a microphone sensitivity of 5 mV/Pa.

Test frequencies used during the session were 100 Hz, 1 kHz and 10 kHz, which are representative audio frequencies.

The first thing we did, was to create two different tasks in MAX (Measurement and Automation Explorer): one for analog output signal generation (AO_GEN1) and another for analog input signal acquisition (AI_ACQ1). The generated signal was then measured using continuous acquired mode through channel AI0 and the adquired one through the AO0 channel.



#figure(
  image(img_path + "E0.png", width: 70%),
  caption: [AI0 configuration in MAX]
)

