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

