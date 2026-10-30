# Lesson 05: Refinement, or what a proof gives you that a test does not

> Numbered 4 in this file's name before the 2026-10-30 renumbering; the course index calls it
> lesson 05. Content is unchanged.

**Prerequisite**: legacy lesson 1 (`assign`, combinational logic), lesson 03 (`always @(posedge clk)`),
lesson 04 (counters). This lesson builds on all of them.

About 40 minutes of reading, then an exercise.

---

## 4.1 The question this lesson answers

In lesson 04 you write a counter and a testbench checks it for 20 clock cycles.

Here is the problem with that. The testbench checks **the 20 cycles you thought of**. If your
counter breaks on cycle 201, or only when `inc` is high during a reset, your testbench never
finds out. You wrote the check and the bug in the same head, on the same day.

Simulation answers: **"does this specific input sequence behave correctly?"**

There is a second question you can ask: **"is there any input sequence at all that breaks this?"**

That second question is what formal verification answers. It is not a better test. It is a
different kind of statement: not "I tried a lot of inputs", but "there is no input that fails,
and the tool has checked all of them".

## 4.2 The shape of a refinement check

The word **refinement** in this context names one specific relation:

> Implementation `impl` refines specification `spec` when every behaviour `impl` can produce
> is a behaviour `spec` allows.

Both directions matter, and they are not the same:

| Situation | What it means |
|---|---|
| `impl` allows behaviour `spec` forbids | A bug. The implementation does something the specification says is impossible |
| `impl` forbids behaviour `spec` allows | **Not** a bug. The implementation is more constrained than required |

That asymmetry is the whole idea. The implementation is allowed to be **more** restricted than the
specification. It is never allowed to be **less** restricted. If your spec says "the counter counts
up to 200" and your implementation stops at 150, that is a bad design but not a refinement
violation. If your implementation wraps from 200 back to 0, that is a refinement violation.

**Refinement is a relation, not a thing.** It always takes two arguments. That is why the question
"what is refinement" has no answer, and "does this refine that" always does.

## 4.3 Why this is not the same as testing

| | Testbench | Proof |
|---|---|---|
| Who picks the inputs | You | The solver |
| How many cases | The ones you wrote | All of them |
| Result when it passes | No bug found in these cases | No bug exists |
| Result when it fails | A printed mismatch | A concrete trace you can open in gtkwave |
| What it cannot tell you | Anything outside the cases you wrote | Nothing about *why* the design is right |

The last row matters and is easy to forget. A proof tells you the property holds. It does not tell
you the property is the one you wanted. **A proof of the wrong property is worthless**, and the
tool cannot detect that.

## 4.4 `assert`, `assume`, and the difference

Two keywords, and confusing them is the single most common formal mistake:

| Keyword | Who it constrains | Meaning |
|---|---|---|
| `assert` | **The design** | "This must be true. If it can be false, the design is wrong" |
| `assume` | **The environment** | "Treat this as given. Do not consider inputs that violate it" |

`assert` is the claim you are making about your circuit. `assume` is the claim you are making about
the world around it.

**An `assume` is a promise, and the proof only holds if the promise holds.** If you assume `rst` is
never high while `inc` is high, and in real hardware that can happen, you have proved something
about a circuit that does not exist. The tool will not warn you.

This is why formal verification has a reputation for being easy to get subtly wrong. The proofs are
sound; the specifications are where the mistakes live.

## 4.5 Why there is no "time 0"

In simulation, `reg [7:0] q` starts at `x` and you reset it. In a proof, the solver is allowed to
pick **any starting state**, including states the real circuit could never reach. Then it looks for
any path from there that breaks an assertion.

That is stricter than reality, and it is the right kind of strict. If the property holds from every
possible starting state, it certainly holds from the one your reset produces.

The practical consequence: most properties need a guard for the first cycle. The pattern is the
same every time:

```verilog
reg f_past_valid = 1'b0;
always @(posedge clk)
    f_past_valid <= 1'b1;
```

`f_past_valid` is low in the first cycle and high forever after. Then every property is written as
`if (f_past_valid && ...) assert (...)`, and anything that depends on a previous cycle uses
`$past(...)`.

**`$past(x)` is "the value of x in the previous cycle".** It only makes sense when there is a
previous cycle, which is the other reason for the guard.

## 4.6 The tool: SymbiYosys

The local toolchain already has it. `sby` is a driver that runs yosys to turn your Verilog into a
state machine, then hands it to an SMT solver (`yices`, `z3`, `boolector`) which does the actual
searching.

`sby` exit codes, which you will see in the script output:

| Code | Meaning | What to do |
|---|---|---|
| 0 | PASS | The property holds in every reachable state |
| 2 | FAIL | A counterexample exists, and a waveform was written |
| 4 | UNKNOWN | The solver gave up inside the depth limit. **Not a pass** |

The `depth` in the `.sby` file is how many clock cycles the solver is allowed to explore. A design
that needs 201 cycles to reach the interesting state will come back `UNKNOWN` at depth 4 and `FAIL`
at depth 260. **Raising the depth and rerunning is the standard first move when you see UNKNOWN.**

## 4.7 Summary

| Concept | Remember this |
|---|---|
| Refinement | A relation between two things. `impl` refines `spec` when `impl` allows nothing `spec` forbids |
| Asymmetry | More constrained than the spec is fine. Less constrained is a bug |
| `assert` | Constrains the design. This is your claim |
| `assume` | Constrains the environment. This is your promise, and it can be false |
| No time 0 | The solver starts anywhere. Guard the first cycle with `f_past_valid` |
| UNKNOWN | Not a pass. Usually the depth is too small |

---

## Your task

Implement `examples/04_formal/rtl/sat_counter.v` and get the proof to `PASS`. Then do the three
deliberate-bug experiments in that exercise's README before asking me anything.

```powershell
cd C:\Local_Data\Dev\fpga
. .\env.ps1
.\scripts\formal.ps1 -Project examples/04_formal
```

**Right now this reports `No .v files under ...\rtl\. The design under test is missing.`**
That is your starting point.

**Come back and tell me when you are done**, and I will set you three questions. One of them will
be about the difference between `assert` and `assume`, and it will not be the easy version.

> Hint: the counter logic is four lines and you already know it from lesson 04. The work in this
> lesson is reading the property file until you can say what each line constrains.
