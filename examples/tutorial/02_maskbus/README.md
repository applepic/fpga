# Tutorial 02 · `maskbus`: buses, bit selects and your first real testbench

> Source: ZipCPU beginner tutorial, lesson 1 ("Wires, and combinatorial logic"), slides 18-44. The
> board half of that same lesson is Tutorial 01. Everything here is measured in iverilog before it
> was written down; where the source uses Verilator, this file says what is different.

## What is given

`rtl/maskbus.v` is the design from slide 40 of the source, unchanged: a nine-bit input XORed with
the constant `9'h87` through an internal wire.

```verilog
module maskbus(input wire [8:0] i_sw,
	       output wire [8:0] o_led);

	wire	[8:0] w_internal;

	assign	w_internal = 9'h87;
	assign	o_led = i_sw ^ w_internal;
endmodule
```

`sim/tb_maskbus.v` is my acceptance testbench. It checks ten rows, and every expected value in it was
computed by hand from the table below.

## The specification

XOR with `9'h87` means: every bit of `i_sw` that lines up with a 1 in `0x87` comes out flipped, and
every bit that lines up with a 0 comes out unchanged. `0x87` is `0_1000_0111` in nine bits, so bits
7, 2, 1 and 0 flip and bits 8, 6, 5, 4 and 3 pass through.

| `i_sw` | `o_led` | why |
|---|---|---|
| `0x000` | `0x087` | nothing to flip, so the mask itself comes out |
| `0x087` | `0x000` | every set bit flips once, so both set bits go to 0 |
| `0x0f0` | `0x077` | bits 7, 2, 1, 0 flip; `0xf0` keeps its high bits and gains the low ones |
| `0x150` | `0x1d7` | `1_0101_0000` flipped in bits 7..0 gives `1_1101_0111` |

> Those three plus the first two are the source's own vector (`0x150` is row `150` in the source's
> simulator output, slides 42 onward) and the two identity cases.

## What you write

`sim/tb_mine.v`, your own testbench. Requirements:

1. Cover the first three rows of the specification table.
2. Add at least two boundary values of your own choosing: all zeros, all ones, a single set bit, or
   exactly the mask.
3. Print one line per case, in whatever format you like, and print `=== tb PASS ===` when every row
   matches and the failing row plus expected value when one does not.
4. **Compute every expected value by hand and paste it in as a literal.** Writing
   `expected = i_sw ^ 9'h87;` inside the testbench is the same-origin trap: the test would compute
   its answer with the operator the design is being tested for, and one misunderstanding would pass
   twice.

## The two things a testbench needs that the design does not

`sim/tb_mine.v` is not synthesised, so it may use constructs the design may not: an `initial` block,
`#1` delays, `$display`, and variables that hold values across time.

- `initial` runs once at time zero, which is where you set inputs and print results.
- `#1` waits one nanosecond. The design is combinational, so its output settles immediately; `#1`
  is what makes "immediately" observable to the simulator. Without it you can read the output in the
  same instant the input changed, before the design has been evaluated.

## Run

```powershell
cd C:\Local_Data\Dev\fpga
```

`cd` moves the current folder to the project root.

```powershell
. .\env.ps1
```

`env.ps1` loads the toolchain into this terminal. The first dot is the dot-source operator, the
second dot belongs to `.\`.

```powershell
.\scripts\sim.ps1 -Project examples/tutorial/02_maskbus
```

`sim.ps1` is the simulation script; `-Project` names the exercise folder. It compiles every
testbench under `sim/` and runs each one.

Expected output from my testbench, and the state to reach:

```
=== tb PASS === all 10 rows match
```

The line `No tb.vcd produced. The testbench is missing $dumpfile/$dumpvars.` is a note, not a
failure: add `$dumpfile` and `$dumpvars` if you want a waveform you can open in GTKWave.

## What passes

1. `tb_maskbus` passes all ten rows.
2. `tb_mine` passes, and the boundary cases you chose are visible in its output.
3. `tb_mine` contains no `^` used to compute an expected value.
4. You can say what `0x087` produces and why (the source's own example happens to make this easy to
   check: the mask XORed with itself is zero).

## Measured facts

- `0x000` gives `0x087`, `0x087` gives `0x000`, `0x0ff` gives `0x078`, `0x100` gives `0x187`.
- An `o_led = i_sw | 9'h87` design fails 6 of the ten rows, and a design with the mask misread as
  `0x78` fails all ten. A testbench that cannot fail is not a testbench, so both were run.
