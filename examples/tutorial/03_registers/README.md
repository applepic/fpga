# Tutorial 03 · Registers and blinky

> Source: ZipCPU beginner tutorial, lesson 2 ("Registers"), slides 1-27. Slides 28-37 are Tutorial 04.
> Every measurement in this file was taken with iverilog and, where the board is involved, with this
> repo's `build.ps1` on the Tang Nano 9K.

## What is given

- `rtl/blinky.v`: the design from slide 16, with the counter width turned into a parameter as slide 20
  suggests.
- `sim/tb_blinky.v`: my acceptance testbench. It overrides `WIDTH` to 8 so the run takes 400 edges
  instead of 2^27, and it checks the counter's start value and the LED's transitions.

## What you write

`rtl/strobe.v`, the design from slide 28, unchanged:

```verilog
module strobe(i_clk, o_led);
	input  wire i_clk;
	output wire o_led;
	reg [26:0] counter;

	always @(posedge i_clk)
		counter <= counter + 1'b1;

	assign o_led = &counter[26:24];
endmodule
```

Three things you have to be able to explain, and I will ask:

1. What does `&` in front of a signal mean, as opposed to `&` between two signals? (Lesson 02, Q1,
   asked the same question about `|`.)
2. How often is `o_led` high, in seconds, at 27 MHz? Compute it; do not estimate.
3. There is no `initial` in this design. In simulation `counter` is `x` and stays `x`. So what is
   `o_led`, and what does that do to a testbench for it?

## The testbench you write

`sim/tb_strobe.v`. It has to show two things, and both need real arithmetic in the testbench:

1. `o_led` is high for a contiguous run of edges: exactly 2^24 / 8 = 2_097_152 edges out of every
   2^24 = 16_777_216. That is too many to simulate one by one, so override the design so that the
   pattern is the same arithmetic at a smaller width, or drive the counter's clock for the first few
   thousand edges and check the intervals between the runs. Whatever you choose, the numbers in your
   testbench must come from that arithmetic, and you must say where each one came from.
2. `o_led` does not depend on the low bits of the counter. Hold the high bits fixed, change
   `counter[23:0]`, and `o_led` must not move.

Requirement 2 is the one that catches a design that applies `&` to the wrong bit range.

## Run

```powershell
cd C:\Local_Data\Dev\fpga
```

`cd` moves the current folder to the project root.

```powershell
. .\env.ps1
```

`env.ps1` loads the toolchain into this terminal. The first dot is the dot-source operator, the second
dot belongs to `.\`.

```powershell
.\scripts\sim.ps1 -Project examples/tutorial/03_registers
```

`sim.ps1` is the simulation script; `-Project` names the exercise folder. It compiles every testbench
under `sim/` and runs each one.

## Measured facts

- `tb_blinky` on the reference design passes. Its five checks are the counter after one edge, and the
  LED at edges 127, 128, 255, 256 and 384, all worked out by hand from `WIDTH = 8` before the design
  existed.
- Wrong variants fail, each in a different place: a design that ignores the parameter (hard-coded 27
  bits), a design with no `initial` (the counter reads `x`), a one-bit counter, and a design wired to
  `counter[0]` instead of the top bit. A blocking `counter = counter + 1'b1;` inside the clocked block
  passes, which matches slide 9's note that the two produce the same logic here.
- `blinky` with `WIDTH = 27` builds for the board at Fmax 156 MHz against the 27 MHz target, so it
  passes timing with room to spare.

## Why this lesson stops at slide 27

Slides 28-37 are strobe, two one-pulse-per-second designs, a stretch circuit, the too-slow counter that
is supposed to fail timing, and the dimmer. They are Tutorial 04 because they introduce integer and
fractional clock dividers, which need their own explanation rather than an appendix.
