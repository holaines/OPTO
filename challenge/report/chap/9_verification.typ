= Requirement verification and final conclusions
== Verification of requirements

The proposed system theoretically satisfies the main requirements of the project. The complete array uses 80 dual-frequency MEMS microphones, so the system must acquire 160 analog signals. This is achieved by dividing the array into 10 equal zones, with 8 MEMS microphones per zone.

Each zone uses two AD7606C-18 integrated circuits: one for the 8 LF outputs and one for the 8 HF outputs. As a result, the complete system uses 20 AD7606C-18 devices. Since each device has 8 simultaneous sampling channels, the 160 outputs can be acquired without external analog multiplexers. The LF and HF branches are kept separated, and the proposed sampling rates are compatible with the required frequency bands.

The power requirement is also considered, because the system can be supplied from a 28 V aircraft bus or from a 24 V battery. The proposed power architecture separates the analog and digital supplies, which is important to reduce noise in the MEMS front-end and ADC stage.

The most critical requirement is the wide acoustic dynamic range. For this reason, the AD7606C-18 must be used together with a calibrated analog front-end, including low-noise amplification, gain or attenuation selection, protection and filtering.

== Final conclusions

The AD7606C-18 is one of the key parts of the design. It is not only an ADC, but a complete acquisition block with 8 simultaneous 18-bit channels, programmable input ranges, PGA, filtering and digital interface. This makes the zone-based architecture simpler and avoids the use of external multiplexers.

The main limitation of the system is the FPGA. It has to control the 20 ADCs, synchronize the acquisition, read the digital data, add timestamps, buffer the stream and send it to the PC. For this reason, the FPGA I/O count, readout timing and output data rate are the main bottlenecks of the design.

In summary, the proposed architecture is coherent with the project requirements. The design provides a modular solution for acquiring the 160 MEMS outputs using 10 acquisition zones, simultaneous ADC sampling and centralized FPGA control. However, since this is a preliminary design, the final performance should be verified experimentally, especially the analog dynamic range, the FPGA pin and data-rate margin, and the physical integration of the 20 AD7606C-18 devices on the PCB.