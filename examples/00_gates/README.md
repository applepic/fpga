# Exercise 00: four basic gates

**Lesson**: `lessons/legacy_01_verilog_basics.md` (old lesson 1, passed 2026-10-29); the vault
copy you read is `01_Projects/FPGA/Lesson-01-Combinational-Logic.md`

**The point of this exercise is not to learn gate logic** (that part is trivial).
It is to see with your own eyes that **Verilog describes circuit structure, not execution order**.

## What you write

`rtl/gates.v`, which **does not exist yet**. You create it.

```verilog
module gates (
    input  wire a,
    input  wire b,
    output wire y_and,
    output wire y_or,
    output wire y_xor,
    output wire y_not
);
```

**The operators are not written here on purpose.** The specification is the truth table under
"Pass condition" below: each output column tells you what that output must do. Deriving the four
expressions from those four columns is the exercise.

> **这里故意不写运算符。** 规格是下面「Pass condition」那张真值表：每一列告诉你那个输出该做什么。
> 从四列反推出四个表达式，就是这次练习。

## How to run

```powershell
cd C:\Local_Data\Dev\fpga
. .\env.ps1
.\scripts\sim.ps1 -Project examples/00_gates
```

## Pass condition

All four input combinations correct, ending with `=== ALL PASS ===`.

**The testbench is yours: `sim/tb_checkpoint1.v`.** You wrote `rtl/gates.v` on 2026-10-29, and
that is when the handover rule took effect: the testbench I wrote (`tb_gates.v`) was removed from
the repository on 2026-10-30, because shipping a working checker beside "now write your own"
makes the exercise fictional. The new file has the shape to fill and no expected values.

The testbench is the acceptance criteria, so the expected values have to come from the lesson's
truth table, not from the design's operators. `git show 40b7d48:examples/00_gates/sim/tb_gates.v`
is the version I wrote, kept in history for reference. When yours is done, tell me; I run the
unchanged original against the same design.

## After it passes

1. Open the waveform with `-Open` (`. .\env.ps1`, then
   `.\scripts\sim.ps1 -Project examples/00_gates -Open`). Watch whether the four outputs
   change **immediately** when `a` or `b` changes, with no delay.
2. Reorder the `assign` lines, rerun, and confirm the result is identical.
3. Come back and ask me for the questions.
