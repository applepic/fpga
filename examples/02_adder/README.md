# Exercise 02: one-bit full adder, then your own testbench

**Lesson**: Lesson 2, binary arithmetic.

**Maps to**: phase A (combinational logic) and phase C, where `ADD` / `SUB` / `SLT` and every
sign-extended immediate depend on this.

This exercise has two files and two checkmarks. The first one runs today. The second one is
your testbench, the first you write, and it exists because it is the only way to check the two
rules the acceptance testbench cannot check.

## What you write

### Part 1: `rtl/full_adder.v` (graded by `sim/tb_adder.v`)

The interface is fixed by the testbench. Do not rename anything:

```verilog
module full_adder (
    input  wire a,
    input  wire b,
    input  wire c_in,    // carry in
    output wire sum,
    output wire c_out    // carry out
);
```

You already have a 4-bit adder in `examples/00_gates/rtl/gates.v`. This is the 1-bit version with
a carry in, and it is the block that gets chained to make the 32-bit `ADD`.

Run:

```powershell
. .\env.ps1
.\scripts\sim.ps1 -Project examples/02_adder
```

Pass: the eight-row table printed, ending in `=== tb PASS === all 8 rows match`.

Then, before moving on, run it again with each of these three wrong versions and note which row
catches it. Do not commit them, delete them after.

| Wrong version | What to change | Which row(s) should FAIL |
|---|---|---|
| forgets the carry in | `sum` computed as if `c_in` were 0 | the rows where `c_in = 1` and the result differs |
| `c_out = a & b` | drop the "carry in plus exactly one input" term | `011` |
| `c_out = a \| b` | wrong operator | the row where exactly one input is 1 and `c_in = 1` |

<details>
<summary>Hint, only after 30 minutes stuck</summary>

- `sum` is the XOR of all three inputs
- `c_out` is the majority of the three inputs: any two of them being 1 is enough
- Both are pure combinational logic, so two `assign` statements, no `always`

</details>

### Part 2: `sim/tb_sign.v` (your testbench)

**Start from `sim/README.md`: it is the specification. `tb_sign.v` does not exist; you write it.**

The rules to check, with the eight-bit examples given:

| Rule | What to check | The eight-bit example in the spec |
|---|---|---|
| 5 | Same bits, two readings | `1111_1111` reads 255 unsigned, -1 signed |
| 6 | Sign extension keeps the value | `1111_1111` sign-extends to 16 bits as `1111_1111_1111_1111`, which still reads -1 signed, now 65535 unsigned |

Check 5 needs no RTL at all: it is about which literal you write in the testbench.
Check 6 needs `rtl/sign_extend.v`, which you also write. Its interface is in `sim/README.md`.

## Files

| File | Who writes it |
|---|---|
| `rtl/full_adder.v` | you |
| `rtl/sign_extend.v` | you |
| `sim/tb_adder.v` | me, acceptance for part 1, do not modify |
| `sim/README.md` | me, the specification for part 2 |
| `sim/tb_sign.v` | **you** |

## After it passes

Come back and say which of the three wrong versions was caught by the fewest rows. Then Lesson 3,
where something can finally remember.
