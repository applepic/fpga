# Lesson 03 · `always`, clocks, blocking vs non-blocking / `always`、时钟、阻塞与非阻塞

> Bilingual, 2026-10-28 format: English is the primary text and complete on its own, Chinese
> follows each paragraph as a blockquote. Code, signal names, commands and error messages are
> never translated.
>
> 中英对照。英文是正文，单独读也完整；中文按段落跟在后面，放在引用块里。
> 代码、信号名、命令、报错原文不翻译。
>
> Previous: [[Lesson-02-Binary-Arithmetic]] · Next: Lesson 04, `examples/01_counter`
> （讲义还没写，测试台已经在了）
>
> Exercise: `examples/03_clocked_rules`. Run it today and read the output before you start
> reading this; the printed table is easier to argue with than the text.

---

## 0. One sentence / 一句话

`assign` is a wire; `always` is a block of actions that happen when its trigger fires.

> `assign` 是一根线；`always` 是一块「触发条件成立时执行的动作」。

Until lesson 2 everything was combinational: outputs depended on inputs and nothing remembered
the last value. A processor needs a register (the PC) that keeps its value between cycles. That
is where `always` comes in, and almost every mistake in this lesson comes from forgetting that a
testbench and a design use the same `always` for two different purposes.

> 到第 2 课为止全是组合逻辑：输出只取决于输入，不记得上一次的值。
> 处理器需要 PC 这种「两次时钟之间一直保持」的寄存器，`always` 就是从这里进来的。
> 这一课大部分的坑，来自忘记**测试台和设计用同一个 `always` 干两件不同的事**。

## 1. `always` is an action block, not a description / `always` 是动作块

There are two forms, and the difference is the sensitivity list.

> 两种形式，区别在敏感列表。

```verilog
always @* begin                 // combinational: any input changes, run the body again
    y = sel[1:0];               // blocking = is correct here
end

always @(posedge clk) begin     // sequential: run the body at each rising edge
    q <= d;                     // non-blocking <= is correct here
end
```

> ```verilog
> always @* begin                 // 组合逻辑：任何输入变了就重新执行
>     y = sel[1:0];               // 这里用阻塞 =
> end
>
> always @(posedge clk) begin     // 时序逻辑：每个上升沿执行一次
>     q <= d;                     // 这里用非阻塞 <=
> end
> ```

`always @*` describes a circuit that must react immediately, so its body is re-evaluated
whenever anything it reads changes. `always @(posedge clk)` describes a circuit that samples its
inputs once per clock, and holds its output in between. When a beginner writes a mux with
`posedge`, the output only updates at clock edges, which for a mux is wrong; when they write a
register with `@*`, it latches instead.

> `always @*` 描述一个必须立刻反应的电路：它读到的任何东西一变，整块就重新算。
> `always @(posedge clk)` 描述一个每个时钟周期采样一次、期间保持输出的电路。
> 初学者把 mux 写成 `posedge`，输出就只在时钟沿变，对 mux 来说是错的；
> 把寄存器写成 `@*`，综合器只好给你一个锁存器。

**Rules 1-4** are about the testbench side, and they are all syntax you have already read
without ever being taught. They are in `examples/03_clocked_rules/README.md`, exercised by
`rtl/mux4.v`.

> **规则 1 到 4** 是测试台那边的东西，你已经在 `tb_gates.v` 里看过但没人讲过。
> 在 `examples/03_clocked_rules/README.md` 里，由 `rtl/mux4.v` 对应。

## 2. The clock is a testbench invention, sort of / 时钟：仿真里是测出来的，板子上有

On the board there is a crystal; the Tang Nano 9K runs at 27 MHz, one cycle every 37 ns, and the
`clk` pin gets it as a signal. In simulation nothing clocks anything unless your testbench toggles
a `clk` variable. The standard form is:

> 板子上有晶振，Tang Nano 9K 是 27 MHz，一个周期 37 ns，`clk` 引脚上就是这个信号。
> 仿真里没有晶振，**测试台不翻转 `clk` 就没有时钟**。标准写法：

```verilog
reg clk = 1'b0;
always #5 clk = ~clk;    // toggles every 5 ns, so a rising edge every 10 ns
```

> ```verilog
> reg clk = 1'b0;
> always #5 clk = ~clk;    // 每 5 ns 翻转一次，所以每 10 ns 一个上升沿
> ```

Two things worth noticing before any of this is tested:

> 在测试之前有两件事值得注意：

- **This `always` has no `@` at all.** It is a free-running loop, a simulation device, not
  synthesizable. The design's `always @(posedge clk)` and the testbench's `always #5 clk = ~clk;`
  are the same keyword doing unrelated jobs.
- **The frequency is arbitrary.** 10 ns is chosen so the simulation is short. The circuit cannot
  tell the difference unless something in it counts time, which is a clock divider, not a
  register.

> - **这个 `always` 没有 `@`。** 它是一个自由循环，是仿真工具，不可综合。设计里的
>   `always @(posedge clk)` 和测试台里的 `always #5 clk = ~clk;` 是同一个关键字干两件无关的事。
> - **频率是随便定的。** 取 10 ns 只是为了让仿真快。只要电路里没有东西数时间，电路分不出差别。

## 3. Blocking `=` and non-blocking `<=` / 阻塞与非阻塞

Inside an `always` block, the two assignment operators behave differently in simulation:

> 在 `always` 块里，两个赋值号在仿真中的行为不同：

- `=` is **blocking**: the next line sees the new value, like a C statement.
- `<=` is **non-blocking**: every `<=` in the block reads the value from **before** the edge, and
  the writes land together at the end.

> - `=` 是**阻塞**的：下一行能看见新值，像 C 的一条语句。
> - `<=` 是**非阻塞**的：块里所有的 `<=` 都读**沿之前**的值，写动作在最后一起生效。

The difference only shows when two `<=` in the block depend on each other. A two-register chain
shows it in one line:

> 只有块里两条 `<=` 互相依赖时才看得出区别。两级寄存器链一行就现出来了：

```verilog
// chained: each <= reads the OLD t1, so q gets the previous t1  (correct register behaviour)
always @(posedge clk) begin
    t1 <= d;
    q  <= t1;
end

// blocked: t1 was already updated, so q gets the NEW t1 in the same edge  (two samples collapse)
always @(posedge clk) begin
    t1 = d;
    q  = t1;
end
```

> ```verilog
> // 非阻塞：两条 <= 读的旧 t1，q 拿到的是上一拍的 t1（正确的寄存器行为）
> always @(posedge clk) begin
>     t1 <= d;
>     q  <= t1;
> end
>
> // 阻塞：t1 已经更新了，q 在同一拍拿到新 t1（两级塌成一级）
> always @(posedge clk) begin
>     t1 = d;
>     q  = t1;
> end
> ```

**Rule 8 is this table, and the difference is measured, not argued:** I ran both versions in
iverilog before writing this paragraph. With `t1 <= d; q <= t1;`, `q` follows `d` two cycles
later. With `=` on both lines, `q` follows one cycle later. Phase D's hazard-free pipeline is
built on the difference not being collapsed; this is where it is learned.

> **规则 8 就是这张表，区别是实测的不是讲的**：写这段之前我在 iverilog 里两个版本都跑过。
> 用 `<=`，`q` 比 `d` 晚两拍；两行都用 `=`，`q` 只晚一拍。
> 阶段 D 那条没有冒险的流水线，靠的就是这两级不能塌成一级。

The rule to carry: **`<=` inside `always @(posedge clk)`, `=` inside `always @*`.** The blocking
version of a register compiles, simulates, and produces a design that works in small tests, which
is exactly why it is a rule and not a suggestion.

> 要记住的一条：**`always @(posedge clk)` 里用 `<=`，`always @*` 里用 `=`。**
> 寄存器的阻塞版本能编译、能仿真、小测试里还能过，所以它才必须是规则而不是建议。

## 4. Reset / 复位

A register that comes out of the FPGA's power-up state with an unknown value (`x` in simulation)
is not usable, so it has a reset input. Two styles:

> 上电后初值未知（仿真里是 `x`）的寄存器没法用，所以要有复位。两种风格：

| Style | Where the reset is tested | What happens in simulation |
|---|---|---|
| synchronous | inside `always @(posedge clk)`, `if (rst) q <= 0; else ...` | reset only takes effect at a clock edge |
| asynchronous | `always @(posedge clk or posedge rst)`, `if (rst) q <= 0; else ...` | reset acts immediately, even with no clock |

> | 风格 | 复位在哪里判断 | 仿真里看到什么 |
> |---|---|---|
> | 同步 | `always @(posedge clk)` 里面，`if (rst) q <= 0; else ...` | 复位只在时钟沿生效 |
> | 异步 | `always @(posedge clk or posedge rst)`，`if (rst) ... else ...` | 复位立刻生效，没有时钟也生效 |

**Rules 5-7** are what to write in `rtl/two_regs.v`: synchronous, active high, checked before
`en`. The active level is the design's, so `rst` not `rst_n`; lesson 4's counter uses `rst_n`
active low instead, and the two are not interchangeable.

> **规则 5 到 7** 是 `rtl/two_regs.v` 要写的行为：同步、高有效、`if (rst)` 在 `if (en)` 前面。
> 有效电平是设计自己定的，所以这里是 `rst` 不是 `rst_n`；第 4 课的计数器用低有效的 `rst_n`，
> 两者不能互换。

Nothing in this lesson requires `initial q = 0;` or `reg q = 0;`. Both work in iverilog and in
this FPGA's flow (Gowin parts come up with a defined initial value), but they hide a broken reset
in simulation: the register is already 0, so a reset path that never fires looks correct. Case 0
in the testbench is the row that tells the two designs apart, and its value is yours to decide.

> 这一课不要求 `initial q = 0;` 或 `reg q = 0;`。两者在 iverilog 和这块板子的流程里都能用
> （Gowin 器件有确定的初始值），但它们在仿真里会**掩盖坏的复位**：寄存器本来就是 0，
> 没连上的复位也看不出错。测试台里的 case 0 就是区分这两种设计的那一行，值由你定。

## 5. What the simulator does not tell you / 仿真不会告诉你的事

`always` and `<=` are simulation semantics, and two things follow that cost people real time:

> `always` 和 `<=` 是仿真语义，由此有两件真正浪费时间的事：

- **A design can pass a simulation of this kind and still be wrong on the board.** The clock on
  the board is 27 MHz and the timing constraints are real; the lesson 22 subjects (reset release,
  input synchronisation, clock constraints) exist because a waveform cannot check them.
- **The testbench can be wrong in the same way the design is wrong,** and then the two agree and
  nobody notices. This is why `tb_rule.v` reads its expected values from a table you fill in and
  not from the design's outputs.

> - **过了这种仿真，板子上仍可能是错的。** 板子的时钟是 27 MHz，时序约束是真的；
>   第 22 课那几节（复位释放、输入同步、时钟约束）存在就是因为波形验不了这些。
> - **测试台可能和设计犯同一个错**，于是两边一致，谁也看不出来。这就是
>   `tb_rule.v` 的期望值从**你填的表**里读、而不是从设计输出里读的原因。

## 6. Your task / 你的任务

Three files, `examples/03_clocked_rules/`:

> 三个文件，在 `examples/03_clocked_rules/`：

| File | What |
|---|---|
| `rtl/mux4.v` | combinational `always @*`, rules 1-4 |
| `rtl/two_regs.v` | sequential `always @(posedge clk)`, rules 5-8 |
| `sim/tb_rule.v` | **partly yours**: fill the `x` rows of the expected-value table, and decide the stimulus |

Run:

> 运行：

```powershell
cd C:\Local_Data\Dev\fpga
. .\env.ps1
.\scripts\sim.ps1 -Project examples/03_clocked_rules
```

**Pass condition:** `PART 1 PASS` and `PART 2 PASS`, with `PART 2` passing against a table you
wrote rather than a table I wrote. The console cannot tell the two apart, which is what checkpoint
4 is for, so expect to explain your table.

> **通过条件**：打印出 `PART 1 PASS` 和 `PART 2 PASS`，而且 `PART 2` 是对着**你写的**表过的。
> 控制台分不出表和表是谁写的，这正是 checkpoint 4 要问的，所以准备好解释你的表。

Time budget: 20 minutes reading, the mux is 10 minutes, the register is 10 minutes, the table is
where the time goes.

> 时间：读 20 分钟，mux 10 分钟，寄存器 10 分钟，时间都花在表上。

## 7. Questions / 问题

Write your questions anywhere in this file, right under the paragraph that caused them. I read
the whole file every time. Original words are kept, and answers go where the question is.

> 问题写在这份文件的任何位置，哪一段看不懂就写在下面。我每次都读整篇。
> 原话照抄，回答就地写在问题下面。

### Q1 (I set this one, answer before you move on)

> In `two_regs`, what is the value of `q` at the moment `reset` has just finished and before the
> first clock edge after that? Write the answer as x, 0, or "whatever d was", and say which line
> of your RTL decides it.

> **中文**：`reset` 刚结束、下一个时钟沿还没来之前，`q` 是什么值？
> 回答成 x、0 或者「d 当时的值」，并且指出你的 RTL 里是哪一行决定的。

### Q2

> `two_regs` uses `rst` (active high) and lesson 4's counter uses `rst_n` (active low). Write
> down, in one sentence each, what your `two_regs` does at the moment `rst` changes from 1 to 0,
> and what the counter does at the moment `rst_n` changes from 0 to 1. If your sentence for the
> counter is "it starts working", rewrite it in terms of clock edges.

> **中文**：`two_regs` 用高有效 `rst`，第 4 课的计数器用低有效 `rst_n`。
> 各用一句话写清楚：`rst` 从 1 变 0 的那一刻你的 `two_regs` 做什么；`rst_n` 从 0 变 1 的那一刻计数器做什么。
> 如果计数器那句写成「它开始工作」，用时钟沿重写。
