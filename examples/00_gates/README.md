# Exercise 00: four basic gates

**Lesson**: [Lesson 1](../lessons/01_verilog_basics.md)

**The point of this exercise is not to learn gate logic** (that part is trivial).
It is to see with your own eyes that **Verilog describes circuit structure, not execution order**.

## What you write

`rtl/gates.v`, which **does not exist yet**. You create it.

```verilog
module gates (
    input  wire a,
    input  wire b,
    output wire y_and,   // a & b
    output wire y_or,    // a | b
    output wire y_xor,   // a ^ b
    output wire y_not    // ~a
);
```

## How to run

```powershell
cd C:\Local_Data\Dev\fpga
. .\env.ps1
.\scripts\sim.ps1 -Project examples/00_gates
```

## Pass condition

All four input combinations correct, ending with `=== ALL PASS ===`.

**The testbench is the acceptance criteria. Do not modify it.**

## After it passes

1. Open the waveform with `-Open` (`. .\env.ps1`, then
   `.\scripts\sim.ps1 -Project examples/00_gates -Open`). Watch whether the four outputs
   change **immediately** when `a` or `b` changes, with no delay.
2. Reorder the `assign` lines, rerun, and confirm the result is identical.
3. Come back and ask me for the questions.
