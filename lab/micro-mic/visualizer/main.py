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
    QFormLayout,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QMainWindow,
    QPushButton,
    QSpinBox,
    QVBoxLayout,
    QWidget,
)
from pyqtgraph.dockarea import Dock, DockArea

UDP_IP = "127.0.0.1"
UDP_PORT = 5002


class Visualizer(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Micro-Mic Advanced Oscilloscope")
        self.resize(1400, 900)

        # Socket
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.bind((UDP_IP, UDP_PORT))
        self.sock.setblocking(False)

        # Core data buffers
        self.buffer_size = 100000
        self.samples = np.zeros(self.buffer_size)
        self.data_ch0 = np.zeros(self.buffer_size)
        self.data_ch1 = np.zeros(self.buffer_size)
        self.data_ch2 = np.zeros(self.buffer_size)
        self.data_clock = np.zeros(self.buffer_size)
        self.idx = 0
        self.sample_count = 0
        self.last_fps_time = time.time()
        self.packet_count = 0

        self.setup_ui()

        # Update timer
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_data)
        self.timer.start(16)  # ~60 FPS

        # Stats timer
        self.stats_timer = QTimer()
        self.stats_timer.timeout.connect(self.update_stats)
        self.stats_timer.start(500)

        # Screenshot timer
        QTimer.singleShot(5000, self.take_screenshot)

    def setup_ui(self):
        self.area = DockArea()
        self.setCentralWidget(self.area)

        # Docks
        self.dock_ctrl = Dock("Control & Stats", size=(300, 200))
        self.dock_time = Dock("Time Domain (Oscilloscope)", size=(800, 400))
        self.dock_fft = Dock("Frequency Domain (FFT)", size=(800, 400))
        self.dock_clock = Dock("Clock Monitor", size=(800, 200))

        self.area.addDock(self.dock_ctrl, "left")
        self.area.addDock(self.dock_time, "right", self.dock_ctrl)
        self.area.addDock(self.dock_fft, "bottom", self.dock_time)
        self.area.addDock(self.dock_clock, "bottom", self.dock_fft)

        self.setup_ctrl_dock()
        self.setup_time_dock()
        self.setup_fft_dock()
        self.setup_clock_dock()

    def setup_ctrl_dock(self):
        w = QWidget()
        layout = QVBoxLayout(w)

        # Controls
        ctrl_group = QGroupBox("Configuration")
        form = QFormLayout(ctrl_group)

        self.spin_window = QSpinBox()
        self.spin_window.setRange(100, self.buffer_size)
        self.spin_window.setSingleStep(1000)
        self.spin_window.setValue(5000)
        form.addRow("Display Window (samples):", self.spin_window)

        self.chk_pause = QCheckBox("Pause Visualization")
        form.addRow("", self.chk_pause)

        layout.addWidget(ctrl_group)

        # Stats
        stats_group = QGroupBox("Real-Time Stats")
        stats_layout = QFormLayout(stats_group)
        self.lbl_pkts = QLabel("0 pps")
        self.lbl_clock = QLabel("0 Hz")
        self.lbl_ch0_mean = QLabel("0.0 V")
        self.lbl_ch1_mean = QLabel("0.0 V")
        self.lbl_ch2_mean = QLabel("0.0 V")

        stats_layout.addRow("Packet Rate:", self.lbl_pkts)
        stats_layout.addRow("Clock (PC0):", self.lbl_clock)
        stats_layout.addRow("Ch0 (PA3) Mean:", self.lbl_ch0_mean)
        stats_layout.addRow("Ch1 Mean:", self.lbl_ch1_mean)
        stats_layout.addRow("Ch2 Mean:", self.lbl_ch2_mean)

        layout.addWidget(stats_group)
        layout.addStretch()
        self.dock_ctrl.addWidget(w)

    def setup_time_dock(self):
        self.plot_time = pg.PlotWidget()
        self.plot_time.setLabel("left", "Voltage", units="V")
        self.plot_time.setLabel("bottom", "Samples")
        self.plot_time.showGrid(x=True, y=True, alpha=0.3)
        self.plot_time.addLegend()
        self.plot_time.setYRange(0, 3.4)

        self.curve_ch0 = self.plot_time.plot(
            pen=pg.mkPen("y", width=1.5), name="Ch 0 (PA3)"
        )
        self.curve_ch1 = self.plot_time.plot(pen=pg.mkPen("c", width=1.5), name="Ch 1")
        self.curve_ch2 = self.plot_time.plot(pen=pg.mkPen("m", width=1.5), name="Ch 2")
        self.dock_time.addWidget(self.plot_time)

    def setup_fft_dock(self):
        self.plot_fft = pg.PlotWidget()
        self.plot_fft.setLabel("left", "Magnitude", units="dB")
        self.plot_fft.setLabel("bottom", "Frequency", units="Hz")
        self.plot_fft.showGrid(x=True, y=True, alpha=0.3)

        self.curve_fft = self.plot_fft.plot(
            pen=pg.mkPen("y", width=1.5), name="Ch 0 FFT"
        )
        self.dock_fft.addWidget(self.plot_fft)

    def setup_clock_dock(self):
        self.plot_clk = pg.PlotWidget()
        self.plot_clk.setLabel("left", "Frequency", units="Hz")
        self.plot_clk.setLabel("bottom", "Samples")
        self.plot_clk.showGrid(x=True, y=True, alpha=0.3)

        self.curve_clk = self.plot_clk.plot(
            pen=pg.mkPen("g", width=2), name="Clock (PC0)"
        )
        self.dock_clock.addWidget(self.plot_clk)

    def take_screenshot(self):
        try:
            pixmap = self.grab()
            pixmap.save("screenshot.png")
            print("Screenshot successfully saved to screenshot.png")
        except Exception as e:
            print("Screenshot failed:", e)

    def update_data(self):
        if self.chk_pause.isChecked():
            try:
                while True:
                    self.sock.recvfrom(2048)
            except BlockingIOError:
                pass
            return

        pkts = 0
        updated = False
        while pkts < 10000:
            try:
                data, addr = self.sock.recvfrom(2048)
                if len(data) >= 32 and data[:4] == b"MMIC":
                    # Bug fixed: added variables for each index carefully since x padding drops in python unpack
                    unpacked = struct.unpack("<4s B x H I I H H H B B I H H", data[:32])

                    timeMs = unpacked[4]
                    raw0 = unpacked[5]
                    raw1 = unpacked[6]
                    raw2 = unpacked[7]
                    clockHz = unpacked[10]
                    vrefMv = unpacked[11]
                    samplePeriodMs = unpacked[12]

                    v0 = (raw0 * vrefMv) / 65535000.0
                    v1 = (raw1 * vrefMv) / 65535000.0
                    v2 = (raw2 * vrefMv) / 65535000.0

                    self.samples[self.idx] = self.sample_count
                    self.data_ch0[self.idx] = v0
                    self.data_ch1[self.idx] = v1
                    self.data_ch2[self.idx] = v2
                    self.data_clock[self.idx] = clockHz

                    self.idx += 1
                    self.sample_count += 1
                    self.packet_count += 1
                    updated = True

                    if self.idx >= self.buffer_size:
                        shift = self.buffer_size // 2
                        self.samples[:-shift] = self.samples[shift:]
                        self.data_ch0[:-shift] = self.data_ch0[shift:]
                        self.data_ch1[:-shift] = self.data_ch1[shift:]
                        self.data_ch2[:-shift] = self.data_ch2[shift:]
                        self.data_clock[:-shift] = self.data_clock[shift:]
                        self.idx -= shift

            except BlockingIOError:
                break
            except Exception as e:
                break
            pkts += 1

        if updated and self.idx > 0:
            win_size = self.spin_window.value()
            start = max(0, self.idx - win_size)

            x = self.samples[start : self.idx]
            self.curve_ch0.setData(x, self.data_ch0[start : self.idx])
            self.curve_ch1.setData(x, self.data_ch1[start : self.idx])
            self.curve_ch2.setData(x, self.data_ch2[start : self.idx])
            self.curve_clk.setData(x, self.data_clock[start : self.idx])

            # Update FFT for CH0
            if len(x) > 100:
                y = self.data_ch0[start : self.idx]
                y = y - np.mean(y)  # Remove DC offset
                window = np.hanning(len(y))
                fft_vals = np.fft.rfft(y * window)
                fft_mag = 20 * np.log10(np.abs(fft_vals) + 1e-9)

                # Estimate Fs from firmware samplePeriodMs (if 0, default to 1kHz)
                fs = 1000.0 if samplePeriodMs == 0 else 1000.0 / samplePeriodMs
                xf = np.fft.rfftfreq(len(y), 1.0 / fs)
                self.curve_fft.setData(xf, fft_mag)

    def update_stats(self):
        now = time.time()
        dt = now - self.last_fps_time
        if dt > 0:
            pps = self.packet_count / dt
            self.lbl_pkts.setText(f"{pps:.1f} pps")
        self.packet_count = 0
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
