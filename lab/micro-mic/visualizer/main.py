import socket
import struct
import sys
import time

import numpy as np
import pyqtgraph as pg
from PyQt6.QtCore import Qt, QTimer
from PyQt6.QtWidgets import (
    QApplication,
    QCheckBox,
    QComboBox,
    QDoubleSpinBox,
    QFormLayout,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QMainWindow,
    QPushButton,
    QSpinBox,
    QSplitter,
    QVBoxLayout,
    QWidget,
)
from pyqtgraph.dockarea import Dock, DockArea

UDP_IP = "127.0.0.1"
UDP_PORT = 5002


class Visualizer(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Micro-Mic Keysight-Style Oscilloscope")
        self.resize(1400, 900)

        # Socket
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.bind((UDP_IP, UDP_PORT))
        self.sock.setblocking(False)

        # Core data buffers (1 million samples = 10k seconds at 100Hz)
        self.buffer_size = 1000000
        self.samples = np.zeros(self.buffer_size)
        self.data_ch0 = np.zeros(self.buffer_size)
        self.data_ch1 = np.zeros(self.buffer_size)
        self.data_ch2 = np.zeros(self.buffer_size)
        self.data_clock = np.zeros(self.buffer_size)
        self.data_duty = np.zeros(self.buffer_size)
        self.idx = 0
        self.sample_count = 0

        # Audio buffers
        self.audio_buffer_size = 1000000
        self.data_audio = np.zeros(self.audio_buffer_size)
        self.audio_idx = 0
        self.audio_packet_count = 0
        self.last_vref = 3300.0

        # Stats & Display variables
        self.last_fps_time = time.time()
        self.packet_count = 0
        self.last_trigger_idx = -1
        self.last_plot_time = time.time()
        self.last_sample_period = 10.0  # Default 10ms

        self.setup_ui()

        # Update timer
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_data)
        self.timer.start(16)  # ~60 FPS

        # Stats timer
        self.stats_timer = QTimer()
        self.stats_timer.timeout.connect(self.update_stats)
        self.stats_timer.start(500)

    def setup_ui(self):
        self.area = DockArea()
        self.setCentralWidget(self.area)

        # Docks
        self.dock_ctrl = Dock("Control Panel", size=(300, 600))
        self.dock_time = Dock("Time Domain (Oscilloscope)", size=(800, 300))
        self.dock_audio = Dock("Audio Waveform", size=(800, 200))
        self.dock_fft = Dock("Frequency Domain (FFT)", size=(800, 300))
        self.dock_clock = Dock("PA0 Clock Monitor", size=(800, 200))

        self.area.addDock(self.dock_ctrl, "left")
        self.area.addDock(self.dock_time, "right", self.dock_ctrl)
        self.area.addDock(self.dock_audio, "bottom", self.dock_time)
        self.area.addDock(self.dock_fft, "bottom", self.dock_audio)
        self.area.addDock(self.dock_clock, "bottom", self.dock_fft)

        self.setup_ctrl_dock()
        self.setup_time_dock()
        self.setup_audio_dock()
        self.setup_fft_dock()
        self.setup_clock_dock()

    def setup_ctrl_dock(self):
        w = QWidget()
        layout = QVBoxLayout(w)

        # Horizontal
        grp_horiz = QGroupBox("Horizontal (Time)")
        form_horiz = QFormLayout(grp_horiz)
        self.combo_time_div = QComboBox()
        self.combo_time_div.addItems(
            [
                "10 ms/div",
                "20 ms/div",
                "50 ms/div",
                "100 ms/div",
                "200 ms/div",
                "500 ms/div",
                "1 s/div",
                "2 s/div",
                "5 s/div",
                "10 s/div",
            ]
        )
        self.combo_time_div.setCurrentText("1 s/div")  # 10s total screen
        form_horiz.addRow("Time Base:", self.combo_time_div)

        self.chk_pause = QCheckBox("Run / Stop (Pause)")
        form_horiz.addRow("", self.chk_pause)
        layout.addWidget(grp_horiz)

        # Trigger Config
        grp_trig = QGroupBox("Trigger")
        form_trig = QFormLayout(grp_trig)
        self.combo_trig_mode = QComboBox()
        self.combo_trig_mode.addItems(["Roll Mode (Free Run)", "Auto", "Normal"])
        self.combo_trig_mode.setCurrentIndex(1)  # Auto by default

        self.combo_trig_ch = QComboBox()
        self.combo_trig_ch.addItems(["Ch 0 (PA3)", "Ch 1 (PC0)", "Ch 2 (PC3)"])

        self.combo_trig_edge = QComboBox()
        self.combo_trig_edge.addItems(["Rising", "Falling"])

        self.spin_trig_lvl = QDoubleSpinBox()
        self.spin_trig_lvl.setRange(0.0, 3.3)
        self.spin_trig_lvl.setSingleStep(0.1)
        self.spin_trig_lvl.setValue(1.5)

        form_trig.addRow("Mode:", self.combo_trig_mode)
        form_trig.addRow("Source:", self.combo_trig_ch)
        form_trig.addRow("Edge:", self.combo_trig_edge)
        form_trig.addRow("Level (V):", self.spin_trig_lvl)
        layout.addWidget(grp_trig)

        # FFT Config
        grp_fft = QGroupBox("Math / FFT")
        form_fft = QFormLayout(grp_fft)
        self.combo_fft_ch = QComboBox()
        self.combo_fft_ch.addItems(["Ch 0", "Ch 1", "Ch 2", "Audio"])

        self.combo_fft_win = QComboBox()
        self.combo_fft_win.addItems(["Hanning", "Hamming", "Blackman", "Rectangular"])

        form_fft.addRow("Source:", self.combo_fft_ch)
        form_fft.addRow("Window:", self.combo_fft_win)
        layout.addWidget(grp_fft)

        # Stats
        grp_stats = QGroupBox("Real-Time Measurements")
        form_stats = QFormLayout(grp_stats)
        self.lbl_pkts = QLabel("0 pps")
        self.lbl_clock = QLabel("0 Hz")
        self.lbl_duty = QLabel("0.0 %")
        self.lbl_audio_pkts = QLabel("0 pps")
        self.lbl_ch0_mean = QLabel("0.0 V")
        self.lbl_ch1_mean = QLabel("0.0 V")
        self.lbl_ch2_mean = QLabel("0.0 V")

        form_stats.addRow("Packet Rate:", self.lbl_pkts)
        form_stats.addRow("PA0 Clock Freq:", self.lbl_clock)
        form_stats.addRow("PA0 Duty Cycle:", self.lbl_duty)
        form_stats.addRow("Audio Packet Rate:", self.lbl_audio_pkts)
        form_stats.addRow("Ch 0 Mean:", self.lbl_ch0_mean)
        form_stats.addRow("Ch 1 Mean:", self.lbl_ch1_mean)
        form_stats.addRow("Ch 2 Mean:", self.lbl_ch2_mean)
        layout.addWidget(grp_stats)

        layout.addStretch()
        self.dock_ctrl.addWidget(w)

    def setup_time_dock(self):
        self.plot_time = pg.PlotWidget()
        self.plot_time.setLabel("left", "Voltage", units="V")
        self.plot_time.setLabel("bottom", "Time", units="s")
        self.plot_time.showGrid(x=True, y=True, alpha=0.5)
        self.plot_time.addLegend(offset=(10, 10))
        self.plot_time.setYRange(0, 3.4)

        # Keysight style: X axis is locked to the Time Base knob. User can only zoom/pan Y-axis.
        self.plot_time.setMouseEnabled(x=False, y=True)

        self.curve_ch0 = self.plot_time.plot(pen=pg.mkPen("y", width=2), name="Ch 0")
        self.curve_ch1 = self.plot_time.plot(pen=pg.mkPen("c", width=2), name="Ch 1")
        self.curve_ch2 = self.plot_time.plot(pen=pg.mkPen("m", width=2), name="Ch 2")

        # Vertical trigger marker line
        self.trigger_line = pg.InfiniteLine(
            angle=90, movable=False, pen=pg.mkPen("r", style=Qt.PenStyle.DashLine)
        )
        self.plot_time.addItem(self.trigger_line)
        self.dock_time.addWidget(self.plot_time)

    def setup_audio_dock(self):
        self.plot_audio = pg.PlotWidget()
        self.plot_audio.setLabel("left", "Voltage", units="V")
        self.plot_audio.setLabel("bottom", "Time", units="s")
        self.plot_audio.showGrid(x=True, y=True, alpha=0.5)
        self.plot_audio.setMouseEnabled(x=False, y=True)
        self.plot_audio.setYRange(0, 3.4)

        self.curve_audio = self.plot_audio.plot(pen=pg.mkPen("w", width=1), name="Audio (PC0)")
        self.dock_audio.addWidget(self.plot_audio)

    def setup_fft_dock(self):
        self.plot_fft = pg.PlotWidget()
        self.plot_fft.setLabel("left", "Magnitude", units="dB")
        self.plot_fft.setLabel("bottom", "Frequency", units="Hz")
        self.plot_fft.showGrid(x=True, y=True, alpha=0.5)
        self.plot_fft.setMouseEnabled(x=True, y=True)

        self.curve_fft = self.plot_fft.plot(pen=pg.mkPen("y", width=1.5), name="FFT")
        self.dock_fft.addWidget(self.plot_fft)

    def setup_clock_dock(self):
        self.dock_clock.setTitle("PA0 Clock Monitor")
        
        self.plot_clk = pg.PlotWidget()
        self.plot_clk.setLabel("left", "Frequency", units="Hz")
        self.plot_clk.showGrid(x=True, y=True, alpha=0.5)
        self.plot_clk.setMouseEnabled(x=False, y=True)
        self.curve_clk = self.plot_clk.plot(pen=pg.mkPen("g", width=2), name="Clock")

        self.plot_duty = pg.PlotWidget()
        self.plot_duty.setLabel("left", "Duty Cycle", units="%")
        self.plot_duty.setLabel("bottom", "Time", units="s")
        self.plot_duty.setYRange(0, 100)
        self.plot_duty.showGrid(x=True, y=True, alpha=0.5)
        self.plot_duty.setMouseEnabled(x=False, y=True)
        self.curve_duty = self.plot_duty.plot(pen=pg.mkPen("c", width=2), name="Duty Cycle")
        
        self.plot_duty.setXLink(self.plot_clk)

        splitter = QSplitter(Qt.Orientation.Vertical)
        splitter.addWidget(self.plot_clk)
        splitter.addWidget(self.plot_duty)
        self.dock_clock.addWidget(splitter)

    def _get_ch_data(self, ch_idx):
        if ch_idx == 0:
            return self.data_ch0
        if ch_idx == 1:
            return self.data_ch1
        return self.data_ch2

    def find_trigger(self, search_start, search_end, pre_trig, post_trig):
        start = max(pre_trig, search_start)
        end = search_end - post_trig

        if end <= start:
            return -1

        data = self._get_ch_data(self.combo_trig_ch.currentIndex())
        lvl = self.spin_trig_lvl.value()
        rising = self.combo_trig_edge.currentIndex() == 0

        chunk_prev = data[start - 1 : end - 1]
        chunk_curr = data[start:end]

        if rising:
            edges = np.where((chunk_prev < lvl) & (chunk_curr >= lvl))[0]
        else:
            edges = np.where((chunk_prev > lvl) & (chunk_curr <= lvl))[0]

        if len(edges) > 0:
            return start + edges[-1]  # Return the most recent trigger in the buffer
        return -1

    def get_time_div_seconds(self):
        txt = self.combo_time_div.currentText()
        val, unit = txt.split(" ")
        time_div = float(val)
        if "ms" in unit:
            return time_div / 1000.0
        return time_div

    def update_data(self):
        if self.chk_pause.isChecked():
            # Flush socket to prevent OS buffer overflow while paused
            try:
                while True:
                    self.sock.recvfrom(4096)
            except BlockingIOError:
                pass
            return

        pkts = 0
        new_data = False
        new_audio_data = False
        prev_idx = self.idx

        # Batch read UDP
        while pkts < 10000:
            try:
                data, addr = self.sock.recvfrom(2048)
                if len(data) >= 56 and data[:4] == b"MMIC":
                    unpacked = struct.unpack("<4s B x H I I H H H B B I H H I I I I H B B 4x", data[:56])

                    raw0 = unpacked[5]
                    raw1 = unpacked[6]
                    raw2 = unpacked[7]
                    vrefMv = unpacked[11]
                    self.last_vref = vrefMv
                    self.last_sample_period = unpacked[12]
                    
                    pa0_freq = unpacked[13]
                    pa0_duty = unpacked[17] / 100.0

                    self.samples[self.idx] = self.sample_count
                    self.data_ch0[self.idx] = (raw0 * vrefMv) / 65535000.0
                    self.data_ch1[self.idx] = (raw1 * vrefMv) / 65535000.0
                    self.data_ch2[self.idx] = (raw2 * vrefMv) / 65535000.0
                    self.data_clock[self.idx] = pa0_freq
                    self.data_duty[self.idx] = pa0_duty

                    self.idx += 1
                    self.sample_count += 1
                    self.packet_count += 1
                    new_data = True

                    # Ring buffer wrap
                    if self.idx >= self.buffer_size:
                        shift = self.buffer_size // 2
                        self.samples[:-shift] = self.samples[shift:]
                        self.data_ch0[:-shift] = self.data_ch0[shift:]
                        self.data_ch1[:-shift] = self.data_ch1[shift:]
                        self.data_ch2[:-shift] = self.data_ch2[shift:]
                        self.data_clock[:-shift] = self.data_clock[shift:]
                        self.data_duty[:-shift] = self.data_duty[shift:]
                        self.idx -= shift
                        prev_idx = max(0, prev_idx - shift)
                        self.last_trigger_idx -= shift

                elif len(data) >= 544 and data[:4] == b"MAUD":
                    unpacked = struct.unpack("<4s B B H I I Q I B B H 256H", data[:544])
                    audio_samples = unpacked[11:]
                    
                    volts = (np.array(audio_samples) * self.last_vref) / 65535000.0
                    n_samp = len(volts)
                    
                    if self.audio_idx + n_samp > self.audio_buffer_size:
                        shift = self.audio_buffer_size // 2
                        self.data_audio[:-shift] = self.data_audio[shift:]
                        self.audio_idx -= shift
                        
                    self.data_audio[self.audio_idx : self.audio_idx + n_samp] = volts
                    self.audio_idx += n_samp
                    
                    self.audio_packet_count += 1
                    new_audio_data = True

            except BlockingIOError:
                break
            except Exception as e:
                break
            pkts += 1

        if (not new_data and not new_audio_data) or (self.idx == 0 and self.audio_idx == 0):
            return

        # Calculate time properties
        dt = self.last_sample_period / 1000.0 if self.last_sample_period > 0 else 0.01
        time_div_s = self.get_time_div_seconds()
        total_time_s = time_div_s * 10.0  # 10 divisions on screen

        win_samples = int(total_time_s / dt)
        if win_samples < 10:
            win_samples = 10
        if win_samples > self.buffer_size:
            win_samples = self.buffer_size

        post_trig = win_samples // 2
        pre_trig = win_samples - post_trig

        trig_mode = self.combo_trig_mode.currentIndex()
        now = time.time()
        plot_start = -1
        plot_end = -1

        # 1. Determine plot range based on mode
        if trig_mode == 0:  # Roll Mode (Free Run)
            plot_end = self.idx
            plot_start = max(0, plot_end - win_samples)
            self.trigger_line.hide()
            self.plot_time.setXRange(-total_time_s, 0, padding=0)
            self.plot_clk.setXRange(-total_time_s, 0, padding=0)
            self.plot_duty.setXRange(-total_time_s, 0, padding=0)

        else:  # Auto or Normal Triggered Sweep
            self.trigger_line.show()
            self.plot_time.setXRange(-total_time_s / 2, total_time_s / 2, padding=0)
            self.plot_clk.setXRange(-total_time_s / 2, total_time_s / 2, padding=0)
            self.plot_duty.setXRange(-total_time_s / 2, total_time_s / 2, padding=0)

            search_start = max(pre_trig, prev_idx - win_samples)
            trig_idx = self.find_trigger(search_start, self.idx, pre_trig, post_trig)

            if trig_idx != -1:
                self.last_trigger_idx = trig_idx
                self.last_plot_time = now
                plot_start = trig_idx - pre_trig
                plot_end = trig_idx + post_trig
            else:
                if trig_mode == 1 and (now - self.last_plot_time > 0.1):
                    # Auto mode: force sweep if no trigger in 100ms
                    plot_end = self.idx
                    plot_start = max(0, plot_end - win_samples)
                    self.last_plot_time = now
                elif trig_mode == 2:
                    # Normal mode: hold the last valid triggered sweep
                    if (
                        self.last_trigger_idx != -1
                        and self.last_trigger_idx + post_trig <= self.idx
                    ):
                        plot_start = self.last_trigger_idx - pre_trig
                        plot_end = self.last_trigger_idx + post_trig

        # 2. Extract and Plot Data
        if plot_start != -1 and plot_end != -1 and plot_end > plot_start:
            actual_samples = plot_end - plot_start

            if trig_mode == 0:  # Roll Mode: time ends at 0
                x = (np.arange(actual_samples) - actual_samples) * dt
            else:  # Triggered Mode: time revolves around pre_trig (0s)
                # If we don't have full history at startup, pre_trig is clamped
                effective_pre_trig = min(pre_trig, actual_samples)
                x = (np.arange(actual_samples) - effective_pre_trig) * dt

            y0 = self.data_ch0[plot_start:plot_end]
            y1 = self.data_ch1[plot_start:plot_end]
            y2 = self.data_ch2[plot_start:plot_end]
            yc = self.data_clock[plot_start:plot_end]
            yd = self.data_duty[plot_start:plot_end]

            self.curve_ch0.setData(x, y0)
            self.curve_ch1.setData(x, y1)
            self.curve_ch2.setData(x, y2)
            self.curve_clk.setData(x, yc)
            self.curve_duty.setData(x, yd)

        if new_audio_data and self.audio_idx > 0:
            audio_win_samples = int(total_time_s / 0.00001)
            if audio_win_samples > self.audio_buffer_size:
                audio_win_samples = self.audio_buffer_size
                
            audio_start = max(0, self.audio_idx - audio_win_samples)
            actual_audio_samples = self.audio_idx - audio_start
            
            x_audio = (np.arange(actual_audio_samples) - actual_audio_samples) * 0.00001
            y_audio = self.data_audio[audio_start : self.audio_idx]
            
            self.curve_audio.setData(x_audio, y_audio)
            self.plot_audio.setXRange(-total_time_s, 0, padding=0)

        # 3. Update FFT
        fft_ch_idx = self.combo_fft_ch.currentIndex()
        if fft_ch_idx == 3:
            if self.audio_idx > 0:
                audio_win_samples = int(total_time_s / 0.00001)
                audio_start = max(0, self.audio_idx - min(audio_win_samples, self.audio_buffer_size))
                y_fft = self.data_audio[audio_start : self.audio_idx]
                fs = 100000.0
            else:
                y_fft = []
                fs = 100000.0
        else:
            if plot_start != -1 and plot_end != -1 and plot_end > plot_start:
                if fft_ch_idx == 0: y_fft = y0
                elif fft_ch_idx == 1: y_fft = y1
                else: y_fft = y2
                fs = (1000.0 / self.last_sample_period if self.last_sample_period > 0 else 100.0)
            else:
                y_fft = []
                fs = 100.0

        if len(y_fft) > 10:
            y_fft = y_fft - np.mean(y_fft)  # Remove DC

            win_type = self.combo_fft_win.currentIndex()
            if win_type == 0:
                window = np.hanning(len(y_fft))
            elif win_type == 1:
                window = np.hamming(len(y_fft))
            elif win_type == 2:
                window = np.blackman(len(y_fft))
            else:
                window = np.ones(len(y_fft))

            fft_vals = np.fft.rfft(y_fft * window)
            fft_mag = 20 * np.log10(np.abs(fft_vals) + 1e-9)

            xf = np.fft.rfftfreq(len(y_fft), 1.0 / fs)
            self.curve_fft.setData(xf, fft_mag)

            color = "y" if fft_ch_idx == 0 else ("c" if fft_ch_idx == 1 else ("m" if fft_ch_idx == 2 else "w"))
            self.curve_fft.setPen(pg.mkPen(color, width=1.5))

    def update_stats(self):
        now = time.time()
        dt = now - self.last_fps_time
        if dt > 0:
            pps = self.packet_count / dt
            self.lbl_pkts.setText(f"{pps:.1f} pps")
            audio_pps = self.audio_packet_count / dt
            self.lbl_audio_pkts.setText(f"{audio_pps:.1f} pps")
        self.packet_count = 0
        self.audio_packet_count = 0
        self.last_fps_time = now

        if self.idx > 0:
            win_size = min(1000, self.idx)
            start = self.idx - win_size

            clock_val = np.mean(self.data_clock[start : self.idx])
            self.lbl_clock.setText(
                f"{clock_val / 1e6:.3f} MHz"
                if clock_val > 100000
                else f"{clock_val:.0f} Hz"
            )

            duty_val = np.mean(self.data_duty[start : self.idx])
            self.lbl_duty.setText(f"{duty_val:.1f} %")

            self.lbl_ch0_mean.setText(
                f"{np.mean(self.data_ch0[start : self.idx]):.3f} V"
            )
            self.lbl_ch1_mean.setText(
                f"{np.mean(self.data_ch1[start : self.idx]):.3f} V"
            )
            self.lbl_ch2_mean.setText(
                f"{np.mean(self.data_ch2[start : self.idx]):.3f} V"
            )


if __name__ == "__main__":
    app = QApplication(sys.argv)
    pg.setConfigOptions(antialias=False)
    win = Visualizer()
    win.show()
    sys.exit(app.exec())
