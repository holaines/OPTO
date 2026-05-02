= PC Visualizer Frontend

The PC Visualizer acts as the central hub for the Micro-Mic oscilloscope, providing a high-performance, real-time graphical interface built on Python and PyQtGraph. It receives combined `MMIC` and `MAUD` UDP streams and reconstructs them into a unified, cross-domain visual layout.

== Architecture & Dynamic Memory Management
To maintain high frame rates while handling hundreds of thousands of samples per second, the visualizer leverages efficient NumPy ring buffers. Instead of hardcoding arrays for each potential audio source, the system employs Dynamic Buffer Allocation. 

When a `MAUD` packet arrives, the visualizer dynamically extracts the `channel_id` and the `sample_rate_hz` from the packet header. If the channel is unseen (e.g., the newly introduced digital PDM stream on SPI1), the software automatically instantiates a new 1,000,000-sample high-speed buffer for it. This allows the system to scale to an arbitrary number of audio streams without code modifications, keeping the memory footprint proportional strictly to the active streams.

== Universal Trigger Engine
We implemented a Universal Trigger Engine that performs mathematically precise cross-domain time synchronization.

When a trigger event (such as a rising edge passing $1.65"V"$) is detected in the high-speed 200 kHz audio array, the engine calculates the exact physical timestamp of that event relative to the current buffer head. This relative time offset is then mathematically projected backwards into the low-speed 100 Hz telemetry arrays. The result is that all traces—whether sampled at 100 Hz or 200 kHz—are plotted on the screen perfectly aligned to the exact same physical instant in time.

#figure(
  image("../img/time_domain.png", width: 90%),
  caption: [Time Domain Interface demonstrating synced analog and PDM audio traces.]
)

== Time Domain Oscilloscope
The primary user interface mimics the workflow of professional Keysight oscilloscopes. The X-axis is strictly controlled by a Time Base knob (e.g., $10 "ms/div"$, $2 "ms/div"$), allowing users to zoom deep into the high-speed audio waveforms while maintaining synchronization with the slow environmental sensors.

To prevent application crashes or visual glitches during extreme zoom, the plotting engine includes strict boundary safety clamping. If the calculated trigger slice attempts to index negative regions (e.g., immediately after application startup before the buffer fills), or queries data that hasn't arrived over UDP yet, the slice is safely clamped to available bounds. 

== Frequency Domain (FFT) Analysis
To prevent the "flashing" amplitude effect typical of real-time FFTs tied to a shifting time-domain view, the FFT window size is strictly decoupled from the Time Domain zoom level.

By enforcing a user-configurable, fixed window length (defaulting to $N = 65,536$ samples), the FFT engine continuously computes over a stable $~0.32$ second history. This guarantees an ultra-high, non-fluctuating frequency resolution of roughly $3 "Hz"$ per bin regardless of the time-base scale.

#figure(
  image("../img/fft_domain.png", width: 90%),
  caption: [Simultaneous Multi-FFT overlay showing distinct frequency peaks.]
)

Furthermore, the Math panel supports Simultaneous Multi-FFT overlays, allowing the user to select any combination of active channels (e.g., `Ch 1` and `Ch 3 PDM`) and overlay their frequency spectrums in real-time on the same graph for immediate harmonic comparisons.

