---
status: planning, no code yet
last_updated: 2026-10-18
---

# SPEC — RV32I processor core

> **This file is a plan, not a statement of fact.** The project contains no RTL yet.
> Read it once before starting, and settle the "Open questions" section with the user first.

## Prerequisites

The user is learning FPGA from zero, so this project is **not the first step**.
Complete phases A and B in [LEARNING.md](LEARNING.md) first:

| Phase | Content | Pass condition |
|---|---|---|
| A | Sequential logic | Counter + clock divider + button-driven marquee, waveforms correct |
| B | Communication | UART transmit and receive working both ways, debouncing proven in simulation |

**Changed 2026-10-18**: the original prerequisite was "phases 0 through 3", which listed FIFO and
Block RAM as hard requirements. On review, a single-cycle RV32I does not need a hand-written FIFO
(memories synthesise into BSRAM from a plain `reg` array), so FIFO moved to optional work after
phase C. Reasoning in "Why the order changed" in `LEARNING.md`.

**Do not start until A and B are complete.** Skipping them and writing RV32I directly is running a
marathon before you can walk.

## Goal

Implement an RV32I processor core in Verilog and run it on the Tang Nano 9K.

**In scope**
- Full base RV32I instruction set (**40 instructions**, see the count note below), able to run a
  compiled bare-metal program

> **Instruction count (corrected 2026-10-28).** The RISC-V spec says "RV32I contains 40 unique
> instructions" ([ISA manual](https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html)).
> Earlier versions of this file said 37, which silently drops `FENCE`, `ECALL` and `EBREAK`.
> The spec also notes that a minimal implementation may implement `FENCE` as a NOP and cover
> `ECALL`/`EBREAK` with one always-trapping SYSTEM instruction, which is 38. **Version one of this
> core will do exactly that**: implement `FENCE` as a NOP and make `ECALL`/`EBREAK` halt the core
> and report over UART. So the working target is **40 encodings, 38 implementations**.
> What must not happen is calling a 37-instruction subset "the full base RV32I".
- A reproducible simulation flow, not "it looked right on the board"
- Synthesis, place and route, and programming all working end to end

**Explicitly out of scope (version one)**
- No M / A / F / D extensions, no privileged mode, no interrupts or exceptions
- No caches, no MMU
- No multi-core

Get the minimal loop working first, then discuss extensions.

## Technology choices

| Item | Choice | Status |
|---|---|---|
| Target board | **Tang Nano 9K** (GW1NR-LV9QN88PC6/I5) | Confirmed by user 2026-10-12 |
| Board resources | 8640 LUT4 / 6480 FF / 26 BSRAM (468K bits) / 32 Mbit Flash / 64 Mbit PSRAM | Verified |
| Clock | 27 MHz on-board oscillator | Verified |
| Debugger | On-board BL702, provides USB-JTAG and USB-UART | Verified |
| Language | Verilog | Decided |
| Simulation | iverilog | Decided 2026-10-18, see open questions |
| Synthesis / place and route | yosys + nextpnr-himbaechel (`--device GW1NR-LV9QN88PC6/I5`) | Available |
| Programming | openFPGALoader | Available |
| Vendor IDE | Gowin EDA (for cross-checking) | Installed |

Toolchain lives in `C:\Local_Data\oss-cad-suite`, version `20260518`.

> **Device name trap**: the datasheet says `GW1NR-LV9QN88PC6/I5`,
> but the Gowin IDE expects `GW1NR-UV9QN88C6/I5`.

## Architecture direction (tentative)

### Step one: single cycle

Start with a single-cycle implementation. The debugging cost is lowest because each instruction's
behaviour can be confirmed independently in the waveform. Decide about pipelining only after the
single-cycle version works.

Module breakdown (tentative):

```
rv32i/
├── rtl/
│   ├── rv32i_core.v     top level, wires the modules together
│   ├── pc.v             program counter
│   ├── ifetch.v         instruction fetch (straight to instruction memory, no cache)
│   ├── decode.v         decode and immediate generation
│   ├── regfile.v        32 x 32 register file
│   ├── alu.v            arithmetic logic unit
│   ├── lsu.v            memory access (load / store)
│   └── control.v        control signal generation
├── sim/
│   ├── tb_core.v        testbench
│   └── programs/        test assembly and machine code
└── README.md            how to run it
```

**Constraints and scripts do not live under `rv32i/`.** The repo-level `constraints/tangnano9k.cst`
and `scripts/` apply to every project, and `build.ps1 -Project rv32i` finds them automatically.
That keeps the "swap the board by editing one directory" principle from "Boundaries and principles".

### Verification strategy

Three layers. Missing any one means not done:

1. **Unit simulation**: each module has its own testbench covering boundary cases
2. **Instruction-level simulation**: a test program covering all 40 encodings (38 implemented
   behaviours), comparing final register values
3. **On the board**: after synthesis and programming, output results over UART and confirm they match simulation

> What fails in simulation will not magically work on the board.

**A fourth layer exists and is optional: formal proofs with `sby`.** It does not replace any of the
three above. It covers a different question: simulation asks whether the inputs you chose behave,
a proof asks whether any input sequence can break the property. Lesson 4 introduces it on a toy
counter. Where it earns its place later is in the RV32I decode logic, where the input space is too
large to sample by hand. The flow is `scripts/formal.ps1`, which reads `formal/props_*.v` and
`rtl/*.v` from one exercise directory and writes its work to `build/formal/`.

## Open questions (settle with the user before starting)

> **Three were settled on 2026-10-18.** Only item 4 genuinely remains.

1. ~~Single cycle first, or pipelined straight away?~~ → **Single cycle.** Reasoning under "Architecture direction"
2. ~~Which simulator?~~ → **iverilog.** Verilator's perl wrapper does not run on this Windows machine;
   only `verilator_bin.exe` works directly. There is no speed requirement yet, so standardising on
   iverilog removes one variable
3. ~~Use an existing instruction test suite?~~ → **No riscv-tests.** There is no RISC-V cross compiler
   on this machine, and hand-writing machine code for the 40 encodings is itself the process of
   understanding instruction encoding, which serves the learning goal better than a benchmark score

   > **Reopened 2026-10-28, scope narrowed.** This decision holds for phase C, where one test
   > program is enough. Phase D needs a dozen small programs with deliberately dependent
   > instruction pairs, and hand-assembling those is where the time goes. A ~200-line Python
   > assembler will pay for itself there. **Do not settle it now**; settle it when phase D starts.
4. **What is the acceptance criterion for step one?** Candidate: a bare-metal program that prints
   "hello" over UART. **Decide this after phase B**, since there is not enough information now

> The board model was confirmed on 2026-10-12 and is no longer an open question.
> "Single cycle or pipelined" is also listed under "confirm before changing" in AGENTS.md;
> the conclusion here is single cycle, which stays within the "out of scope" boundary in this file.

## Boundaries and principles

- **Make it work, then optimise.** Performance, area and power are second-round concerns
- **Every module must be simulatable on its own.** A module that cannot be tested alone is too coupled and needs splitting
- **Keep constraints separate from RTL.** Swapping boards touches only `constraints/`
- **Simulation and hardware must produce consistent evidence.** "It should be fine" is not acceptable
