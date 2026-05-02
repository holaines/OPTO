= Global system architecture

The proposed system is divided into 10 equal zones. Each zone contains 8 MEMS microphones. Since each microphone has two outputs, one for the LF band and one for the HF band, each zone has 16 analog signals.

The two frequency bands are acquired separately. The HF outputs of the 8 microphones are connected to one AD7606C-18, and the LF outputs are connected to another AD7606C-18. In this way, each zone uses two ADCs: one for the 8 HF channels and one for the 8 LF channels.

Before entering the AD7606C-18, the microphone outputs pass through a low-noise amplifier (LNA). After this stage, each AD7606C-18 performs the conversion of the 8 channels of one frequency band.

#figure(
  image("../img/ad7606c18_diagram.png", width: 85%),
  caption: [Simplified internal structure of the AD7606C-18.]
)

The AD7606C-18 is used as a complete acquisition block. It includes 8 analog inputs, a PGA stage, low-pass filtering and 8 simultaneous 18-bit SAR ADC channels. This is useful for this project because one device can acquire all the LF or HF outputs of one zone.

#figure(
  image("../img/system_diagram.png", width: 95%),
  caption: [Final acquisition system block diagram.]
)

The same structure is repeated for the 10 zones of the array. Therefore, the complete system uses 20 AD7606C-18 converters: 10 for the HF outputs and 10 for the LF outputs. All ADCs are connected to the Artix-7 FPGA.

The FPGA controls the acquisition, synchronizes the ADCs and receives the digital data. Finally, the data are sent to a PC through a digital communication interface, where they can be stored and visualized.