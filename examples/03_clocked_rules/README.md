# Exercise 03: clocks, non-blocking assignment, and your first expected-value table

**Lesson**: Lesson 3, `always`, clocks, blocking vs non-blocking.

**Maps to**: phase A, "writing sequential logic" and "explain synchronous vs asynchronous reset".
Every register in the RV32I core, and every pipeline register in phase D, is this one module
shape.

Two modules, two reports. The change from exercise 02: `sim/tb_rule.v` does not hold all the
expected values. Two rows are filled in as specimens. **The other rows are yours to fill in**,
including one that has no clock edge in it, and that is capability checkpoint 2.

## What you write

### Part 1: `rtl/mux4.v` (testbench syntax, rules 1-4)

```verilog
module mux4 (
    input  wire [2:0] sel,
    output reg  [1:0] y      // `reg`, because it is assigned inside always @*
);
```

The mapping is the specification, all eight rows:

| `sel` | `y` | rule that decides it |
|---|---|---|
| `000` | `00` | |
| `001` | `10` | |
| `010` | `01` | |
| `011` | `11` | |
| `100` | `00` | `default` |
| `101` | `10` | `default` |
| `110` | `01` | `default` |
| `111` | `11` | `default` |

`sel[2]` is never used. The first four rows never reach `default`; rows 5-8 do. Read the lesson's
rules 1-4 before writing it: the point of this part is `case` with `default` and a blocking
assignment in a combinational `always`, not the mux.

### Part 2: `rtl/two_regs.v` (the clock, rules 5-8)

```verilog
module two_regs (
    input  wire       clk,
    input  wire       rst,    // synchronous, active high, tested inside always @(posedge clk)
    input  wire       en,     // enable
    input  wire [1:0] d,      // value loaded when en is 1
    output reg  [1:0] q
);
```

The behaviour is rules 5-8 in the lesson. The testbench applies the inputs for one clock cycle at
a time and compares against a table of expected values. The table is in `sim/tb_rule.v`, in the
`sheet` and `chg` arrays. Rows 1 and 2 are filled in, row 0 and rows 3-16 are yours.

How to fill them, in this order:

1. **Build the table on paper first.** Columns: case, `rst`, `en`, `d`, `q` after the edge,
   number of times `q` has changed. `q` starts at 0 and the clock rises once per case.
2. Write the two numbers into `sheet[N]` and `chg[N]` next to the case, and write the `$display`
   line that reports it. Cases 1 and 2 have no `$display` because it would give away their
   answers; yours is where the printed table comes from.
3. **Decide what each case needs.** Every case in this file waits for the next rising edge. Look
   at the timeline in the file before you accept that: two consecutive cases must be one edge
   apart, and any case that is not is testing the same cycle twice. Which one, and which of your
   rows has the same shape.
4. Report. `PART 2 PASS` means the design agrees with your table.

If it fails, the interesting question is **which side is wrong, the table or the RTL**, and that
is decided from the rules in the lesson. That is checkpoint 4 and this is the first exercise that
lets you practise it.

## Run

```powershell
. .\env.ps1
.\scripts\sim.ps1 -Project examples/03_clocked_rules
```

Today it fails with `Unknown module type: mux4`, because `rtl/` is empty. That is the start.

Waveform: add `-Open` to `sim.ps1`.

## Wrong versions to try once it passes

On your own copy, one at a time. Write down which report catches each.

| Change | Which rule breaks |
|---|---|
| `q <= d;` becomes `q = d;` inside `always @(posedge clk)` | rule 8 |
| remove `if (en)` | rule 7 |
| `if (rst)` becomes `if (!rst)` | rule 6 |
| `q <= {2{d[1]}};` (ignore `d[0]`) | rule 5, plus rule 7 sometimes |

<details>
<summary>Hint, only after 30 minutes stuck</summary>

- One `always @(posedge clk)` block. Inside it, `if (rst)` first, `else if (en)` second.
- Non-blocking `<=` everywhere inside it. The blocking version compiles and simulates; it is
  wrong in a way rule 8 exists to catch.
- `q` is `output reg`, not `output wire`, because it is assigned inside `always`.

</details>

## After it passes

Open the waveform with `-Open`, look at `q` against `clk`, and confirm it moves one edge after
`d` changes. Then come back with: which case did your table get wrong first, if any, and how you
decided which side was at fault. Lesson 4 is the counter exercise, `examples/01_counter`, already
waiting with its testbench.
