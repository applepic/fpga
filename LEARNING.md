---
status: in progress
last_updated: 2026-10-18
---

# FPGA learning route (condensed)

> Goal: learn FPGA design with Verilog from zero, ending with an RV32I processor core
> you can implement independently.
> Board: **Tang Nano 9K** (GW1NR-LV9QN88PC6/I5, 8640 LUT4, 27 MHz on-board oscillator)
>
> **Revised 2026-10-18**: the original route had one step (FIFO) standing in front of RV32I
> that RV32I does not actually need. It moved behind RV32I. Reasoning at the end of this file.
>
> **This file is the route. For the actual sequence of lessons, see [lessons/README.md](lessons/README.md).**

## Three phases

| Phase | Content | Acceptance |
|---|---|---|
| **A. Write sequential logic** | `wire`/`assign`, `always @(posedge clk)`, reset, clock division, counters, state machines | Counter + divider + button-driven marquee, all with simulation evidence |
| **B. Talk to the outside world** | UART transmit, UART receive, button debouncing | Board sends a string to the PC; PC sends a character and the board displays it |
| **C. RV32I** | Single-cycle core, see [SPEC.md](SPEC.md) | The 40-encoding test program (38 implemented behaviours) runs, UART output matches simulation |

**Every phase is signed off by me setting questions.** Your known failure mode is treating
"seen it" as "mastered it", so you do not get to declare your own pass.
Tell me when you finish a phase and I will set the questions.

## Environment

All commands run from the repo root (`C:\Local_Data\Dev\fpga`).

```powershell
. .\env.ps1                                          # the leading dot is required
.\scripts\sim.ps1   -Project examples/00_gates       # simulate
.\scripts\build.ps1 -Project examples/00_gates       # synthesise, place and route, build .fs
.\scripts\flash.ps1 -Project examples/00_gates       # program SRAM (lost on power cycle)
.\scripts\flash.ps1 -Project examples/00_gates -Flash  # program Flash (persists)
```

**The leading dot on `env.ps1` is not optional.** Without dot-sourcing, the PATH change only
applies to a child process, and the next command cannot find the tools.
That is a PowerShell rule, not our convention.

### Directory layout

```
fpga/
├── env.ps1                    toolchain environment
├── constraints/tangnano9k.cst pin assignments for the whole board (shared by all projects)
├── scripts/                   build / sim / flash
├── infra/toolchain_smoke/     toolchain self-test, not learning material
├── lessons/                   course text, one .md per lesson
├── examples/                  exercises, one directory per lesson
│   └── NN_name/
│       ├── rtl/*.v            design (you fill this in)
│       ├── sim/tb_*.v         testbench (acceptance criteria, do not modify)
│       └── build/             artifacts (not in git)
└── rv32i/                     phase C
```

One exercise is one directory. `rtl/` holds the design, `sim/` holds the testbench,
`build/` is generated and git-ignored.

### Three toolchain traps (all hit for real, all fixed in the scripts)

1. **Adding only `bin\` to PATH crashes the tools.** yosys / nextpnr / openFPGALoader depend on
   DLLs in the sibling `lib\` directory. Without them the exit code is `-1073741515` (0xC0000135)
   and there is **no error message at all**. iverilog happens not to need them, so it runs fine
   and misleads you into thinking the toolchain is healthy. `env.ps1` adds `lib\` as well.
2. **`--cst` is not a nextpnr option.** Constraints go in as `--vopt cst=xxx.cst`,
   and GW1N-9 additionally requires `--vopt family=GW1N-9C`, otherwise it reports
   `For the GW1N-9 series you need to specify --vopt family=`.
3. **`--report` writes JSON, not a text report.** Reading Fmax and utilisation requires `ConvertFrom-Json`.

## Resources: three, with different jobs

| Resource | Role | How to use it |
|---|---|---|
| [Gisselquist's 10 lessons](https://zipcpu.com/tutorial/) | **Main line** | Work through in order; each lesson has downloadable examples |
| Readler, *Verilog by Example* (114 pages) | **Syntax reference** | Look up the relevant chapter when stuck. **Do not read cover to cover** |
| [Sipeed Wiki](https://wiki.sipeed.com/hardware/zh/tang/Tang-Nano-9K/Nano-9K.html) | **Board-specific** | Only when you touch hardware |

Why split this way: Gisselquist binds language, tooling and debugging together, which is exactly
where self-learners fall through. Readler is pure syntax, and reading it alone tends to produce
"I understood it but I cannot write it".

## Phase A: write sequential logic

**What you do**: get clear on how code becomes a circuit.

**Resources**: Gisselquist L01 (wires), L02 (registers and blinky), L03 (FSM); Readler chapters 2, 3, 4

**Acceptance** (all require simulation evidence):

1. 4-bit binary counter, 0 through 15 and back to 0
2. 27 MHz to 1 Hz divider so an LED blinks once per second
3. Button-driven marquee: each press advances one position, and **one press advances exactly one**
   (no debouncing yet; that comes in phase B)
4. Verbal explanation: why `reg` is not a register, and how `always @(*)` differs from `always @(posedge clk)`

**A concrete trap**: simulating 27 MHz down to 1 Hz requires 27 million clock cycles, and the
waveform file becomes too large to open. **Scale the divisor down for simulation** (say, to 27)
and restore the real value before going to hardware. That is standard practice, not cheating.

## Phase B: talk to the outside world

**What you do**: get the board and the PC exchanging data.

**Resources**: Gisselquist L05 / L06 / L09 (UART transmit and receive), L07 (button debouncing)

**Acceptance**:

1. **Transmit**: the board sends `hello` every 0.5 s and the PC serial terminal receives it
2. **Receive**: the PC sends one character; the board displays its ASCII code on the six LEDs
3. **Debouncing**: simulation proves that mechanical bounce (a burst of fast transitions) triggers only once

**Fix the serial parameters at 115200 8N1.** RV32I will rely on this link to report results,
so get it stable now.

**Wiring**: the on-board BL702 already exposes USB-UART. `uart_tx` = pin 17, `uart_rx` = pin 18.
Plug in USB and a COM port appears in Device Manager.

## Phase C: RV32I

Specification in [SPEC.md](SPEC.md). Requires phases A and B to be complete.

## Why the order changed (2026-10-18)

The original phase 3 was "buttons + Block RAM + UART + FIFO", requiring FIFO to work before RV32I.
The problem: **the first version of RV32I does not need a FIFO.**

- A FIFO is not needed for a first RV32I, because instruction and data memory can be a plain
  `reg [31:0] mem[0:N]` array
- UART is transmit-only in this phase (dumping results out), so it needs no FIFO either
- A FIFO becomes genuinely useful when you buffer both directions on the UART, or when you build
  a pipelined design with an instruction queue. That is second-round work

**So FIFO moved from "prerequisite" to "optional, after phase C".** This is not a lowered bar.
It removes a step that blocked the goal without the goal needing it.

Block RAM is the same story: you will use it naturally in phase C (as instruction memory),
and learning it there gives you a reason. Learning "a memory block" in the abstract now does not.

### Correction 2026-10-28: a combinational read does NOT become BSRAM

This section used to claim that `assign dout = mem[addr]` (a combinational read) is placed in
BSRAM by the synthesis tool, and that this is why a single-cycle core needs no hand-written
memory. **The second half is false.** Measured on this board, `synth_gowin` + `nextpnr-himbaechel`,
2026-10-28:

| Memory | Read | Result |
|---|---|---|
| 256 x 32, address from a **register** | combinational | BSRAM, 16 LUT4, Fmax 224 MHz |
| 256 x 32, address from an **ALU expression** | combinational | **no BSRAM**: 354 LUT4, Fmax 98 MHz |
| 512 x 32, ALU address | combinational | **no BSRAM**: 1211 LUT4 (14% of the chip), Fmax 138 MHz |
| 1024 x 32, ALU address | combinational | **place and route fails**: `Unable to find legal placement for cell mem.0.1 of type RAM16SDP4` |
| 1024 x 32, ALU address | **registered** | BSRAM, 10 LUT4, Fmax 272 MHz |

The pattern: **BSRAM inference requires the read address to come from a register.**
A single-cycle core computes the load address with the ALU in the same cycle it needs the data,
so its data memory is exactly the failing case. The instruction memory is fine, because the PC
is a register, which is why the instruction memory row above infers BSRAM at 1024 words.

Consequences for phase C, none of them fatal but all of them real:

1. **The data memory has to be small.** 256 words (1 KB) costs 524 LUT4, 6% of the chip.
   That is affordable. 1024 words is not, and does not even place.
2. **The load path is the critical path.** 98 MHz for a 256-word memory against a 27 MHz clock
   leaves about 3.6x headroom, which is enough, but it is the number to watch in phase D.
3. **The cheap fix is a registered read**, which turns the load into a two-cycle operation and
   costs a stall. That is a real design change, not a detail, so it is a phase C decision to make
   deliberately, not something to discover at integration time.

The FIFO demotion itself still stands: a `reg` array is still enough, it is just a **LUT** array
at the sizes a single-cycle core can afford. What was wrong was the reason, not the conclusion.

The lesson: "the synthesis tool will infer BSRAM" is a claim about a specific code shape, and the
shape that infers BSRAM is narrower than it looks. Verify it with `stat`, do not assume it.

## On simulation: use it from day one

Gisselquist uses Verilator and also teaches SymbiYosys formal verification.
**Do not skip simulation and go straight to hardware.**

The reason is practical: debugging on the board gives you only LEDs and a serial port, and every
change costs tens of seconds of synthesis and place-and-route. In simulation you can inspect any
signal at any moment, and a one-line change reruns in a second. Every acceptance item in phases A
and B demands simulation evidence specifically to build that habit.

**This repo standardises on iverilog** (easier to start with; you can ignore Gisselquist's Verilator
setup). Verilator is installed, but its perl wrapper does not run on this Windows machine; only
`verilator_bin.exe` works directly. Revisit if you need more speed.

## How to use this route

1. **Advance by phase, not by week.** If a phase's acceptance criteria are unmet, do not start the next one
2. **Ask me to set questions at the end of each phase.** You do not grade yourself
3. **Stuck for more than 30 minutes? Look at example code.** Do not grind. That wastes time
4. Time budget follows the measured values in `ai-profile/profile/personal.md`:
   **2 to 3 blocks per day, 2.5 to 3 hours per block**

## Reference files

- Book: `docs/Verilog-by-Example_Readler-2011.pdf` (6 MB, not in git)
- Specification: [SPEC.md](SPEC.md)
- Change history: [LOG.md](LOG.md)
