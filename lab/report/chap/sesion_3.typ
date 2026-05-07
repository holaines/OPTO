#import "@preview/acrostiche:0.7.0": *

= Session 3
#let img_path = "../img/session-3/"

In the previous sessions, basic acquisition programs were developed in LabVIEW for the NI-USB6009 #acr("DAQ"), enabling signal recording at typical audio sampling frequencies (e.g., 14 kSps). Additionally, different #acr("MEMS") microphones were tested, their specifications analyzed, and the required signal conditioning circuits were designed for proper connection to the #acr("DAQ") (see Appendix).

The objective of this session is to acquire signals from one or more conditioned sensors, process the obtained data, and present the results in a useful format. 

== Microphones used

In this session we will be using two different analog #acr("MEMS") microphones:

#grid(
  columns: 2,
  gutter: 1cm,
  [
    #figure(
      image(img_path + "microines.jpeg", width: 100%),
      caption: [First microphone]
    )
  ],
  [
    #figure(
      image(
      img_path + "microagusyjavi.jpeg",
      width: 100%,
        height: 5.5cm,
      fit: "cover"
  ),  
      caption: [Second microphone]
    )
  ]
)

We make sure both circuits are properly connected before doing any Measurements, and then we proceed to acquire signals from both microphones while producing noise and while not producing noise.

== Acquisition strategy by sensor

Before starting the measurements, we defined the acquisition strategy for each microphone. Both sensors were analog #acr("MEMS") microphones connected to their conditioning circuits and acquired with the NI-USB-6009 #acr("DAQ") in LabVIEW.

#figure(
  table(
    columns: (1.8fr, 1.8fr, 1.8fr, 2.4fr),
    inset: 6pt,
    align: left,
    fill: (col, row) => {if row == 0 {gray.lighten(50%)}},
    [*Sensor*], [*Acquisition input*], [*Test performed*], [*Result*],

    [First analog #acr("MEMS") microphone],
    [Analog input of the NI-USB-6009 #acr("DAQ")],
    [Acquisition with and without acoustic excitation],
    [The signal increased when sound was generated close to the microphone.],

    [Second analog #acr("MEMS") microphone],
    [Analog input of the NI-USB-6009 #acr("DAQ")],
    [Acquisition with and without acoustic excitation],
    [The signal also increased with sound, allowing comparison with the first microphone.],

    [Both microphones together],
    [Two analog inputs of the NI-USB-6009 #acr("DAQ")],
    [Simultaneous acquisition in LabVIEW],
    [Amplitude and delay differences were observed depending on the position of the sound source.],
  ),
  caption: [Acquisition table per sensor]
)

== Acquisition with and without noise

#figure(
  image(img_path + "amboscircuitos.jpeg", width: 70%),
  caption: [Both circuits properly connected]
)

For the first microphone, and while producing noise, we obtained the following signal in the right, and while not producing noise, we obtained the one on the left :

#grid(
  columns: (1fr, 1fr),
  gutter: 1cm,
  [
    #figure(
      image(
        img_path + "fotomicroinesconruido.jpeg",
        width: 100%,
        height: 7cm,
        fit: "cover",
      ),
      caption: [Signal acquired with the first microphone while producing noise]
    )
  ],
  [
    #figure(
      image(
        img_path + "fotomicroinessinruido.jpeg",
        width: 120%,
        height: 7cm,
        fit: "cover",
      ),
      caption: [Signal acquired with the first microphone while not producing noise]
    )
  ]
)

Now for the second microphone, and while producing noise, we obtained the following signal in the right, and while not producing noise, we obtained the one on the left :

#grid(
  columns: (1fr, 1fr),
  gutter: 1cm,
  [
    #figure(
      image(
        img_path + "fotomicroagusyjaviconruido.jpeg",
        width: 100%,
        height: 7cm,
        fit: "cover",
      ),
      caption: [Signal acquired with the second microphone while producing noise]
    )
  ],
  [
    #figure(
      image(
        img_path + "fotomicroagusyjavisinruido.jpeg",
        width: 120%,
        height: 7cm,
        fit: "cover",
      ),
      caption: [Signal acquired with the second microphone while not producing noise]
    )
  ]
)
When external acoustic excitation is present, the oscilloscope shows a clear periodic waveform corresponding to the injected tone. In contrast, when no intentional sound is generated, only low-amplitude background noise is observed. This confirms that both conditioning circuits correctly amplify the microphone output and allow detection of external acoustic signals above the noise floor

== Output amplitude measurements

We now measured the amplitude of the acquired signals at the output of the amplifier and at the output of the microphone, and we obtained the following values:

#grid(
  columns: (1fr, 1fr),
  gutter: 1cm,
  [
    #figure(
      image(
        img_path + "fotomicroines.jpeg",
        width: 100%,
        height: 7cm,
        fit: "cover",
      ),
      caption: [Signal acquired with the first microphone while producing noise]
    )
  ],
  [
    #figure(
      image(
        img_path + "fotomicroagusyjavi.jpeg",
        width: 120%,
        height: 7cm,
        fit: "cover",
      ),
      caption: [Signal acquired with the second microphone while producing noise]
    )
  ]
)
The signal amplitude measured at the amplifier output is higher than at the microphone output, confirming the expected gain introduced by the conditioning stage. This amplification improves the signal-to-noise ratio and allows reliable acquisition with the NI-USB6009 #acr("DAQ").

== LabVIEW signal representation

We were now looking to be able to represent the information we obtained in and present it in a useful form:

#grid(
  columns: (0.4fr, 1.6fr),
  gutter: 1cm,

  [
    #align(left,
      figure(
        image(
          img_path + "705HZ.jpeg",
          width: 100%,
          height: 7cm,
          fit: "cover",
        ),
        caption: [Inserted frequency = 705 Hz]
      )
    )
  ],

  [
    #figure(
      image(
        img_path + "foto con el medidor.png",
        width: 100%,
        height: 13cm,
        fit: "cover",
      ),
      caption: [Different charts in LabVIEW interface]
    )
  ]
)
We can properly see in the images the LabVIEW interface and there are three different plots displayed:

The Waveform Chart (top) represents the real-time evolution of the acquired signal amplitude over time.
The Waveform Graph (middle) shows a zoomed time-domain segment of the signal, allowing clearer observation of its oscillatory behaviour.
The Waveform Graph 2 (bottom) corresponds to the frequency-domain representation (spectrum), where the dominant frequency components of the signal can be identified (705 Hz).

When introducing a pure tone of 705 Hz, a clear spectral peak appears around this frequency in the spectrum plot, confirming correct acquisition of the injected signal through the microphone and the conditioning circuit. The meter indicator also reflects this detected frequency value.

== Simultaneous acquisition of both microphones

We noticed that we could connect both circuits to the same computer and see the acquired signals from both microphones simultaneously in LabVIEW, which is a very useful feature for comparing the performance of different sensors under the same conditions, or even by aproaching the emited frequency to one micorphone or to another to see the different delays.

#figure(
  image(img_path + "comparacion masfuerte ines.png", width: 100%),
  caption: [Signal acquired while aproaching the emitted frequency to the first microphone]
)

In this figure, the acquired signal presents a noticeably higher amplitude in the time-domain waveform compared to the second microphone. This indicates that this microphone was positioned closer to the acoustic source. Also #acr("SPL") decreases with distance due to propagation losses in air.

The #acr("FFT") spectrum shows a clear dominant peak around the excitation frequency (≈705 Hz), confirming correct detection of the injected tone. The higher spectral magnitude at this frequency also reflects the stronger received signal energy.

The #acr("SPL") representation further supports this observation, showing larger pressure variations (higher dB-SPL values), which are consistent with a shorter distance between the microphone and the sound source.

Compared with the second microphone, a slight phase advance can also be observed, suggesting a smaller propagation delay, again consistent with a closer position relative to the emitter. We will se this further on more clearly. 

#figure(
  image(img_path + "comparacion masfuerte agus.png", width: 100%),
  caption: [Signal acquired while aproaching the emitted frequency to the second microphone]
)

In this figure we can see the same results, the acquired signal presents a noticeably higher amplitude in the time-domain waveform compared to the first microphone. This indicates that this microphone was positioned closer to  the acoustic source. 

== Delay between microphones

We now want to take a deeper look into the delay: 
#figure(
  image(img_path + "comp masfuerte con desafse en medio.png", width: 100%),
  caption: [Signal acquired while putting the emitted frequency closer to the second microphone]
)

This figure shows the simultaneous acquisition of the signals from both microphones in the time domain, allowing comparison of their relative phase. Since the excitation frequency (705 Hz) was generated closer to the second microphone, a noticeable phase shift between the signals is expected. As observed in the waveform graph, the peaks of the two signals are not aligned, indicating a propagation delay between sensors caused by the difference in distance from the sound source.

In addition to the phase shift, a difference in signal amplitude can also be observed. The microphone located closer to the source presents a higher amplitude and higher #acr("SPL") values, which is consistent with the expected attenuation of acoustic pressure with distance.

The #acr("FFT") representation confirms that both microphones detect the same dominant frequency component at approximately 705 Hz, proving that the difference between signals is due to spatial positioning, not to frequency variation.

Therefore, the observed phase displacement and amplitude difference are consistent with the sound source being positioned closer to one microphone than the other.
