# Micro-Mic Ethernet Telemetry

This workspace has two active parts:

- `firmware/`: STM32H755 M7 RTIC firmware.
- `frontend/`: PC UDP bridge and browser dashboard.

The firmware streams ADC telemetry to a PC over direct Ethernet.

## Network

- MCU static IP: `192.168.88.99/24`
- PC static IP for the direct link: `192.168.88.2/24`
- Telemetry destination: `192.168.88.2:5001` UDP unicast to the PC
- MCU UDP source port: `5000`
- PC UDP telemetry port: `5001`
- Dashboard HTTP port: `8080`

Configure the PC Ethernet interface connected to the board as `192.168.88.2/24`.

## Signals

- `PA8`: 2.2 MHz PWM clock output from `TIM1_CH1`
- `PA3`: analog input 0
- `PC0`: analog input 1
- `PC3`: analog input 2
- `PC13`: digital input included in the telemetry packet
- `PB0`: link/status LED
- Ethernet RMII TX: `PG11` TX_EN, `PG13` TXD0, `PB13` TXD1

Analog inputs must stay within the MCU ADC input range.

## Commands

Enter the shell:

```sh
nix develop
```

Useful commands:

```sh
micro-check
micro-run
micro-ui
sudo micro-net-up
micro-net-status
```

Open the dashboard at `http://127.0.0.1:8080` after running `micro-ui`.

`micro-ui` sends a small UDP keepalive from port `5001` to the MCU. This keeps
the direct link's ARP/firewall state warm on hosts that block unsolicited UDP.
