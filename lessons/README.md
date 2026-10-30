# Course index

> A step-by-step course from zero to RV32I. **Every lesson has a runnable task.
> When you finish one, I set questions. You only advance after passing.**

The order is not organised by topic. It is organised by **what blocks you next**.

## Renumbered on 2026-10-30

The course is now lessons 01 to 24, and the numbering is the course's own: the old lesson 1 was
kept off the new numbers because it is done, it lives at
[`legacy_01_verilog_basics.md`](legacy_01_verilog_basics.md), and `examples/00_gates` keeps its
name. The three prerequisite gaps found on 2026-10-29 are now two lessons (binary arithmetic,
testbench syntax) that sit before `always`; the proposal to renumber from 23 to 24 lessons is
approved by doing it, and the old numbers in issue-style references should be read through this
table.

| Old | New | Note |
|---|---|---|
| 1 | legacy | done 2026-10-29, file renamed |
| 2 | **03** | clocks and `always` |
| 3 | **04** | counters, `examples/01_counter` |
| 4 | **05** | formal verification, `examples/04_formal` |
| 5-14 | 06-15 | one higher |

> 2026-10-30 重新编号：旧第 1 课已完成，改名为 `legacy_01_verilog_basics.md`，不进新编号；
> 补码与加法、测试台语法各成一课插在 `always` 之前；其余课号整体后移一位。

## Progress

| Lesson | Topic | Status | Exercise |
|---|---|---|---|
| legacy | What Verilog describes: `wire` / `assign` / bitwise ops | passed 2026-10-29 | `examples/00_gates` |
| 02 | Binary arithmetic: two's complement over 8 bits, addition, subtraction, overflow, sign extension | **ready 2026-10-30**, not started | `examples/02_adder` |
| 03 | `always`, clocks, blocking vs non-blocking, reset | **ready 2026-10-30**, not started | `examples/03_clocked_rules` |
| 04 | Counters: why `reg` is not a register | not started | `examples/01_counter` |
| 05 | Formal verification: `assert` / `assume`, and what a proof gives you | not started | `examples/04_formal` |
| 06 | Clock dividers: 27 MHz down to 1 Hz | not started | to be built |
| 07 | State machines: button-driven marquee | not started | to be built |
| 08 | UART transmit: talking to the PC | not started | to be built |
| 09 | UART receive and button debouncing | not started | to be built |
| 10 | Memory: how a `reg` array becomes BSRAM | not started | to be built |
| 11 | RV32I 1: instruction encoding and fetch | not started | to be built |
| 12 | RV32I 2: decode and immediates | not started | to be built |
| 13 | RV32I 3: ALU and register file | not started | to be built |
| 14 | RV32I 4: memory access and branches | not started | to be built |
| 15 | RV32I 5: full-system integration | not started | to be built |
| 16 | Phase D: timing and structural decisions for a pipeline | not started | to be built |
| 17 | Phase D: the lockstep harness, built before the hazard lessons | not started | to be built |
| 18 | Phase D: pipeline registers only | not started | to be built |
| 19 | Phase D: data hazards and forwarding | not started | to be built |
| 20 | Phase D: the load-use hazard | not started | to be built |
| 21 | Phase D: `valid`, `bubble`, `stall` vs `flush` | not started | to be built |
| 22 | Phase D: control hazards and flush side effects | not started | to be built |
| 23 | Phase D: reset release, input synchronisation, clock constraints | not started | to be built |
| 24 | Phase D: stage balance and the stop line | not started | to be built |

> **Phase D** is lessons 16-24. The endpoint is a five-stage pipeline, and the single-cycle core
> from phase C is what it is verified against. See "Phase D" in `LEARNING.md` and the review
> record in the vault at `01_Projects/FPGA/FPGA-Route-Review-2026-10-28.md`.

## Prerequisite gaps found on 2026-10-29: both closed on 2026-10-30

| Gap | Needed by | Status |
|---|---|---|
| Two's complement, binary addition, carry | `SUB`, `SLT`, every sign-extended immediate | **taught and exercised** in lesson 02 |
| Testbench syntax: `initial`, `reg`, `begin`/`end`, `if`, `case`, `$dumpfile`, `$dumpvars`, `$finish`, `posedge` | Lesson 3 onward, and every testbench he writes | **taught and exercised** as rules 1-4 of lesson 03 |
| Binary arithmetic: half adder, full adder, carry chain | The ALU (lesson 13) | **started**: the full adder is part 1 of `examples/02_adder`; the carry chain arrives with `ADD` in lesson 13 |

> 2026-10-29 查出的三个前置缺口中，补码与加法、测试台语法已经各成一课并在 2026-10-30 出好练习；
> 加法器先从一位全加器做起，进位链留到 ALU 那一课。

## How a lesson works

1. **Read the lesson `.md`**. About 20 minutes.
2. **Write the code**, then run `.\scripts\sim.ps1 -Project examples/NN_name`.
3. **Stuck for more than 30 minutes? Ask.** Before asking, state what you tried and what error you saw.
4. **When it passes, tell me.** I set questions. **You do not declare your own pass.**
5. After you pass, I mark the lesson complete and build the next one.

## Why every lesson ends with questions

Your known failure mode is treating "I have seen this" as "I have mastered this".
Reading an explanation and feeling that it makes sense is a different thing from writing it from scratch.

The questions ask **why**, not just "write the code". The legacy lesson asked why `~` and `!`
cannot be used interchangeably in hardware; lesson 03 asks what `q` holds between reset and the
first edge, and which line of the RTL decides it.

## Relationship to `LEARNING.md`

`LEARNING.md` is the **route**: phases A, B, C, each with acceptance criteria.
This directory is the **course**: how you actually walk that route.

The route says "phase A means you can write sequential logic".
The course says "Lesson 03 covers `always`, Lesson 04 is a counter".

## Relationship to `examples/`

One lesson maps to one directory: `lessons/NN_xxx.md` ↔ `examples/NN_xxx/`.

Two directories carry names that predate the numbering and were not renamed: `00_gates` belongs to
the legacy lesson, `01_counter` to lesson 04, `04_formal` to lesson 05. Each directory contains a
testbench under `sim/tb_*.v` and a `README.md`. Formal exercises hold `formal/props_*.v` instead of
a testbench; it is the acceptance criteria there, under the same rule. `rtl/` is empty **on
purpose**, and you fill it in.

## Who writes the testbench: a handover by capability, not by lesson (2026-10-29)

**The problem this fixes.** For the legacy lesson 1 I wrote every testbench and told him not to
touch it. He asked "tb 也不是我自己写的啊", and he was right: writing the checker is part of the
skill, and without it his only feedback is someone else's verdict.

**The first version of this plan was wrong, and GPT caught it.** I had scheduled the handover by
lesson number (1-3 me, 4-6 gap-filling, 7-9 him, 10 onward him plus a hidden one). Two defects:

1. **I conflated "can write testbench code" with "can judge whether the hardware is correct".**
   In the 7-9 tier I planned to hand him the input list and the expected outputs and have him
   transcribe them into Verilog. That transfers the typing, not the judgement: the decisions about
   *what to test and why* would still be mine. GPT rated that tier's risk **high**, higher than
   every other tier, precisely because it looks like a handover and is not one.
2. **Lesson numbers are teaching progress, not evidence of ability.** Three lessons is not a
   measurement of anything. The right boundaries are observable capabilities.

So the handover is gated on **capability checkpoints**, and a checkpoint is not cleared by reaching
a lesson number. He can be on lesson 8 and still be stuck at checkpoint 1.

| # | Capability | How it is tested (observable) | What I hand over |
|---|---|---|---|
| 1 | **Read a truth table** | Given a table, without looking at any RTL, he names which inputs each output depends on | Nothing yet; I write the checks, he derives expected values by hand |
| 2 | **Write expected values** | Given a written spec, he fills in the expected outputs **without reading the RTL** | The expected-value table is his; the stimulus and the checker are mine |
| 3 | **Design stimulus** | He states what a given test case can catch and, importantly, what it cannot | He chooses the input combinations and the clock edges; I review the coverage argument |
| 4 | **Adjudicate a conflict** | When RTL and testbench disagree, he decides from the spec which side is wrong | He writes the whole testbench; I keep an independent one he does not see |

**Where he is on 2026-10-30.** Checkpoint 1 is **not cleared**: he could not answer where a
testbench's expected values come from, and the remedy ordered that day was for him to write the
gates testbench himself, which is `examples/00_gates/sim/tb_checkpoint1.v` (shipped 2026-10-30,
empty of expected values on purpose).

**Checkpoints 2 and 3 are being introduced in the same breath, deliberately.** Lesson 02 hands
over one file's expected values (`sim/tb_sign.v` in `examples/02_adder`), and lesson 03 hands over
a table and the clock-edge decision inside an existing testbench. That is out of order on paper.
The reason is scope: a course that waits for checkpoint 1 before teaching `always` would stall the
route on one question, while the two new lessons are the ones with a real wall at the end (the
ALU needs arithmetic, and every later testbench needs `always`). The cost is accepted and stated
here rather than hidden: **if his gates testbench is still not written when lesson 03 is passed,
checkpoint 2 stays uncleared regardless of how lesson 03 went**, because the same person cannot be
credited for a table in one file and not for a table in another.

### The rule that makes checkpoint 2 mean anything

**Expected values must never be recomputed from the same operators the RTL uses.** The original
`tb_gates.v` did exactly that:

```verilog
exp_and = a & b;     // same operator as the RTL, so a shared misunderstanding passes
```

That is same-origin verification: the checker and the design are two copies of one answer. If both
mistake `~a` for `~(a & b)`, the test passes and both are wrong. The testbench was changed on
2026-10-29 to a hardcoded table copied from the lesson's truth table, so the expected values come
from the **specification**, not from the operators.

**But a hardcoded table only helps if the table itself is right.** Measured on 2026-10-29: corrupt
one row of the table and run it against *correct* RTL, and the console prints
`FAIL y_not expected 0, got 1`. The testbench reports the disagreement correctly and attributes it
wrongly, blaming the RTL for the spec's error. A console cannot tell you which side is wrong; that
requires a human comparing against an independent statement of the specification. This is why
checkpoint 4 is the real endpoint, not "he can write a testbench that passes".

Both of the new exercises are built so the same question is askable of them: lesson 03's case 0
and case 1 are a start-up and a first-edge sample, and every case waits for an edge except case 0.
A table that assumes the clock has already risen is wrong at case 1, and the console will blame the
RTL for it.

### Why an independent hidden testbench from checkpoint 4 on

If his testbench is the only one, a wrong assumption about RV32I semantics gets written into both the
RTL and its checker, they agree, and both are wrong. The hidden one is what catches that.

**The cost I was underestimating.** Not the number of testbenches, the *correctness* cost: when the
two disagree you cannot tell whether the RTL broke or one testbench went stale. The mitigation is a
single written behavioural contract per module (the interface and the timing) that both testbenches
are derived from, so a disagreement points at an implementation rather than at a drifting
specification. Do not let the two testbenches each grow their own assumptions.
`examples/02_adder/sim/README.md` is the first file written as that kind of contract.

**Rule for me, effective now:** when a checkpoint says the testbench is his, **do not ship a working
one under `sim/`**. Put the specification in the lesson text and the exercise `README.md`. Shipping
a reference testbench and asking him to write his own is a fiction.

> 2026-10-29 记：交接按**能力节点**划分，不按课次。
> 2026-10-30 记：节点 1 仍未过，测试台交接从 `00_gates` 开始落实；节点 2 和 3 在同一轮提前引入，
> 理由和代价写在上面，没有藏。
