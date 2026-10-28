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
- **A five-stage pipelined implementation** that is architecturally identical to the single-cycle
  one (phase D, see "Architecture direction")
- A reproducible simulation flow, not "it looked right on the board"
- Synthesis, place and route, and programming all working end to end

> **Instruction count (corrected 2026-10-28).** The RISC-V spec says "RV32I contains 40 unique
> instructions" ([ISA manual](https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html)).
> Earlier versions of this file said 37, which silently drops `FENCE`, `ECALL` and `EBREAK`.
> The spec also notes that a minimal implementation may implement `FENCE` as a NOP and cover
> `ECALL`/`EBREAK` with one always-trapping SYSTEM instruction, which is 38. **Version one of this
> core will do exactly that**: implement `FENCE` as a NOP and make `ECALL`/`EBREAK` halt the core
> and report over UART. So the working target is **40 encodings, 38 implementations**.
> What must not happen is calling a 37-instruction subset "the full base RV32I".

> **"Compiled" means compiled (2026-10-28).** The phrase "a compiled bare-metal program" was
> previously contradicted by open question 3, which ruled out a cross compiler. Hand-assembled
> machine code is not a compiled program. **Resolved: install a RISC-V cross compiler before
> lesson 10.** Chosen toolchain is `riscv-none-elf-gcc` from
> [xpack-dev-tools](https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases)
> (standalone Windows binary, no MSYS2 or WSL needed, nothing to build from source).
> Installation is deliberately **deferred until lesson 10 starts**, not done now, so the
> dependency does not sit unused for months before phase C. Until then, hand-written machine code
> remains the phase C test method; the compiled-program requirement is what closes phase C.

**Explicitly out of scope (version one)**
- No M / A / F / D extensions, no privileged mode, no interrupts or exceptions
- No caches, no MMU
- No multi-core
- No dynamic branch prediction. Phase D fetches sequentially and flushes; prediction is later work
- No CSR file. `ECALL` / `EBREAK` / any unsupported encoding halts the core and reports the
  encoding over UART. **That behaviour boundary is part of the specification**, not an oversight

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

## Architecture direction (decided 2026-10-28)

### Step one: single cycle

Start with a single-cycle implementation. The debugging cost is lowest because each instruction's
behaviour can be confirmed independently in the waveform.

**Changed 2026-10-28**: this used to say "decide about pipelining only after the single-cycle
version works", which left the endpoint undefined. The endpoint is now **phase D, a five-stage
pipeline**. The single-cycle core is not a detour, it is the oracle phase D is checked against.
What changed is the goal, not the order.

**A limit found by measurement on 2026-10-28**: the data memory cannot be read combinationally at
a useful size. BSRAM inference requires the read address to come from a register, and a
single-cycle core computes its load address with the ALU in the same cycle. Measured on this
board: 256 words costs 524 LUT4 and reaches 98 MHz; 1024 words **fails place and route**. The
instruction memory is unaffected because the PC is a register. Consequences and the full table are
in `LEARNING.md` under "Correction 2026-10-28". **Phase C therefore has to choose deliberately
between a small data memory (256 words or less) and a registered read costing a one-cycle stall.**
This choice is made at lesson 9, not discovered at integration.

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

## Phase D: five-stage pipeline (added 2026-10-28)

**Why it is in scope.** The user's stated endpoint is "write a pipelined core from the ground".
Version one was defined as single-cycle only, which made the resume line ("32-bit 5-stage
pipelined RISC-V CPU") false. Phase D is what makes it true. An Astra review on 2026-10-28
accepted the direction and rejected parts of the original justification; the accepted version is
below, the rejected parts are recorded in the vault at `01_Projects/FPGA/FPGA-Route-Review-2026-10-28.md`.

### Stage split

Five stages: `IF` / `ID` / `EX` / `MEM` / `WB`.

**The stage boundaries are not decided by the longest path alone.** They are decided by three
constraints together, which is why lesson 15 comes before any pipeline register is written:

1. the critical path measured from the single-cycle core's timing report
2. **memory timing**: the data memory needs a registered read to reach BSRAM (see above), so `MEM`
   is where that register lands, and the load result is not available until the end of `MEM`
3. **the forwarding path**: the path from `EX` output back to `EX` input is the one that usually
   becomes critical after pipelining, and it constrains how much logic fits in one stage

### Hazard handling (version one)

| Hazard | Handling |
|---|---|
| Data RAW, ALU result | forward from `EX/MEM` and `MEM/WB` to `EX` |
| Load-use | one-cycle stall. **Not** "the only hazard forwarding cannot fix" as an assumption; verify at lesson 19 |
| Control, branch | resolve in `EX`, flush `IF` and `ID` |
| Control, `JAL`/`JALR` | resolve in `ID`, flush `IF` only |
| Store data | forwarded separately from the load path; the store data hazard is not the same as the load hazard |
| Register file same-cycle read/write | write in the first half, read in the second, or bypass in the register file. Decide at lesson 15 |

**Flushed instructions must not produce write side effects.** A `store` in a flushed slot must not
write memory, and a flushed instruction must not commit to the register file. This is an explicit
acceptance item, because it is the classic pipeline bug that simulation with "nice" programs misses.

### Control signals that do not exist in a single-cycle core

`valid` per stage, `bubble` insertion, and a defined priority between `stall` and `flush`
(flush wins, or the flushed instruction commits). This gets its own lesson (20) because it is
where most pipeline debugging time actually goes.

### Verification: lockstep against phase C

The final register file alone is **not** an acceptable comparison. Errors get overwritten by later
instructions, and a wrong `store` never shows up in a register at all. The lockstep harness
compares, per retired instruction:

| Field | Why |
|---|---|
| PC | confirms the same instruction stream |
| instruction word | catches a fetch/decode divergence |
| next PC | catches a control-flow divergence at the instruction that caused it |
| register write (index + data + enable) | catches a writeback divergence |
| memory address, byte mask, read data, write data | catches load/store divergence, which registers cannot see |

This is the same information set as [RVFI](https://yosyshq.net/yosyshq.net/riscv-formal/rvfi.html),
without adopting the full riscv-formal framework. The two cores do **not** need cycle-level
synchronisation; they need the same input events in the same order, and a stall timeout so a
deadlock is reported rather than hanging.

**The lockstep harness is built at lesson 16, before the hazard lessons**, not after. Building it
afterwards means the first dozen pipeline bugs are debugged by waveform, which is the expensive way.

### Acceptance for phase D

All four, or phase D is not done:

1. the same test programs produce **identical retired-instruction traces** on both cores
2. every hazard class has a test program that actually triggers it (verified by counting the
   stalls and flushes, not by inspection)
3. it runs on the board and the UART output matches simulation
4. the timing report shows the target frequency met, with the report kept as evidence

**Then stop.** Chasing Fmax beyond the target and formal refinement proofs are explicitly out of
scope for phase D; the review recommended a stop line and it is adopted here.

> **What phase D does not give you.** A lockstep comparison is test evidence, not a proof.
> A refinement proof would additionally need a state mapping between the two implementations,
> environment assumptions, and a progress argument. That is research work, tracked separately in
> the vault's long-term plan, not part of this project's definition of done.

## Open questions

> **All four are settled as of 2026-10-28.** Kept as a record of what was decided and why.

1. ~~Single cycle first, or pipelined straight away?~~ → **Both, in that order.** Single cycle is
   phase C and the oracle; the five-stage pipeline is phase D. Settled 2026-10-28
2. ~~Which simulator?~~ → **iverilog.** Verilator's perl wrapper does not run on this Windows machine;
   only `verilator_bin.exe` works directly. There is no speed requirement yet, so standardising on
   iverilog removes one variable
3. ~~Use an existing instruction test suite?~~ → **No riscv-tests, but yes to a cross compiler.**
   Hand-writing machine code for the 40 encodings is itself the process of understanding instruction
   encoding, so phase C keeps doing that. **But the goal line says "a compiled bare-metal program",
   and hand-assembled code does not satisfy it.** `riscv-none-elf-gcc` gets installed at the start
   of lesson 10 (see "Compiled means compiled" above). Phase D additionally wants a small assembler
   for its dependency-heavy test programs; that is settled when phase D starts
4. ~~What is the acceptance criterion for step one?~~ → **Phase C**: the 40-encoding test program
   runs in simulation with correct final state, and a compiled C program prints over UART.
   **Phase D**: identical retired-instruction traces against phase C, all hazard classes triggered,
   board output matching simulation, timing met. Settled 2026-10-28

> The board model was confirmed on 2026-10-12.
> "Single cycle or pipelined" was listed under "confirm before changing" in AGENTS.md; it was
> confirmed with the user on 2026-10-28, and this file now records both phases as in scope.

## Boundaries and principles

- **Make it work, then optimise.** Performance, area and power are second-round concerns
- **Every module must be simulatable on its own.** A module that cannot be tested alone is too coupled and needs splitting
- **Keep constraints separate from RTL.** Swapping boards touches only `constraints/`
- **Simulation and hardware must produce consistent evidence.** "It should be fine" is not acceptable
