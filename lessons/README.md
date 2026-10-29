# Course index

> A step-by-step course from zero to RV32I. **Every lesson has a runnable task.
> When you finish one, I set questions. You only advance after passing.**

The order is not organised by topic. It is organised by **what blocks you next**.

## Progress

| Lesson | Topic | Status | Exercise |
|---|---|---|---|
| 1 | What Verilog describes: `wire` / `assign` / bitwise ops | **passed 2026-10-29** | `examples/00_gates` |
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

## Known prerequisite gaps (found 2026-10-29, not yet scheduled)

I audited the docs against what phases A and C actually require. Three things are needed later and
taught nowhere. Listed here so a future session does not rediscover them.

| Gap | Needed by | Status |
|---|---|---|
| **Two's complement, binary addition, carry** | RV32I `SUB`, `SLT`, every sign-extended immediate (lesson 11-13) | Taught nowhere. `LEARNING.md`, `SPEC.md` and both lesson files contain no coverage |
| **Testbench syntax**: `initial`, `reg`, `begin`/`end`, `if`, `case`, `$dumpfile`, `$dumpvars`, `$finish`, `posedge` | Lesson 2 onward, and every testbench he writes from checkpoint 2 | Lesson 1 mentions only `$display`, `#10`, `integer`. He has read all the rest inside `tb_gates.v` without ever being taught it |
| **Binary arithmetic: half adder, full adder, carry chain** | The ALU (lesson 12) | Taught nowhere |

**Why the first gap matters most.** Two's complement is a mental model, not syntax. Reaching the
decode lesson without it means learning immediate sign-extension and Verilog syntax at the same time.
The proposal on 2026-10-29 was to put two's complement and binary addition *before* `always`, then
teach testbench syntax as its own lesson. That renumbers the course from 23 to 24 lessons and was
**not yet approved**, so the table above is unchanged.

> 2026-10-29 查出来的三个前置缺口：补码与二进制加法、测试台语法、加法器。都还没排进课表。
> 补码最要紧，它是思维模型不是语法，等写到立即数扩展时再补会同时面对两个难点。
> 提议把补码放到 `always` 之前、测试台语法单独一课，课数从 23 变 24，**尚未确认**。

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

## Who writes the testbench: a handover by capability, not by lesson (2026-10-29)

**The problem this fixes.** For lessons 1 to 3 I wrote every testbench and told him not to touch it.
He asked "tb 也不是我自己写的啊", and he was right: writing the checker is part of the skill, and
without it his only feedback is someone else's verdict.

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
| 1 | **Read a truth table** | Given a table, without looking at any RTL, he names which inputs each output depends on | Nothing yet; I write the testbench, he derives expected values by hand |
| 2 | **Write expected values** | Given a written spec, he fills in the expected outputs **without reading the RTL** | I write the testbench skeleton, he fills the expected-value table |
| 3 | **Design stimulus** | He states what a given test case can catch and, importantly, what it cannot | He chooses the input combinations; I review the coverage argument |
| 4 | **Adjudicate a conflict** | When RTL and testbench disagree, he decides from the spec which side is wrong | He writes the whole testbench; I keep an independent one he does not see |

**Checkpoint 1 is currently not cleared** (2026-10-29). He could not answer where a testbench's
expected values come from, which is the same skill.

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

### Why an independent hidden testbench from checkpoint 4 on

If his testbench is the only one, a wrong assumption about RV32I semantics gets written into both the
RTL and its checker, they agree, and both are wrong. The hidden one is what catches that.

**The cost I was underestimating.** Not the number of testbenches, the *correctness* cost: when the
two disagree you cannot tell whether the RTL broke or one testbench went stale. The mitigation is a
single written behavioural contract per module (the interface and the timing) that both testbenches
are derived from, so a disagreement points at an implementation rather than at a drifting
specification. Do not let the two testbenches each grow their own assumptions.

**Rule for me, effective now:** when a checkpoint says the testbench is his, **do not ship a working
one under `sim/`**. Put the specification in the lesson text and the exercise `README.md`. Shipping
a reference testbench and asking him to write his own is a fiction.

> 2026-10-29 记：交接按**能力节点**划分，不按课次。节点 1「会读真值表」目前没过。
> 期望值绝不能和 RTL 用同一套运算符算出来，否则测试台和设计是同一个答案的两份拷贝。
> 硬编码真值表也有风险：表本身抄错时，控制台会正确报告冲突但错误地归咎于 RTL。
> 真正要验的能力是冲突时能依据规格判断哪一边错。
