#let navy = rgb("#17324D")
#let blue = rgb("#2F6F9F")
#let light-blue = rgb("#EAF3F8")
#let pale-blue = rgb("#F6FAFD")
#let green = rgb("#3A7D44")
#let light-green = rgb("#ECF7EF")
#let orange = rgb("#B86B00")
#let light-orange = rgb("#FFF4E3")
#let red = rgb("#9B2C2C")
#let light-red = rgb("#FDECEC")
#let grey = rgb("#5A5A5A")
#let light-grey = rgb("#F4F6F8")

#let diagram-box(body) = align(center)[
  #box(
    width: 92%,
    inset: 10pt,
    stroke: 0.8pt + blue,
    fill: pale-blue,
    radius: 6pt,
  )[
    #text(font: "Courier", size: 8pt, fill: navy)[#body]
  ]
]

#let equation-box(body, color: blue, fill-color: light-blue) = align(center)[
  #box(
    inset: 8pt,
    stroke: 0.7pt + color,
    fill: fill-color,
    radius: 5pt,
  )[
    #body
  ]
]

#let note-box(title, body, color: blue, fill-color: light-blue) = box(
  width: 100%,
  inset: 9pt,
  stroke: 0.7pt + color,
  fill: fill-color,
  radius: 5pt,
)[
  #text(fill: color, weight: "bold")[#title] \
  #body
]

#set heading(numbering: "1.1")
= Verification of requirements

== Acquisition-stage conclusion

#note-box(
  [Conclusion],
  [
    The proposed acquisition architecture uses two AD7606C-18 devices per zone: one for the 8 LF outputs and one for the 8 HF outputs. Across 10 zones, the full system uses 20 AD7606C-18 devices and acquires 160 analog channels.

    The use of the AD7606C-18 removes the need for external analog multiplexers because each ADC provides 8 simultaneous sampling channels. This improves timing alignment between microphones and avoids the sampling delay introduced by multiplexed acquisition.

    The selected preliminary sampling rates are 51.2 kS/s per channel for the LF ADCs and 512 kS/s per channel for the HF ADCs. The LF rate gives 5.12 samples per period at 10 kHz, while the HF rate gives 5.12 samples per period at 100 kHz. These rates are above the Nyquist limit and keep the data rate manageable. If higher time-domain waveform fidelity is required, the HF ADCs can be operated closer to the 1 MS/s maximum rate of the AD7606C-18, which would provide 10 samples per period at 100 kHz.

    The main unresolved issue is not the number of channels but the analog dynamic range. The MEMS outputs can be extremely small at low SPL and too large at high SPL. Therefore, the AD7606C-18 must be used together with a calibrated analog front-end providing low-noise amplification, attenuation, protection and filtering.
  ],
  color: navy,
  fill-color: light-grey,
)

== Analog front-end conclusion

#note-box(
  [Conclusion],
  [
    The proposed analog front-end keeps the LF and HF outputs separated, preserving the dual-frequency behavior of the MEMS microphones. Each zone contains 16 analog paths: 8 LF paths and 8 HF paths. The external analog multiplexer is not used in the final architecture because each AD7606C-18 already acquires 8 channels simultaneously.

    However, the external analog interface is still necessary. Using a linear extrapolation from the nominal MEMS sensitivity, the MEMS output can range from microvolts at low SPL to tens of volts at high SPL. This does not mean that the sensor is guaranteed to remain linear up to these voltages, but it justifies the need for gain control, attenuation and protection. Therefore, each channel requires a low-noise buffer/LNA, selectable gain or attenuation, protection and local filtering before the AD7606C-18 input.

    The main design limitation is the very wide acoustic dynamic range. The front-end must be calibrated and the selected gain state must be stored with the acquired data so that the acoustic pressure can be reconstructed accurately during post-processing.
  ],
  color: navy,
  fill-color: light-grey,
)