# Specification for `tb_sign.v`: your first testbench

This file says what a correct `tb_sign.v` must do. It is the contract both of us work from: you
write `tb_sign.v` from it, and I keep a second, hidden testbench written from the same text. When
the two disagree, the disagreement points at one copy of this file going stale, not at "one of the
testbenches is right". The reason is in `lessons/README.md`, checkpoint 4.

Every rule below is one that I ran in iverilog before shipping this file, so it is a measured
statement about this simulator, not Verilog textbook prose. The commands are in the lesson.

## Two rules are being checked

### Rule 5: the same eight bits, two readings

In Verilog the bits do not change, only how you read them does:

```verilog
reg [7:0]        u;   // unsigned: 8'hFF reads as 255
reg signed [7:0] s;   // signed:   8'hFF reads as -1
```

**The test must show that difference.** The obvious way to write it is

```verilog
u = 8'hff;
s = 8'hff;
if (u !== s) ...
```

and that can never fail, because `!==` compares the eight bit values, which are equal by
construction. A test that cannot fail proves nothing.

**So the test has to make the comparison a number comparison.** In Verilog the sign of a
comparison is decided by the operands: if both sides are signed regs, both are read as signed
numbers and the 8-bit one is sign-extended to the wider width. If either side is unsigned, the
whole comparison goes unsigned and every operand is zero-extended. Two consequences:

- `if (u !== s)` is unsigned, so `s` is zero-extended: `1111_1111` reads 255 on both sides
- `if (s !== -1)` compares a signed reg with an unsized literal, which is a plain number, so it
  reads `s` signed correctly

**Required cases**, taken from the rule-5 table in the lesson:

| Bits | Unsigned reading | Signed reading |
|---|---|---|
| `8'h00` | 0 | 0 |
| `8'h7f` | 127 | 127 |
| `8'h80` | 128 | -128 |
| `8'hff` | 255 | -1 |

Write each case so that deleting `signed` from the declaration of `s` makes it fail. That is the
only evidence that the test is testing rule 5 rather than the `!==` operator.

**How to see the mechanism for yourself, without me telling you the answer.** Make a tiny
testbench that assigns `8'hff` to both `u` and `s`, prints `u` with `%0d` and `s` with `%0d`, and
runs. Print should show 255 and -1 (the `%0d` of a signed variable reads it signed; that part I
did run). Then delete `signed` and run again. If the two printed numbers are the same both times,
your testbench is not doing the conversion and the problem is in the width, not the value.
"print it, look, delete `signed`, look again" is the method.

### Rule 6: sign extension keeps the value

`assign y = {{8{x[7]}}, x};` is a sign extension written in Verilog. The specification states what
it must do in terms of values, not bits:

| `x` | `y` must read as, signed | `y` must read as, unsigned |
|---|---|---|
| `8'hff` (-1) | -1 | 65535 |
| `8'h80` (-128) | -128 | 65408 |
| `8'h40` (64) | 64 | 64 |
| `8'h00` (0) | 0 | 0 |

**The test to write.** Declare two signed registers next to the DUT wires, one per width, and
compare THEM:

```verilog
reg signed [7:0]  sx;
reg signed [15:0] sy;
...
x = 8'hff; #1;      // #1 lets the combinational output settle, as in tb_gates.v
sx = x;  sy = y;
if (sx !== sy) $display("FAIL: sign extension changed the value");
```

Both sides are signed, so the comparison is a signed number comparison and the narrow one is
sign-extended: perfect for the check, useless for showing the bug in your own RTL, because the
same mechanism is then used twice. That is exactly why the unsigned column of the table exists
and why it goes into a separate check:

```verilog
if (y !== 16'd65535) $display("FAIL: 8'hff extended to %0d, expected 65535 unsigned", y);
```

`y` is an unsigned 16-bit wire, so the 16-bit literal is compared bit for bit and this catches
the case where the top eight bits are not copies of `x[7]`. Run your own design once with the
top eight bits forced to 0 (`{8'h00, x}`) and look at which of these two checks reports it. That
is the lesson inside the lesson.

**Required cases:** all four rows of the table. Negative, positive, zero, and a value whose sign
bits are not all ones (`8'h80`). State in your file, as a comment, what each case is there to
catch. A case list without that column is guessing.

## `rtl/sign_extend.v` interface

```verilog
module sign_extend (
    input  wire [7:0]  x,
    output wire [15:0] y
);
```

Combinational, no clock and no `always`. When your `tb_sign.v` passes, come and tell me.

## What happens after you say "done"

I run my hidden testbench, written from this file, with different values from the spec (`8'hc0`,
`8'h01`, `8'h3f`, ...). If the two disagree we find out why before you move on. That is why the
hidden one is announced up front rather than kept a secret.
