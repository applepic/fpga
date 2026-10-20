# Course index

> A step-by-step course from zero to RV32I. **Every lesson has a runnable task.
> When you finish one, I set questions. You only advance after passing.**

The order is not organised by topic. It is organised by **what blocks you next**.

## Progress

| Lesson | Topic | Status | Exercise |
|---|---|---|---|
| 1 | What Verilog describes: `wire` / `assign` / bitwise ops | **in progress** | `examples/00_gates` |
| 2 | Clocks and `always`: combinational to sequential | not started | to be built |
| 3 | Counters: why `reg` is not a register | not started | `examples/01_counter` |
| 4 | Formal verification: `assert` / `assume`, and what a proof gives you | not started | `examples/04_formal` |
| 5 | Clock dividers: 27 MHz down to 1 Hz | not started | to be built |
| 6 | State machines: button-driven marquee | not started | to be built |
| 7 | UART transmit: talking to the PC | not started | to be built |
| 8 | UART receive and button debouncing | not started | to be built |
| 9 | Memory: how a `reg` array becomes BSRAM | not started | to be built |
| 10 | RV32I 1: instruction encoding and fetch | not started | to be built |
| 11 | RV32I 2: decode and immediates | not started | to be built |
| 12 | RV32I 3: ALU and register file | not started | to be built |
| 13 | RV32I 4: memory access and branches | not started | to be built |
| 14 | RV32I 5: full-system integration | not started | to be built |

## How a lesson works

1. **Read the lesson `.md`**. About 20 minutes.
2. **Write the code**, then run `.\scripts\sim.ps1 -Project examples/NN_name`.
3. **Stuck for more than 30 minutes? Ask.** Before asking, state what you tried and what error you saw.
4. **When it passes, tell me.** I set questions. **You do not declare your own pass.**
5. After you pass, I mark the lesson complete and build the next one.

## Why every lesson ends with questions

Your known failure mode is treating "I have seen this" as "I have mastered this".
Reading an explanation and feeling that it makes sense is a different thing from writing it from scratch.

The questions ask **why**, not just "write the code". For example, Lesson 1 will ask you why
`~` and `!` cannot be used interchangeably in hardware.

## Relationship to `LEARNING.md`

`LEARNING.md` is the **route**: phases A, B, C, each with acceptance criteria.
This directory is the **course**: how you actually walk that route.

The route says "phase A means you can write sequential logic".
The course says "Lesson 2 covers `always`, Lesson 3 is a counter".

## Relationship to `examples/`

One lesson maps to one directory: `lessons/NN_xxx.md` ↔ `examples/NN_xxx/`.

Each directory contains `sim/tb_*.v` (the acceptance criteria, **do not modify**) and `README.md`.
`rtl/` is empty **on purpose**, and you fill it in.
