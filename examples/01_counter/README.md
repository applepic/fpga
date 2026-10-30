# Exercise 01: 4-bit counter

**Lesson**: Lesson 4. The lesson text is not written yet; the testbench was here from 2026-10-18.
Do not start it until Lesson 3 (`lessons/03_always_and_clocks.md`) is passed: a counter is one
register plus one addition, and the register is Lesson 3.

**Goal**: a binary counter that cycles 0 to 15.

**Maps to**: phase A, acceptance item 1.

## What you write

`rtl/counter.v`, which **does not exist yet**. You create it.

The module interface is fixed by the testbench. Do not rename anything:

```verilog
module counter (
    input  wire       clk,     // clock
    input  wire       rst_n,   // reset, active low
    output reg  [3:0] q        // count value
);
```

## How to run

```powershell
. .\env.ps1
.\scripts\sim.ps1 -Project examples/01_counter
```

It fails right now because `rtl/counter.v` does not exist. That is the starting point.

## Pass condition

Every check in `sim/tb_counter.v` reports PASS.
**The testbench is the acceptance criteria. Do not modify it.**
If you think it is wrong, come and ask me rather than editing it yourself.

It checks three things:

1. `q = 0` while reset is asserted
2. `q` increments on every rising clock edge
3. After 15 it wraps to 0

## Hints (read only after 30 minutes stuck)

<details>
<summary>Expand</summary>

- A counter is **sequential logic**, so it needs `always @(posedge clk)`, not `assign`
- Synchronous or asynchronous reset? Both pass this testbench,
  but you must be able to explain the difference. Gisselquist L02 covers it
- A 4-bit register naturally wraps at 15, so you do not need `if (q == 15)`. Think about why
- Here `reg` only means "a variable assigned inside an `always` block". It does not mean flip-flop.
  That distinction is phase A acceptance item 4

</details>

## After it passes

1. Open the waveform yourself with `-Open` and confirm `q` really changes on the rising edge
2. Come and tell me, and I will set questions. **Do not declare your own pass**

## Optional: put it on the board

This exercise does not require the board by default. If you want to watch the LEDs count:
wire `q` to `led[3:0]`, remembering that **the LEDs are active low**, so invert.
Then run `.\scripts\build.ps1 -Project examples/01_counter` followed by `flash.ps1`.
When you go to hardware, divide the clock down first. At 27 MHz all 16 states flash past faster
than the eye can follow.
