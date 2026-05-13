= Introduction and project objective

In this project, we design an instrumentation system for aero-acoustic measurements. The system is based on MEMS microphone arrays and is intended to be used in wind tunnel and flight test applications.

The complete array has 80 MEMS microphones. Each microphone has two outputs: one for the low-frequency band and one for the high-frequency band. So the system has to acquire 160 analog signals in total.

To make the design easier, the array is divided into 10 zones. Each zone with 8 MEMS microphones and the electronics needed to acquire both frequency bands.

The main parts of the system are the analog front-end, the AD7606C-18 integrated circuit, the Artix-7 FPGA, the power supply stage and the software used to store and visualize the data.
