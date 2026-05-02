= Data handling and acquisition strategy

== Design objective

== Acquisition architecture

== ADC-to-FPGA interface
=== Number of ADC devices and channels
=== Digital interface configuration
=== FPGA I/O requirements

== Sampling and synchronization
=== Common conversion trigger
=== Clocking strategy
=== External trigger support
=== Timing coherence across the array

== FPGA data pipeline
=== ADC readout controller
=== Channel mapping
=== Timestamping and sample counters
=== FIFO buffering
=== Status and error flags

== Frame format
=== Frame structure
=== Channel ordering
=== Metadata fields
=== CRC and integrity checks

== Data rate estimation
=== Raw data rate
=== Packed data rate
=== Interface bandwidth margin

== Output interface to the acquisition PC
=== USB 3.0 FIFO bridge option
=== Ethernet option
=== Selected interface

== PC-side acquisition software
=== Configuration and control
=== Real-time monitoring
=== Data storage format
=== Metadata and calibration data

== Preliminary design conclusion