const dgram = require("dgram");
const http = require("http");

const UDP_PORT = Number(process.env.MICRO_UDP_PORT || 5001);
const MCU_IP = process.env.MICRO_MCU_IP || "192.168.88.99";
const MCU_UDP_PORT = Number(process.env.MICRO_MCU_UDP_PORT || 5000);
const HTTP_PORT = Number(process.env.MICRO_HTTP_PORT || 8080);
const KEEPALIVE = Buffer.from("MMIC_HELLO");

let latestSample = null;
let packetCount = 0;
let lastPacketAt = 0;

function parseTelemetry(buffer, remote) {
  if (buffer.length < 32 || buffer.toString("ascii", 0, 4) !== "MMIC") {
    return null;
  }

  const packetLength = buffer.readUInt16LE(6);
  if (packetLength > buffer.length) {
    return null;
  }

  const raw = [
    buffer.readUInt16LE(16),
    buffer.readUInt16LE(18),
    buffer.readUInt16LE(20),
  ];
  const vrefMv = buffer.readUInt16LE(28);
  const voltages = raw.map((value) => (value * vrefMv) / 65535);

  return {
    version: buffer.readUInt8(4),
    sequence: buffer.readUInt32LE(8),
    timeMs: buffer.readUInt32LE(12),
    raw,
    voltages,
    digital: Boolean(buffer.readUInt8(22)),
    linkUp: Boolean(buffer.readUInt8(23)),
    clockHz: buffer.readUInt32LE(24),
    vrefMv,
    samplePeriodMs: buffer.readUInt16LE(30),
    receivedAt: Date.now(),
    remote: `${remote.address}:${remote.port}`,
  };
}

const udp = dgram.createSocket("udp4");
let keepaliveErrorLogged = false;

const forwardSocket = dgram.createSocket("udp4");
const FORWARD_PORT = 5002;

udp.on("message", (message, remote) => {
  // Forward raw telemetry to the Python visualizer
  forwardSocket.send(message, 0, message.length, FORWARD_PORT, "127.0.0.1");

  const sample = parseTelemetry(message, remote);
  if (!sample) {
    return;
  }

  packetCount += 1;
  lastPacketAt = Date.now();
  latestSample = {
    ...sample,
    packetCount,
  };

  if (packetCount === 1 || packetCount % 1000 === 0) {
    const volts = sample.voltages.map((value) => (value / 1000).toFixed(3));
    console.log(
      `telemetry #${packetCount} seq=${sample.sequence} adc=${volts.join(",")}V from ${sample.remote}`,
    );
  }
});

function sendKeepalive() {
  udp.send(KEEPALIVE, MCU_UDP_PORT, MCU_IP, (error) => {
    if (error && !keepaliveErrorLogged) {
      keepaliveErrorLogged = true;
      console.error(`UDP keepalive failed: ${error.message}`);
    }
  });
}

udp.bind(UDP_PORT, "0.0.0.0", () => {
  console.log(`UDP telemetry listening on 0.0.0.0:${UDP_PORT}`);
  console.log(`Sending keepalive to ${MCU_IP}:${MCU_UDP_PORT}`);
  sendKeepalive();
  setInterval(sendKeepalive, 1000);
});

const server = http.createServer((request, response) => {
  if (request.url === "/metrics") {
    response.writeHead(200, {
      "Content-Type": "text/plain; version=0.0.4",
      "Cache-Control": "no-store",
    });

    let metrics = "";
    metrics += `# HELP micro_mic_telemetry_packets_total Total telemetry packets received\n`;
    metrics += `# TYPE micro_mic_telemetry_packets_total counter\n`;
    metrics += `micro_mic_telemetry_packets_total ${packetCount}\n`;

    if (latestSample) {
      metrics += `# HELP micro_mic_voltage Voltage from ADC\n`;
      metrics += `# TYPE micro_mic_voltage gauge\n`;
      metrics += `micro_mic_voltage{channel="0"} ${latestSample.voltages[0] / 1000.0}\n`;
      metrics += `micro_mic_voltage{channel="1"} ${latestSample.voltages[1] / 1000.0}\n`;
      metrics += `micro_mic_voltage{channel="2"} ${latestSample.voltages[2] / 1000.0}\n`;

      metrics += `# HELP micro_mic_raw_adc Raw ADC values\n`;
      metrics += `# TYPE micro_mic_raw_adc gauge\n`;
      metrics += `micro_mic_raw_adc{channel="0"} ${latestSample.raw[0]}\n`;
      metrics += `micro_mic_raw_adc{channel="1"} ${latestSample.raw[1]}\n`;
      metrics += `micro_mic_raw_adc{channel="2"} ${latestSample.raw[2]}\n`;

      metrics += `# HELP micro_mic_digital Digital pin status\n`;
      metrics += `# TYPE micro_mic_digital gauge\n`;
      metrics += `micro_mic_digital ${latestSample.digital ? 1 : 0}\n`;

      metrics += `# HELP micro_mic_link_up Link up status\n`;
      metrics += `# TYPE micro_mic_link_up gauge\n`;
      metrics += `micro_mic_link_up ${latestSample.linkUp ? 1 : 0}\n`;

      metrics += `# HELP micro_mic_clock_hz Clock frequency\n`;
      metrics += `# TYPE micro_mic_clock_hz gauge\n`;
      metrics += `micro_mic_clock_hz ${latestSample.clockHz}\n`;

      metrics += `# HELP micro_mic_vref_mv Vref in mV\n`;
      metrics += `# TYPE micro_mic_vref_mv gauge\n`;
      metrics += `micro_mic_vref_mv ${latestSample.vrefMv}\n`;

      metrics += `# HELP micro_mic_sample_period_ms Sample period in ms\n`;
      metrics += `# TYPE micro_mic_sample_period_ms gauge\n`;
      metrics += `micro_mic_sample_period_ms ${latestSample.samplePeriodMs}\n`;
    }

    response.end(metrics);
    return;
  }

  if (request.url === "/api/status") {
    response.writeHead(200, {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
    });
    response.end(
      JSON.stringify({
        udpPort: UDP_PORT,
        httpPort: HTTP_PORT,
        packetCount,
        lastPacketAt,
        latestSample,
      }),
    );
    return;
  }

  response.writeHead(404);
  response.end("Not found. Use /metrics for Prometheus metrics.");
});

server.listen(HTTP_PORT, "0.0.0.0", () => {
  console.log(
    `Prometheus metrics available at http://0.0.0.0:${HTTP_PORT}/metrics`,
  );
});
