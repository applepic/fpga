# Tutorial 04 · Clock dividers, one pulse per second, and timing checks

> Source: ZipCPU beginner tutorial, lesson 2 ("Registers"), slides 28-37: Strobe, PPS-I, PPS-II,
> Stretch, Too Slow, Dimmer, Exercises. Tutorial 03 is the first half of the same source lesson.
> Everything in "Measured" was run here first.

## What you write

Three designs, in your own words and your own order, none of them copy-paste:

### 1. `rtl/pps.v`

A one pulse per second LED at 27 MHz. `examples/tutorial/03_pps/rtl/pps.v` is my version and you may read
it, but derive yours and be able to defend every line:

- `CLOCK_RATE_HZ` must be a `parameter`, not a `localparam`, or a testbench cannot override it.
  iverilog refuses with `Cannot override localparam CLOCK_RATE_HZ in tb.u_dut`.
- The counter adds a constant once per edge. If that constant is `2^32 - CLOCK_RATE_HZ/2`, the counter
  passes through zero once every `CLOCK_RATE_HZ` edges, so the LED period is one second.
- Your testbench must say **how far from zero** the counter is after `D = CLOCK_RATE_HZ/2` edges.
  Repeated addition is not division: after `D` edges it holds `2^32 - D*D mod 2^32`, which is not zero.

### 2. `rtl/tooslow.v` and a timing conclusion

The 1024-bit counter from slide 34, `parameter NBITS = 1024`, and it must build twice:

```powershell
.\scripts\build.ps1 -Project examples/tutorial/04_dividers
```

`build.ps1` is the build script; without arguments it targets 27 MHz, this board's oscillator.

```powershell
.\scripts\build.ps1 -Project examples/tutorial/04_dividers -Freq 100
```

`-Freq` overrides the target frequency in MHz. Paste both outputs, and answer in one sentence why this
board does not fail the way the source predicts.

### 3. `rtl/dimmer.v`

The dimmer from slide 36, on the board, so you can see the brightness change. In simulation, prove only
the two endpoints: when `counter[27:20]` is 0 the LED never lights, and when it is 255 it never goes out.

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
.\scripts\sim.ps1 -Project examples/tutorial/04_dividers
```

`sim.ps1` is the simulation script; `-Project` names the exercise folder.

## Measured, so you can compare your numbers

Fmax of `counter <= counter + 1` at the default 27 MHz target, on this device:

| Counter width | Result |
|---|---|
| 64 | Fmax 156.01 MHz, pass |
| 128 | Fmax 99.42 MHz, pass |
| 256 | Fmax 57.62 MHz, pass |
| 288 | nextpnr fails to place the carry chain, timing is never reached |
| 320, 512, 1024 | same placement failure |

So the source's 1024-bit counter does not fail timing here, it fails placement. To see a timing failure
you have to raise the target: 256 bits with `-Freq 100` gives
`Max frequency for clock 'u.i_clk': 57.62 MHz (FAIL at 100.00 MHz)` and stops the build.

Two more measured facts about `pps.v`:

- `localparam [32:0] INCREMENT = 33'h1_0000_0000 - CLOCK_RATE_HZ/2;` is clean. The same value written as
  `32'h1_0000_0000 - D` gives `warning: Extra digits given for sized hex constant` and
  `warning: Numeric constant truncated to 32 bits`, and the result is still right, because the
  truncation to 0 makes it `0 - D`, which is `2^32 - D` in two's complement.
- `o_led` must be a `wire` assigned from a `reg`, or `build.ps1` reports
  `ERROR: Unconstrained IO:u_pps.i_clk_IBUF_O`, because the port name in the top module stops matching
  the board file. My first version declared `output reg o_led` and hit exactly that.

## What passes

1. `pps` passes a testbench that checks the counter's value after 1 and after `D` edges, with the
   expected numbers worked out from `D` in the testbench, not copied from the design.
2. Both `tooslow` builds are reported, and your one-sentence explanation matches the table above.
3. `dimmer` is on the board and visibly changes brightness, and the two endpoint checks pass in
   simulation.

Then answer the four questions in the lesson note. Question 4 has a concrete answer and I will check it.
