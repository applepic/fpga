# FPGA Projects

Learning FPGA from zero, ending with a Verilog RV32I processor core running on a **Tang Nano 9K**.

> **Status (2026-10-18): toolchain working and verified. Learning phase; no RTL written by the user yet.**
> Course index: [lessons/README.md](lessons/README.md). Route: [LEARNING.md](LEARNING.md).

## Start here

**Begin with [Lesson 1](lessons/01_verilog_basics.md).** Do not jump to RV32I.

The course runs one lesson at a time. Each lesson has an exercise directory:
`sim/` holds the testbench (the acceptance criteria, do not modify), and `rtl/` is empty for you to fill in.

```powershell
cd C:\Local_Data\Dev\fpga
. .\env.ps1
.\scripts\sim.ps1 -Project examples/00_gates
```

It reports `Unknown module type` right now. That is the starting point.

## Environment

**Run `. .\env.ps1` once per new terminal** (the leading dot is required).

| Command | What it does |
|---|---|
| `.\scripts\sim.ps1 -Project <dir>` | iverilog simulation, writes `build/tb.vcd` |
| `.\scripts\sim.ps1 -Project <dir> -Open` | Same, then opens gtkwave on the waveform |
| `.\scripts\build.ps1 -Project <dir>` | Synthesis + place and route + `build/top.fs` |
| `.\scripts\flash.ps1 -Project <dir>` | Program SRAM (lost on power cycle) |
| `.\scripts\flash.ps1 -Project <dir> -Flash` | Program Flash (persists) |

**Self-test**: `.\scripts\sim.ps1 -Project infra/toolchain_smoke` and
`.\scripts\build.ps1 -Project infra/toolchain_smoke` should both pass.
If either fails, the toolchain is broken. Do not continue learning until it is fixed.

Toolchain lives in `C:\Local_Data\oss-cad-suite`, version `20260518`:
iverilog 14.0 / yosys 0.65 / nextpnr 0.10 / openFPGALoader 1.1.1 / gtkwave.

## Board

**Sipeed Tang Nano 9K**

| Item | Value |
|---|---|
| FPGA | GW1NR-LV9QN88PC6/I5 |
| Logic cells | 8640 LUT4 |
| Flip-flops | 6480 FF |
| Block RAM | 26 BSRAM, 468K bits total |
| On-board storage | 32 Mbit SPI Flash, 64 Mbit PSRAM |
| Clock | 27 MHz crystal |
| Buttons | 2 user buttons (pins 4 and 3, active low) |
| LEDs | 6 (pins 10/11/13/14/15/16, **active low**) |
| Debugger | On-board BL702, USB-JTAG + USB-UART (TX=17, RX=18) |
| Display | HDMI, RGB LCD, SPI LCD |

All pin assignments live in `constraints/tangnano9k.cst`; sources and verification date are in the file header.

> **Device name trap**: the datasheet says `GW1NR-LV9QN88PC6/I5`,
> while the Gowin IDE wants `GW1NR-UV9QN88C6/I5`.
> The open-source toolchain uses the datasheet name, and additionally requires `--vopt family=GW1N-9C`.

## Documents

| File | Contents |
|---|---|
| [lessons/README.md](lessons/README.md) | **Course index and progress table.** How to walk the route |
| [lessons/01_verilog_basics.md](lessons/01_verilog_basics.md) | **Lesson 1**: `wire` / `assign` / bitwise ops / simulation |
| [LEARNING.md](LEARNING.md) | **Route.** Three phases, acceptance criteria per phase, toolchain traps |
| [SPEC.md](SPEC.md) | RV32I scope and open questions |
| [AGENTS.md](AGENTS.md) | Instructions for AI agents working in this repo |
| [LOG.md](LOG.md) / [LOG-INDEX.md](LOG-INDEX.md) | Change history |
| `docs/` | Reference book, not in git |

> **Route vs course**: `LEARNING.md` says "phase A means you can write sequential logic".
> `lessons/` says "Lesson 2 covers `always`, Lesson 3 is a counter". One is the goal, the other is the path.

## References

- [Gisselquist's Verilog tutorial](https://zipcpu.com/tutorial/), 10 lessons, from C basics to UART
- Readler, *Verilog by Example*, 114 pages of syntax reference, in `docs/`
- [Sipeed Wiki](https://wiki.sipeed.com/hardware/zh/tang/Tang-Nano-9K/Nano-9K.html), everything about the board and toolchain
