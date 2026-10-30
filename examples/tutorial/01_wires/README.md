# Tutorial 01 · `thruwire` and the board

> Source: ZipCPU beginner tutorial, lesson 1 "Wires, and combinatorial logic"
> ([zipcpu.com/tutorial](https://zipcpu.com/tutorial/), `lsn-01-wires.pdf`, 51 pages). This exercise
> is the board half of that lesson; the bus, bit-select and simulation half is lesson 2.

## What is already here

`rtl/thruwire.v` is complete. It is the design from slide 3 of the original, unchanged: one input
`i_sw`, one output `o_led`, and `assign o_led = i_sw;`. The original hands it to you in full, so this
one is handed to you in full as well. There is nothing to invent in it, and inventing something would
be a mistake.

## What you write

`rtl/top.v`, with exactly these ports:

```verilog
module top(input wire [1:0] btn, output wire [5:0] led);
```

These two names and widths are not negotiable: `constraints/tangnano9k.cst` binds `btn[0]` to pin 4
and `led[0]` to pin 10, and `btn`/`led` are the only names the board file knows.

Inside it, instantiate `thruwire` and connect it to the board. Two things to decide:

1. `btn` is two bits wide, `i_sw` is one bit. Which bit do you connect, and how do you write "bit 0
   of a two-bit input" in Verilog?
2. On this board the LED lights when the pin is driven **low**, and the button also reads **low**
   when pressed. So pressing the button and driving `i_sw` with the raw button level: does the LED
   light when you press, or when you release? Answer it as a truth table on paper first, then check
   on the board.

## The port mapping form

Connecting a module's port to a signal has two spellings, and one of them is the reason you can
later swap a module without touching every line:

- by position: `thruwire u(btn[0], led[0]);`, where the order must match the module's port list
  exactly
- by name: `thruwire u(.i_sw(btn[0]), .o_led(led[0]));`, where the order does not matter and the name
  must match

Use the by-name form. Every later exercise in this repo uses it, and the first time a module grows a
port you will see why.

## Run

```powershell
cd C:\Local_Data\Dev\fpga
```

`cd` moves the current folder to the project root.

```powershell
. .\env.ps1
```

`env.ps1` loads the toolchain into this terminal. The first dot is the dot-source operator, the
second belongs to `.\`.

```powershell
.\scripts\build.ps1 -Project examples/tutorial/01_wires
```

`build.ps1` is the build script; `-Project` names the exercise folder. It runs yosys, then nextpnr,
then `gowin_pack`, and prints utilisation and timing at the end.

```powershell
.\scripts\flash.ps1 -Project examples/tutorial/01_wires
```

`flash.ps1` programs the bitstream into the board's SRAM. It is lost on power cycle; add `-Flash`
to write the persistent flash instead.

## What passes

1. `build.ps1` finishes and names `build\top.fs`.
2. Pressing `btn[0]` changes `led[0]`, and you can say which direction it went and why.
3. Warnings about `led[1]` through `led[5]` having no driver are expected: your `top` drives one LED.
   If you see a warning that `btn[1]` has no load, that is also expected. Warnings that name `i_sw`
   or `thruwire` are not expected.

## The simulation half, and why it is lesson 2

The original lesson 1 also builds a Verilator simulation and a C++ driver, then reintroduces the
design as a bus (`maskbus`) to talk about bit selects. That is a different tool chain from the one
this project uses (iverilog plus a Verilog testbench), so it is lesson 2 here, where it can be
introduced properly instead of half-way through a board exercise.

## Measured facts, so you do not have to discover them twice

- `build.ps1` on this exercise with a correct `top` reports 3 IOB and "no internal timing paths",
  because the design has no clock. That is a pass, not a failure.
- nextpnr warns about every port in the constraint file that your design does not use. Those
  warnings are noise.
