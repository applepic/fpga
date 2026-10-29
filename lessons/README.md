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
| 15 | Phase D: timing and structural decisions for a pipeline | not started | to be built |
| 16 | Phase D: the lockstep harness, built before the hazard lessons | not started | to be built |
| 17 | Phase D: pipeline registers only | not started | to be built |
| 18 | Phase D: data hazards and forwarding | not started | to be built |
| 19 | Phase D: the load-use hazard | not started | to be built |
| 20 | Phase D: `valid`, `bubble`, `stall` vs `flush` | not started | to be built |
| 21 | Phase D: control hazards and flush side effects | not started | to be built |
| 22 | Phase D: reset release, input synchronisation, clock constraints | not started | to be built |
| 23 | Phase D: stage balance and the stop line | not started | to be built |

> **Phase D (lessons 15-23) was added 2026-10-28.** The endpoint is a five-stage pipeline, and the
> single-cycle core from phase C is what it is verified against. See "Phase D" in `LEARNING.md`
> and the review record in the vault at `01_Projects/FPGA/FPGA-Route-Review-2026-10-28.md`.

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

Each directory contains a testbench under `sim/tb_*.v` and a `README.md`.
Formal exercises hold `formal/props_*.v` instead of a testbench; it is the acceptance criteria there,
under the same rule.
`rtl/` is empty **on purpose**, and you fill it in.

## Who writes the testbench: a handover schedule (2026-10-28)

**The problem this fixes.** For lessons 1 to 3 I wrote every testbench and told him not to touch it.
He then asked "tb 也不是我自己写的啊", and he was right: writing the checker is part of the skill, and
without it his only feedback is someone else's verdict. The question "how do I know whether `y_not`
depends on `a` or on `b`" comes from never having had to write down what each output must be.

**He chose a gradual handover ("我可以接受一步步来"), so the split is by lesson, not all at once.**

| Lessons | Who writes `sim/tb_*.v` | What he practices |
|---|---|---|
| 1 to 3 | **I do** (already written) | Reading a testbench and its output; learning what a checker looks like |
| 4 to 6 | **I do, then he edits it** | I ship a working testbench and leave one marked gap, e.g. a missing expected value or a missing input combination. He fills the gap and reruns |
| 7 to 9 | **He writes, I review** | Given a written spec ("these inputs, these expected outputs, print this on failure"), he writes the whole testbench. I review and run it |
| 10 onward | **He writes first, then I add a hidden one** | He writes his own testbench for the RTL. I separately keep an independent testbench he does not see, so passing his own checker is not enough |

**Why the last row matters for phase C.** If the only testbench is the one he wrote, a wrong
assumption about RV32I semantics gets baked into both the RTL and its checker, and both agree while
both are wrong. From lesson 10 on, an independent hidden testbench is what catches that. Until then
the two agree by construction, which is fine because the designs are small enough to check by eye.

**Rule for me, effective now:** when a lesson's testbench is one he is supposed to write, **do not
ship a working one under `sim/`**. Put the specification in the lesson text and in the exercise
`README.md` instead. Shipping a reference testbench and asking him to write his own is a fiction.

> 2026-10-28 记：第 1 到 3 课的测试台是我写的，他提出这不对。改成按课交接：
> 4 到 6 课我写但留一个空让他补，7 到 9 课他写我审，10 课起他自己写之外我再留一份他看不到的独立测试台，
> 防止他和他的测试台一起错。
