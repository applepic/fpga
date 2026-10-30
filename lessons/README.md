# Course index

> **The course is now the ZipCPU beginner tutorial, ten lessons, restructured.** The self-authored
> 24-lesson sequence is retired: it was written on top of things never taught (`wire`, `reg`, the
> testbench), it explained in twenty minutes what the original explains in two slides, and on
> 2026-10-30 the user asked for the tutorial instead. His instruction is authoritative.

## Where the course comes from

| Item | Value |
|---|---|
| Source | [Verilog, Formal Verification and Verilator Beginner's Tutorial](https://zipcpu.com/tutorial/) by Daniel Gisselquist |
| Local copy | `C:\Local_Data\Dev\fpga\tutorials\zipcpu\` (PDFs, page-indexed text, example archives), git-ignored |
| Lesson files | `lessons/tutorial_NN_*.md`, English with per-paragraph Chinese |
| Vault notes he reads | `C:\Local_Data\Obsidian\01_Projects\FPGA\Tutorial-NN-*.md` |
| Exercises | `examples/tutorial/NN_<name>/` |

The vault already listed this tutorial as the course main line (`FPGA-Course`, materials table), so
this is the source he was pointing at, not a guess. It is called the ten-lesson tutorial by its own
author in the index page: "I've thought about writing another more advanced tutorial to follow these
ten lessons".

## The ten lessons

| Lesson | Source | Topic | Exercise | Status |
|---|---|---|---|---|
| 01 | `lsn-01-wires.pdf`, slides 1-51 | Wires, `assign`, module skeleton, constraints, board build | `examples/tutorial/01_wires` | **ready 2026-10-30**, not started |
| 02 | `lsn-01-wires.pdf`, slides 18-44 | Bus signals, bit select, `maskbus`, first real testbench | `examples/tutorial/02_maskbus` | **ready 2026-10-30**, not started |
| 03 | `lsn-02-regs.pdf`, slides 1-27 | Registers, `always @(posedge clk)`, latches, blocking vs non-blocking, blinky, parameters | `examples/tutorial/03_registers` | **ready 2026-10-30**, not started |
| 04 | `lsn-02-regs.pdf`, slides 28-37 | Strobe, PPS-I, PPS-II, stretch, timing checks, dimmer | `examples/tutorial/04_dividers` | **ready 2026-10-30**, not started |
| 05 | `lsn-03-fsm.pdf` | Finite state machines, LED walker | `examples/tutorial/05_fsm` | to be written |
| 06 | `lsn-04-pipeline.pdf` | Building a Wishbone slave, pipelining | `examples/tutorial/06_wishbone` | to be written |
| 07 | `lsn-05-serialtx.pdf` | Serial port transmitter, hello world | `examples/tutorial/07_serialtx` | to be written |
| 08 | `lsn-06-txdata.pdf` | Transmitting 32-bit data | `examples/tutorial/08_txdata` | to be written |
| 09 | `lsn-07-bouncing.pdf` | 2FF synchronisers and debouncing | `examples/tutorial/09_bouncing` | to be written |
| 10 | `lsn-08-memory.pdf` | FPGA block RAM | `examples/tutorial/10_memory` | to be written |
| 11 | `lsn-09-serialrx.pdf` | Serial port receiver | `examples/tutorial/11_serialrx` | to be written |
| 12 | `lsn-10-fifo.pdf` | FIFO | `examples/tutorial/12_fifo` | to be written |

> Lesson numbering follows the source, with two splits. The source's index lists ten named lessons
> after a Preface. Lesson 1 splits into 01 (board) and 02 (bus and simulation) because the halves use
> different tool chains. Lesson 2 splits into 03 (registers and blinky, slides 1-27) and 04 (clock
> dividers, timing, dimmer, slides 28-37) because the divider material needs its own lesson. The
> source's lessons 3-10 therefore become 05-12. The mapping is in the table above and in every lesson
> file's header.

## What is different from the original

1. **Tool chain.** The original uses Verilator with a C++ driver, yosys/nextpnr for iCE40. This
   project uses iverilog with Verilog testbenches (so the testbench is written in the same language
   as the design), and yosys/nextpnr-himbaechel for the Tang Nano 9K. Where the two differ in a way
   that matters, the lesson says so instead of pretending.
2. **Length.** One source lesson becomes one lesson file here, split into sections, with the slide
   text rewritten as prose. No lesson longer than the original's own slide count justifies; if a
   source lesson is 70 slides it becomes several sections, not one wall.
3. **Exercises.** Each lesson has a folder with a `README.md` and the part of the code that is his to
   write. Testbench ownership still follows the capability checkpoints below.

## Retired course

The 24-lesson sequence was written between 2026-10-18 and 2026-10-30. Files kept for reference, not
deleted, because his questions and answers live inside them:

| File | What it was |
|---|---|
| `lessons/legacy_01_verilog_basics.md` | old lesson 1, passed 2026-10-29 |
| `lessons/02_binary_arithmetic.md` | two's complement, addition, sign extension |
| `lessons/03_always_and_clocks.md` | `always`, clocks, blocking vs non-blocking, reset |
| `lessons/04_formal_refinement.md` | formal verification |
| `examples/00_gates`, `examples/02_adder`, `examples/03_clocked_rules`, `examples/01_counter`, `examples/04_formal` | their exercises |

The vault copies of those lessons stay where they are, with his questions in them. Nothing is
deleted; the tutorial is a separate path with its own numbering.

## Testbench handover

Unchanged. The four capability checkpoints (read a truth table, write expected values, design
stimulus, adjudicate a conflict) still decide who writes a testbench. The tutorial lessons use iverilog
testbenches, so checkpoint practice continues where it fits: lesson 02's `maskbus` is the first one
where he writes expectations.
