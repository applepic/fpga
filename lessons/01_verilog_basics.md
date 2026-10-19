# Lesson 1: What you are actually writing in Verilog

**This lesson is short, but everything else stands on it.** About 20 minutes.

---

## 1.1 One sentence: you are not writing a program, you are drawing a circuit

In C, `int x = a + b;` means "the CPU performs one addition right now and stores the result."
It is an **instruction executed in sequence**.

In Verilog, `assign y = a & b;` means "an AND gate **exists** here; its two inputs are wired to
`a` and `b`, and its output is called `y`." It describes **what the circuit looks like**,
not "do this first, then that."

That difference drives everything that follows:

| | C / Python | Verilog |
|---|---|---|
| What you write | A sequence of operations | A circuit structure |
| When it computes | When execution reaches that line | **Continuously.** Change an input, the output follows |
| Meaning of `a = b` | Copy the value of b into a | Connect a to b with a wire (**order irrelevant**) |

**The trap most people hit**: if you come from C, you expect `assign` statements to run in order.
They do not. These two modules are **exactly equivalent**, and synthesise to identical circuits:

```verilog
// Version one
assign y_and = a & b;
assign y_or  = a | b;

// Version two
assign y_or  = a | b;
assign y_and = a & b;
```

## 1.2 The two most basic words: `wire` and `assign`

```verilog
wire y;              // Declare a wire named y
assign y = a & b;    // Connect that wire to the output of an AND gate
```

- **`wire`** is a piece of wire. It **cannot store** anything; it only carries a signal from one point to another.
- **`assign`** is a "continuous assignment". The moment the right side changes, the left side changes.
  **No delay, no clock.**

Together these describe **combinational logic**: the output depends only on the current inputs,
and has no memory of what happened before.

## 1.3 Bitwise operators, and one critical difference

| Operator | Meaning | Example |
|---|---|---|
| `&` | bitwise AND | `4'b1100 & 4'b1010` = `4'b1000` |
| `\|` | bitwise OR | `4'b1100 \| 4'b1010` = `4'b1110` |
| `^` | bitwise XOR | `4'b1100 ^ 4'b1010` = `4'b0110` |
| `~` | **bitwise NOT** | `~4'b1100` = `4'b0011` |

**The critical difference**: Verilog has two kinds of "not".

- `~a` is **bitwise negation**. Every bit flips. `~4'b1100` = `4'b0011`
- `!a` is **logical negation**. It only asks "is this zero?" `!4'b1100` = `1'b0`

Both exist in C too, but many people only ever use `!`.
**In hardware you almost always want `~`**, because you are handling signal lines where every bit matters.

The same split applies to `&&` (logical AND, produces 1 bit) versus `&` (bitwise AND, keeps the original width).
**Use `&` in hardware. Never `&&`.**

## 1.4 How to write numbers

Verilog literals are `<width>'<base><value>`:

```verilog
4'b1100        // 4-bit binary 1100
8'hFF          // 8-bit hex FF
3'd5           // 3-bit decimal 5
1'b0           // 1 bit, value 0
```

`'b` binary, `'h` hex, `'d` decimal, `'o` octal.

**Always state the width.** A bare `5` is a 32-bit integer. Assigning it to a 4-bit signal truncates it,
and that kind of bug is very hard to find.

## 1.5 A module is a "chip" in your circuit

```verilog
module gates (
    input  wire a,
    input  wire b,
    output wire y_and
);
    assign y_and = a & b;
endmodule
```

- Everything between `module` and `endmodule` is the inside of the box
- `input` / `output` are the pins on the box
- **Do not rename the module or its ports casually.** Other files (testbenches) find them by name

One `.v` file can hold several modules, but by convention the filename matches the top module.
That is a convention, not a language rule.

## 1.6 Simulation: how you know the circuit is correct

The biggest difference from writing software: **you cannot `printf` in hardware**.

Once the design is on the board, all you can see is six LEDs and one serial port.
If you want to know whether some internal signal is correct, you cannot look at it.

So the industry standard is **simulate first**: run a fake version of the circuit on your computer,
record the value of every signal at every moment, and plot it as a waveform.

```
your circuit (rtl/*.v)  +  testbench (sim/tb_*.v)
                              |
                         iverilog compile
                              |
                          vvp run
                              |
                    printed text + tb.vcd waveform
```

A **testbench** is itself written in Verilog, but it is never synthesised into a circuit.
It is just a program: it drives the inputs and checks the outputs. That is why a testbench can contain
`for` loops, `$display` printing, and `#10` delays. None of those exist in real hardware.

The `tb_` prefix on `tb_*.v` stands for testbench. That is a convention.

## 1.7 Summary

| Concept | Remember this |
|---|---|
| `assign` | Continuous assignment. Right side changes, left side follows. **Always computing** |
| `wire` | Wire. Stores nothing |
| `&` `\|` `^` `~` | Bitwise. **Use `~`, not `!`** |
| Order | `assign` statements inside a module are **order independent** |
| Simulation | The only verification tool you have before going to hardware. Use it |

---

## Your task

Implement four gates in `examples/00_gates/rtl/gates.v`:

```verilog
module gates (
    input  wire a,
    input  wire b,
    output wire y_and,   // a & b
    output wire y_or,    // a | b
    output wire y_xor,   // a ^ b
    output wire y_not    // ~a
);
```

Run:

```powershell
cd C:\Local_Data\Dev\fpga
. .\env.ps1
.\scripts\sim.ps1 -Project examples/00_gates
```

**Right now this reports `Unknown module type: gates`**, because the file does not exist yet. That is your starting point.

**The pass condition** is seeing

```
  a  b | and  or  xor  not
-------+------------------
  0  0 |  0    0    0    1
  0  1 |  0    1    1    1
  1  0 |  0    1    1    0
  1  1 |  1    1    0    0

=== ALL PASS ===
```

You must be able to **derive this table yourself**, not memorise it.
Why is the `y_not` column 1,1,0,0? Because `~0 = 1`.

**Come back and tell me when you are done**, and I will set you two questions.
Only after you pass do we move to Lesson 2 (`always` blocks and clocks).

> Hint: four `assign` statements, one per line. Do not use `always`; that is Lesson 2.
> If you are stuck for more than 30 minutes, ask me. Try on your own first.
