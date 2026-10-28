# Lesson 1: What you are actually writing in Verilog / 你在 Verilog 里到底在写什么

> **Bilingual format, from 2026-10-28.** English is the primary text and is complete on its own.
> Chinese follows each paragraph as a blockquote, so you read English first and drop into Chinese
> only when a sentence does not land. Code, signal names, commands and error messages are never
> translated.
>
> **中英对照格式，2026-10-28 起。** 英文是正文，单独读也完整。中文按段落跟在后面，
> 放在引用块里。读的时候先读英文，哪句没落地再看中文。代码、信号名、命令、报错原文不翻译。

**This lesson is short, but everything else stands on it.** About 20 minutes.

> 这一课很短，但后面所有内容都建立在它上面。大约 20 分钟。

---

## 1.1 One sentence: you are not writing a program, you are drawing a circuit

> 1.1 一句话：你写的不是程序，是电路

In C, `int x = a + b;` means "the CPU performs one addition right now and stores the result."
It is an **instruction executed in sequence**.

> 在 C 里，`int x = a + b;` 的意思是「CPU 现在做一次加法，把结果存起来」。
> 它是一条**按顺序执行的指令**。

In Verilog, `assign y = a & b;` means "an AND gate **exists** here; its two inputs are wired to
`a` and `b`, and its output is called `y`." It describes **what the circuit looks like**,
not "do this first, then that."

> 在 Verilog 里，`assign y = a & b;` 的意思是「这里**存在**一个与门，两个输入接到 `a` 和 `b`，
> 输出叫 `y`」。它描述的是**电路长什么样**，不是「先做这个，再做那个」。

That difference drives everything that follows:

> 这个区别决定了后面所有内容：

| | C / Python | Verilog |
|---|---|---|
| What you write / 你写的 | A sequence of operations / 一串操作 | A circuit structure / 一个电路结构 |
| When it computes / 什么时候算 | When execution reaches that line / 执行到那一行时 | **Continuously.** Change an input, the output follows / **一直在算**，输入一变输出就跟着变 |
| Meaning of `a = b` | Copy the value of b into a / 把 b 的值拷进 a | Connect a to b with a wire (**order irrelevant**) / 用一根线把 a 连到 b（**顺序无关**） |

**The trap most people hit**: if you come from C, you expect `assign` statements to run in order.
They do not. These two modules are **exactly equivalent**, and synthesise to identical circuits:

> **大多数人踩的坑**：从 C 过来的人会以为 `assign` 是按顺序执行的。并不是。
> 下面这两个模块**完全等价**，综合出来的电路一模一样：

```verilog
// Version one
assign y_and = a & b;
assign y_or  = a | b;

// Version two
assign y_or  = a | b;
assign y_and = a & b;
```

## 1.2 The two most basic words: `wire` and `assign`

> 1.2 最基础的两个词：`wire` 和 `assign`

```verilog
wire y;              // Declare a wire named y
assign y = a & b;    // Connect that wire to the output of an AND gate
```

- **`wire`** is a piece of wire. It **cannot store** anything; it only carries a signal from one point to another.
- **`assign`** is a "continuous assignment". The moment the right side changes, the left side changes.
  **No delay, no clock.**

> - **`wire`** 是一根线。它**存不了**任何东西，只负责把信号从一处送到另一处。
> - **`assign`** 是「连续赋值」。右边一变，左边立刻跟着变。**没有延迟，没有时钟。**

Together these describe **combinational logic**: the output depends only on the current inputs,
and has no memory of what happened before.

> 这两个词合起来描述的是**组合逻辑**：输出只取决于当前的输入，不记得之前发生过什么。

The moment you want memory, you need `always` and a clock. That is Lesson 2.

> 一旦你想要「记得」，就需要 `always` 和时钟。那是第 2 课。

## 1.3 Bitwise operators, and one critical difference

> 1.3 位运算符，以及一个关键区别

> The `4'b1100` notation in this table is explained in **1.4**, right below. If the width-and-base
> syntax is new to you, read 1.4 first and come back.
>
> 这张表里的 `4'b1100` 写法在下面的 **1.4** 讲。如果没见过「位宽 + 进制」这种写法，先读 1.4 再回来。

| Operator | Meaning | Example |
|---|---|---|
| `&` | bitwise AND / 按位与 | `4'b1100 & 4'b1010` = `4'b1000` |
| `\|` | bitwise OR / 按位或 | `4'b1100 \| 4'b1010` = `4'b1110` |
| `^` | bitwise XOR / 按位异或 | `4'b1100 ^ 4'b1010` = `4'b0110` |
| `~` | **bitwise NOT** / **按位取反** | `~4'b1100` = `4'b0011` |

**The critical difference**: Verilog has two kinds of "not".

> **关键区别**：Verilog 有两种「非」。

- `~a` is **bitwise negation**. Every bit flips. `~4'b1100` = `4'b0011`
- `!a` is **logical negation**. It only asks "is this zero?" `!4'b1100` = `1'b0`

> - `~a` 是**按位取反**，每一位都翻。`~4'b1100` = `4'b0011`
> - `!a` 是**逻辑非**，它只问一句「这是不是零」。`!4'b1100` = `1'b0`

Both exist in C too, but many people only ever use `!`.
**In hardware you almost always want `~`**, because you are handling signal lines where every bit matters.

> C 里也有这两种，但很多人一辈子只用过 `!`。
> **硬件里几乎总是要 `~`**，因为你处理的是信号线，每一位都有意义。

Here is that difference with a 4-bit value, measured on this machine:

> 下面是用 4 位信号在本机实测的结果：

```
v=1100  ~v=0011      !v=0
v=1100  v&1010=1000  v&&1010=1
v=0000  ~v=1111      !v=1
v=0000  v&1010=0000  v&&1010=0
```

Read the **width**. `~v` is still 4 bits, every bit flipped. `!v` collapsed the whole bus into one
bit answering a single question: "is this all zeros?"

> 看**位宽**。`~v` 还是 4 位，每一位都翻了。`!v` 把整条总线压成 1 位，
> 只回答一个问题：这是不是全零。

The same split applies to `&&` (logical AND, produces 1 bit) versus `&` (bitwise AND, keeps the original width).
**Use `&` in hardware. Never `&&`.**

> `&&`（逻辑与，出 1 位）和 `&`（按位与，保留原来的位宽）是同一个道理。
> **硬件里用 `&`，不要用 `&&`。**

## 1.4 How to write numbers

> 1.4 数字怎么写

Verilog literals are `<width>'<base><value>`:

> Verilog 的字面量格式是 `<位宽>'<进制><数值>`：

```verilog
4'b1100        // 4-bit binary 1100
8'hFF          // 8-bit hex FF
3'd5           // 3-bit decimal 5
1'b0           // 1 bit, value 0
```

`'b` binary, `'h` hex, `'d` decimal, `'o` octal.

> `'b` 二进制，`'h` 十六进制，`'d` 十进制，`'o` 八进制。

**Always state the width.** A bare `5` is a 32-bit integer. Assigning it to a 4-bit signal truncates it,
and that kind of bug is very hard to find.

> **一定要写位宽。** 裸写一个 `5` 是 32 位整数。把它赋给 4 位信号会被截断，
> 这类 bug 非常难找。

## 1.5 A module is a "chip" in your circuit

> 1.5 一个 module 就是电路里的一块「芯片」

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

> - `module` 到 `endmodule` 之间是盒子内部
> - `input` / `output` 是盒子上的引脚
> - **不要随手改 module 或 port 的名字。** 别的文件（测试台）是按名字找它们的

One `.v` file can hold several modules, but by convention the filename matches the top module.
That is a convention, not a language rule.

> 一个 `.v` 文件可以放好几个 module，但约定俗成文件名和顶层 module 同名。
> 这是约定，不是语言规则。

## 1.6 Simulation: how you know the circuit is correct

> 1.6 仿真：你怎么知道电路是对的

The biggest difference from writing software: **you cannot `printf` in hardware**.

> 和写软件最大的区别：**硬件里没法 `printf`。**

Once the design is on the board, all you can see is six LEDs and one serial port.
If you want to know whether some internal signal is correct, you cannot look at it.

> 设计一旦烧进板子，你能看到的只有六个 LED 和一个串口。
> 想知道某个内部信号对不对，你看不到。

So the industry standard is **simulate first**: run a fake version of the circuit on your computer,
record the value of every signal at every moment, and plot it as a waveform.

> 所以行业标准做法是**先仿真**：在电脑上跑一份电路的假版本，
> 把每个信号在每一刻的值都记下来，画成波形。

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

> **测试台**本身也是 Verilog 写的，但它永远不会被综合成电路。
> 它就是一个程序：驱动输入，检查输出。所以测试台里可以有 `for` 循环、`$display` 打印、
> `#10` 延迟。这些东西在真实硬件里都不存在。

The `tb_` prefix on `tb_*.v` stands for testbench. That is a convention.

> `tb_*.v` 里的 `tb_` 前缀代表 testbench。这是约定。

## 1.7 Summary

> 1.7 小结

| Concept | Remember this |
|---|---|
| `assign` | Continuous assignment. Right side changes, left side follows. **Always computing** / 连续赋值，右边变左边就变，**一直在算** |
| `wire` | Wire. Stores nothing / 一根线，存不了东西 |
| `&` `\|` `^` `~` | Bitwise. **Use `~`, not `!`** / 按位运算，**用 `~` 不用 `!`** |
| Order | `assign` statements inside a module are **order independent** / module 里的 `assign` **顺序无关** |
| Simulation | The only verification tool you have before going to hardware. Use it / 上板之前唯一的验证手段，用它 |

---

## Your task / 你的任务

Implement four gates in `examples/00_gates/rtl/gates.v`:

> 在 `examples/00_gates/rtl/gates.v` 里实现四个门：

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

> 运行：

```powershell
cd C:\Local_Data\Dev\fpga
. .\env.ps1
.\scripts\sim.ps1 -Project examples/00_gates
```

**Right now this reports `Unknown module type: gates`**, because the file does not exist yet. That is your starting point.

> **现在跑会报 `Unknown module type: gates`**，因为文件还不存在。这就是你的起点。

**The pass condition** is seeing

> **通过条件是**看到

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

> 这张表你要能**自己推出来**，不是背下来。
> `y_not` 那列为什么是 1,1,0,0？因为 `~0 = 1`。

Before you type anything, draw the table on paper and then check it against this one.
Deriving it is the point; copying it is not.

> 动手之前先在纸上把这四行画出来，再和这张表对。推出来才有意义，抄没有。

**Come back and tell me when you are done**, and I will set you two questions.
Only after you pass do we move to Lesson 2 (`always` blocks and clocks).

> **做完回来告诉我**，我出两道题。过了才进第 2 课（`always` 和时钟）。

> Hint: four `assign` statements, one per line. Do not use `always`; that is Lesson 2.
> If you are stuck for more than 30 minutes, ask me. Try on your own first.
>
> 提示：四条 `assign`，一行一条。不要用 `always`，那是第 2 课。
> 卡住超过 30 分钟再来问，先自己试。

---

## Questions / 问题

**Write questions anywhere in the vault copy, right where you got stuck.** Not only at the bottom.
Under the paragraph, beside the table, after the code block. Original wording is fine, no formatting
needed, swearing included.

> **写在 vault 副本的任何位置，就地写。** 不是只能写在最下面。
> 读不懂的那一段下面、表格旁边、代码块后面，哪里不懂就在哪里写。原话就行，不用整理格式，骂也行。

`01_Projects/FPGA/Lesson-01-Combinational-Logic.md`

**Read the whole file every turn, not just the tail.** On 2026-10-28 ten questions were inserted
mid-document and only the one at the bottom was answered, because the tail was all that got read.

> **每轮读整篇，不只看末尾。** 2026-10-28 正文中间插了十个问题，只答了末尾那一条，
> 因为只读了末尾。

Answers go **directly under the question**, inside a folded `> [!question]-` callout, with three
fixed parts: the original wording verbatim, a cleaned-up restatement, then the answer. The answer
stays where the question is; it is not moved to a summary section.

> 回答直接插在那句问题下面，收在折叠的 `> [!question]-` 框里，固定三块：
> 原话照抄、整理成规范写法、回答。答案留在原位，不搬到别处汇总。

**Language inside the callout follows the original wording.** If the question mixes in English
(`plot出wave`, `tb`, `module`), the restatement is written as a full English sentence. If it is pure
Chinese, the restatement stays Chinese. Never translate an English technical term into Chinese.

> **框内语种跟着原话走。** 原话里夹了英文（`plot出wave`、`tb`、`module`），整理就整句写成英文；
> 原话是纯中文，整理保持中文。不把英文术语翻成中文。
