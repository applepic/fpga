# Exercise 02: prove it, do not just test it

**Lesson**: Lesson 05. The file keeps its old name `lessons/04_formal_refinement.md` from before the 2026-10-30 renumbering.

**The point of this exercise is not the counter.** A saturating counter is trivial. The point is
that you get a **proof**, not a sample. Simulation asks "did this input sequence behave?", and the
sequence is one you thought of. A proof asks "is there any input sequence at all that breaks this?",
and answers either no, or here is the exact sequence that does.

## What you write

`rtl/sat_counter.v`, which **does not exist yet**. You create it.

The module interface is fixed by the properties. Do not rename anything:

```verilog
module sat_counter (
    input  wire       clk,     // clock
    input  wire       rst,     // reset, active high, synchronous
    input  wire       inc,     // count enable
    output reg  [7:0] count    // count value, saturates at 200
);
```

## The specification

Three properties, in `formal/props_sat_counter.v`:

| | Property |
|---|---|
| P1 | `count` never exceeds 200 |
| P2 | once it reaches 200, it stays at 200 while `inc` is high |
| P3 | while `inc` is high and `count < 200`, it goes up by exactly one |

**The property file is the acceptance criteria. Do not modify it.**
If you think a property is wrong, come and ask me rather than editing it yourself.

## How to run

```powershell
cd C:\Local_Data\Dev\fpga
. .\env.ps1
.\scripts\formal.ps1 -Project examples/04_formal
```

Right now it reports `No .v files under ...\rtl\. The design under test is missing.`
That is the starting point.

When you have a counter, the run ends with one of three lines:

| Line | Meaning |
|---|---|
| `PASS` | The property holds in every reachable state. Done |
| `FAIL` | A counterexample exists. A waveform is written to `build/formal/engine_0/trace.vcd` |
| `UNKNOWN` | The solver gave up inside the depth limit. **This is not a pass** |

`FAIL` and `UNKNOWN` are easy to confuse and mean opposite things. `FAIL` means your design is wrong
and the tool has evidence. `UNKNOWN` means the tool did not decide, and your design may be perfectly
fine. The depth is in `formal/sat_counter.sby`; if you raise it and the result turns from `UNKNOWN`
into `PASS`, the design was fine.

## The experiment you must do before asking me

Write a **deliberately wrong** counter, run the proof, and read the counterexample. Then fix it.

Three wrong versions worth trying, one at a time:

1. **Wrap instead of saturate.** Drop the `count != 200` guard. The proof fails; look at which
   property fails and at which step
2. **Saturate one early.** Change the guard to `count != 199`. This one is interesting: the
   counter is still monotonic and still bounded, so P1 and P2 pass. Only P3 catches it
3. **Ignore `rst`.** The proof fails almost immediately. Find out at which step and why

The third one tells you something a testbench cannot: the solver found a starting state your
reset was supposed to rule out.

## Hints (read only after 30 minutes stuck)

<details>
<summary>Expand</summary>

- `count` needs an `initial` value or the solver is free to start it at 201. Actually, read the
  note in `props_sat_counter.v` about `f_past_valid` first, then decide whether you still need one
- The comparison `count != 8'd200` is a guard on the **assignment**, not on the assertion.
  Getting the guard into the wrong place produces a counter that is off by one
- `always @(posedge clk)` with a non-blocking assignment (`<=`) is the same rule as Lesson 03.
  Nothing about formal changes how the hardware works

</details>

## After it passes

1. Run `.\scripts\formal.ps1 -Project examples/04_formal -Open` on a failing version and look at
   the waveform. Compare it with what a testbench would have shown you
2. Delete the `f_past_valid` assumption block temporarily and rerun. Explain why it now fails
3. Come and tell me, and I will set questions. **Do not declare your own pass**

## Why this exercise exists

It is the first place in this course where the tool can tell you "no" with a proof instead of
with a lucky test. That property, a check that is either proven or refuted with evidence, is the
thing worth learning here. The counter is incidental.
