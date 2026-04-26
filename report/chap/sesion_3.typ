= Session 3
#let img_path = "../img/session-3/"


In the previous sessions, basic acquisition programs were developed in LabVIEW for the NI-USB6009 DAQ, enabling signal recording at typical audio sampling frequencies (e.g., 14 kSps). Additionally, different MEMS microphones were tested, their specifications analyzed, and the required signal conditioning circuits were designed for proper connection to the DAQ (see Appendix).

The objective of this session is to acquire signals from one or more conditioned sensors, process the obtained data, and present the results in a useful format. 

In this session we will be using two different MEMS microphones:

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

#figure(
  image(img_path + "amboscircuitos.jpeg", width: 70%),
  caption: [AI0 configuration in MAX]
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
      caption: [Signal acquired with the second microphone while producing noise]
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
      caption: [Signal acquired with the second microphone while not producing noise]
    )
  ]
)

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
      caption: [Signal acquired with the first microphone while not producing noise]
    )
  ]
)
We can properly see in the images the LabVIEW interface and there are three different plots displayed:

The Waveform Chart (top) represents the real-time evolution of the acquired signal amplitude over time.
The Waveform Graph (middle) shows a zoomed time-domain segment of the signal, allowing clearer observation of its oscillatory behaviour.
The Waveform Graph 2 (bottom) corresponds to the frequency-domain representation (spectrum), where the dominant frequency components of the signal can be identified (705 Hz).

When introducing a pure tone of 705 Hz, a clear spectral peak appears around this frequency in the spectrum plot, confirming correct acquisition of the injected signal through the microphone and the conditioning circuit. The meter indicator also reflects this detected frequency value.