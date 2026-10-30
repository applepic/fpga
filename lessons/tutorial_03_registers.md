# ZipCPU 教程 · 第 3 课 · 寄存器与 blinky

> Source: [ZipCPU beginner tutorial](https://zipcpu.com/tutorial/), lesson 2, `lsn-02-regs.pdf`,
> 37 slides. This tutorial file is split in two, as lesson 1 was: this half is slides 1-27 (registers,
> latches, flip flops, blocking, blinky, parameters, traces). The second half is Tutorial 04 (strobe,
> the two PPS designs, stretch, timing, dimmer).
>
> 来源：ZipCPU 教程第 2 课（37 页）。和前两课一样拆成两半：这里对应第 1 到 27 张幻灯片。

## 0. 这一课要拿到什么

原文第 2 页的目标：会用寄存器做组合逻辑、会写时钟同步逻辑、明白寄存器能「记住」东西、知道系统时钟
从哪来、知道时序检查为什么重要。

> The source's objectives: build combinational logic with registers, build clocked logic, understand
> that registers remember, know where the system clock comes from, and know why timing checks matter.

## 1. 为什么需要寄存器

原文第 3 页一句话：**线没有记忆，只有寄存器能存状态**。

> Slide 3: wires have no memory, and only registers can hold state.

到这里是这一课真正的新东西。之前所有东西 `wire`、`assign`、异或、拼位，都是「输入变了，输出立刻跟着变」。
时钟一来，「记住上一个值」这件事就没法用线表达了。`always` 有两种写法，对应两种硬件：

> Everything up to here was combinational: the output follows the input immediately. Holding a value
> across a clock edge needs a register, and there are two forms:

| 形式 | 写法 | 硬件 |
|---|---|---|
| 组合 | `always @(*)` 里面用 `=` | 和 `assign` 一样，没有记忆 |
| 同步 | `always @(posedge i_clk)` 里面用 `<=` | 触发器，只在时钟上升沿更新 |

> Combinational uses `always @(*)` with `=`; synchronous uses `always @(posedge i_clk)` with `<=`.

**只有 `always` 里面能赋值给 `reg`。** 反过来，`wire` 只能被 `assign` 驱动。这两句话是 Verilog 里最容易
混淆的一处，记住它的理由：`reg` 是一个「在过程块里被赋值的变量」的声明，不代表它会变成寄存器。

> `reg` means "a variable a procedural block assigns". It does not mean "a register". A `reg` inside
> `always @(*)` becomes wires and gates, and a `reg` inside `always @(posedge clk)` becomes a flip
> flop. The source says the same thing in fewer words on slide 4.

## 2. 组合 `always`

原文第 4 到 5 页：

> Slides 4-5:

```verilog
always @(*)
begin
	o_led = A ^ i_sw;
	o_led = o_led + 7;
	if (i_reset)
		o_led = 0;
end
```

这段看起来像软件，仿真里也像软件一样一句一句执行，但**硬件里这三句同时生效**，只有最后一句的结果留下来。
原文叫它「最后赋值获胜」（Last Assignment Wins）。这带来一个非常有用的写法，原文第 7 页：

> It looks like software and behaves like software in a simulator, but in hardware all three happen at
> once and the last one wins. That gives a pattern (slide 7):

```verilog
always @(*)
begin
	o_R = 0;          // defaults first
	if (i_S)
		o_R = i_V;    // then the interesting case
end
```

先给默认值，再按条件覆盖。**不这么写会出事**，原文第 6 页的例子：

> Give the default first, then override. Without the default you get a latch (slide 6):

```verilog
always @(*)
	if (i_S)
		o_R = i_V;    // and nothing says what happens when i_S == 0
```

`i_S` 是 0 的时候 `o_R` 该是多少？代码没说，硬件就必须「记住上一次的值」。这就是锁存器（latch）。
原文的态度很直接：**别用锁存器**。大多数 FPGA 不支持它，支持的地方也容易和仿真对不上。

> When `i_S` is 0 the code does not say what `o_R` is, so the hardware has to remember the last value.
> That is a latch. The source's instruction is to avoid latches: most FPGAs do not support them, and
> where they exist they behave differently in hardware than in simulation.

## 3. 同步 `always`

原文第 8 到 13 页，这一节是整课最重要的 6 张幻灯片：

> Slides 8-13, the most important stretch in the lesson:

```verilog
reg [9:0] A;
always @(posedge i_clk)
	A <= A + 1'b1;
```

三条规则：

> Three rules:

1. `<=` 是**非阻塞**赋值。同一个时钟沿上，右边读的是旧值，然后所有寄存器一起更新
2. 只有真正的时钟边沿可以用在 `posedge` 里，不要用它自己逻辑里造出来的信号当时钟
3. `always @(posedge i_clk)` 里一律用 `<=`

> `<=` is non-blocking: the right-hand side reads the old value, then every register updates at once.
> Only a real clock edge belongs in `posedge`. Inside a clocked block, always use `<=`.

原文用两张幻灯片演示差别，假设 `A` 从 0 开始：

> Two slides show the difference, with `A` starting at 0:

| 写法 | 一个时钟沿之后 `A` | 为什么 |
|---|---|---|
| `A <= 5; A <= A + 1;` | 1 | 两条右边都读旧值：`A <= 5` 被后一条覆盖，`A <= 0 + 1` 生效 |
| `A = 5; A = A + 1;` | 6 | 阻塞赋值，第一句已经把 `A` 改成 5，第二句读到的是 5 |

> With `<=` the first assignment is over-written before it is applied and `A` becomes 1. With `=`
> the first line really changed `A`, so the second reads 5 and `A` becomes 6.

还有更坏的情况，原文第 12 页：两个 `always` 块，一个用 `=` 改 `A`，另一个用 `<=` 读 `A`。
结果**取决于仿真器的执行顺序**，`B` 可能是 0 也可能是 6，而硬件只有一个确定的答案。
原文的话是「不要这样做」。

> Slide 12: a second block reading `A` across a blocking assignment gives a result that depends on
> simulation order. It can be 0 or 6, while the hardware has one answer. Do not do it.

## 4. blinky：第一个有用的时序电路

原文第 16 页，整个设计六行：

> Slide 16, the whole design in six lines:

```verilog
module blinky(i_clk, o_led);
	parameter WIDTH = 27;

	input  wire i_clk;
	output wire o_led;

	reg [WIDTH-1:0] counter;
	initial counter = 0;

	always @(posedge i_clk)
		counter <= counter + 1'b1;

	assign o_led = counter[WIDTH-1];
endmodule
```

读它的顺序：`counter` 每个时钟加一，位宽决定多久回绕一次；`o_led` 接最高位，所以每半个周期变一次。

> The counter adds one per clock; its width decides how often it wraps; the LED is the top bit, so it
> flips every half wrap.

**`initial counter = 0;` 这里必须有。** 原文第 16 页的原设计里就有这一句。原因和仿真有关：寄存器没有初值的话，
仿真里它的值是 `x`（未知），而 `x + 1` 还是 `x`，LED 永远是 `x`。板子上 FPGA 上电时寄存器会清零，
所以这一句在板子上可有可无，在仿真里没有就看不到任何东西。

> `initial counter = 0;` is in the source's design and it is not optional here. Without it the register
> simulates as `x`, and `x + 1` is `x` forever. On the board the FPGA clears registers at power-up, so
> the line matters only to the simulator, which is exactly where it matters most.

原文第 17 页还列了一个初学者常见错误：把 `counter` 声明成 1 位。这样 LED 只在半个时钟周期里翻转，
27 MHz 下看不出来，灯看起来是半亮的。

> Slide 17's beginner mistake: a one-bit counter makes the LED flip at half the clock rate, which at
> 27 MHz is invisible and looks like a dim LED.

## 5. 参数：让同一个设计跑不同的速度

原文第 20 到 21 页。仿真 27 位计数器太慢（2^27 个时钟才翻一次），所以把位宽做成参数，仿真时改小：

> Slides 20-21. A 27-bit counter is far too slow to simulate, so the width becomes a parameter:

```verilog
parameter WIDTH = 27;
reg [WIDTH-1:0] counter;
assign o_led = counter[WIDTH-1];
```

这里原文用的是 Verilator 的 `-GWIDTH=12`。**本仓库用 iverilog，对应的写法是测试台里实例化时覆盖参数**：

> The source overrides it with Verilator's `-GWIDTH=12`. With iverilog the override happens at
> instantiation, in the testbench:

```verilog
blinky #(.WIDTH(8)) u_dut(.i_clk(i_clk), .o_led(o_led));
```

这也是为什么参数比直接改常数好：**同一份 RTL，板子上用 27，仿真里用 8，不用改源码，也不会出现两边不一致。**

> One file, 27 on the board and 8 in simulation, with no edit and no chance of the two drifting apart.

## 6. 你的任务

`examples/tutorial/03_registers/`。

**我给的**：`rtl/blinky.v`（原文第 16 页那个设计，加了 `parameter WIDTH`）和 `sim/tb_blinky.v`
（我的验收测试台，它把 `WIDTH` 覆盖成 8，在 400 个时钟沿里检查计数器的起止和 LED 的翻转时刻）。

**你要写的**：`rtl/strobe.v`，原文第 28 页的设计，一模一样：

> The source's design on slide 28, which you write:

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

三个要点，你要能说清楚：

> Three things you have to be able to explain:

1. `&` 放在信号前面是什么运算？和放在两个信号中间有什么不同？（第 2 课 Q1 问过 `|`，这里是同一个问题）
2. `&counter[26:24]` 在 27 MHz 下多久为 1 一次？**算出来**，别猜
3. 这段代码里没有 `initial`。仿真里 `counter` 会是 `x`，那么 `o_led` 会是什么？为什么？

> 1 asks what a reduction operator is, 2 asks you to compute the period rather than guess it, and
> 3 asks what the missing `initial` does to simulation, which is the lesson's own warning from slide 16.

写完跑我的测试台，再自己加一个 `sim/tb_strobe.v`：

> Run mine, then add `sim/tb_strobe.v` of your own:

```powershell
cd C:\Local_Data\Dev\fpga
```

`cd` 切到项目目录。

```powershell
. .\env.ps1
```

`env.ps1` 加载工具链。第一个点是 dot-source 运算符，第二个点属于 `.\`。

```powershell
.\scripts\sim.ps1 -Project examples/tutorial/03_registers
```

`sim.ps1` 是仿真脚本，`-Project` 指定练习目录。你自己的测试台要能证明 `o_led` 每 2^24 个时钟沿才为 1
一次，而且为 1 的时间是对称的一段时间，不是一个沿。

> Your testbench has to show the LED is high for a contiguous run of edges every 2^24 edges, not for a
> single edge.

## 7. 通过条件

1. `tb_blinky` 打印 `=== tb PASS ===`
2. `tb_strobe` 打印通过，并且它检查的是「连续 2^24 个沿里前 2^24 / 8 个为 1」这类可算的东西
3. 你能回答第 6 节的三个要点，第 2 点给出具体数字

> The third one is the one I will ask about with the numbers.

## 8. 问题

### Q1

> 原文第 10 页：`A <= 5; A <= A + 1'b1;` 一个沿之后 `A` 是 1，不是 6。用你自己的话解释这个 1
> 是怎么来的。

### Q2

> `&counter[26:24]` 为 1 的**概率**是多少？为 1 的时间占多少？两个答案不一样，说出为什么。

### Q3

> 原文说「别用锁存器」，举的理由有两条：多数 FPGA 不支持，以及仿真和硬件可能不一致。用你的
> `strobe.v` 举例说明：如果去掉 `assign` 那一行里的某一部分，什么时候会生成锁存器？

### Q4

> 板子上电时寄存器是 0，仿真里不写 `initial` 就是 `x`。这个差别会怎么骗过你？举一个你觉得最可能
> 发生的场景。
