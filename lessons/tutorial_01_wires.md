# ZipCPU 教程 · 第 1 课 · Wires，与组合逻辑

> Source: [Verilog, Formal Verification and Verilator Beginner's Tutorial](https://zipcpu.com/tutorial/),
> lesson 1, `lsn-01-wires.pdf`, 51 pages, by Daniel Gisselquist. Original slides are CC/public domain
> for the examples; this is a restructuring, not a copy.
>
> 来源：ZipCPU 教程第 1 课（51 页，Daniel Gisselquist）。这里是把那 51 张幻灯片重写成可读的一课，
> 不是复制原文，也不含他给出的完整答案代码。

## 0. 这一课要拿到什么 / What you get from this lesson

三件事，原文第 2 页的 Objectives 原文就是这三条：

1. 对**组合逻辑**（combinational logic）有一点基本的手感
2. 会用工具把设计**综合并烧到板子上**
3. 第一个设计在板子上跑起来

> The original slide lists exactly these: a basic feel for combinational logic, learning to run the
> tools, and getting a first design running on the board.

这一课不写测试台，不写时钟，也不写 `reg`。整课只有一个东西：`wire`。

> No testbench, no clock, no `reg` in this lesson. One concept only: `wire`.

## 1. 第一个设计：一根线 / Your first design: one wire

原文第 3 页给出的完整设计只有五句话：

> The whole design on slide 3 is five lines:

```verilog
module thruwire(i_sw, o_led);
	input	wire	i_sw;
	output	wire	o_led;

	assign	o_led = i_sw;
endmodule
```

逐句说清楚，这五句是后面二十几课的基本骨架：

> Line by line, because this skeleton is the shape of every later design:

| 这一句 | 在说什么 |
|---|---|
| `module thruwire(i_sw, o_led);` | 定义一个叫 `thruwire` 的模块，括号里是它对外露出的**端口**（ports）。Verilog 文件里放模块，一个文件放一个模块最好，原文第 4 页明确建议这么做 |
| `input wire i_sw;` | `i_sw` 是输入端口，类型 `wire` |
| `output wire o_led;` | `o_led` 是输出端口，类型 `wire` |
| `assign o_led = i_sw;` | 把 `o_led` 永久接到 `i_sw` 上，`assign` 是「连一根线」，不是「执行一次赋值」 |
| `endmodule` | 模块结束 |

> Note the port naming convention, which the whole tutorial keeps: `i_` for input, `o_` for output,
> `w_` for an internal wire. Following it means you never have to guess a signal's direction while
> debugging 300 lines of someone else's code later.

原文还带了 `\`default_nettype none`，在 `module` 之前。它让「用了没声明的线」变成编译错误而不是
悄悄生成一根线。**但这一课先不加**：你现在还在学语法，先让它悄悄帮你兜住拼写错误，等第 3 课你写
状态机的时候再加。原文加了它，是作者给有经验的工程师写的默认做法。

> The original adds `` `default_nettype none `` before the module, which turns an undeclared wire into
> a compile error instead of a silent implicit wire. Not in this lesson: you are still learning
> syntax, and a silent auto-wire is the friendlier failure for now. Added in lesson 3.

## 2. 板子那边：约束文件 / The board side: constraints

FPGA 不知道你的 `i_sw` 在哪个引脚上。原文第 5 到 8 页就在讲这件事：设计写完只是「纸上的电路」，
还要告诉工具「这个端口接第几号引脚」，这个信息放在**约束文件**里（原文用 iCE40 的 `.pcf` 格式）。

> The FPGA does not know which pin your port should be on. Slides 5-8 cover exactly this: the design
> is a paper circuit until a constraint file says "this port lives on pin N". The original uses the
> iCE40 `.pcf` format; the Tang Nano 9K uses `.cst`.

本仓库的约束文件是 `constraints/tangnano9k.cst`，里面对应的两行是：

> This repo already has the board file; the two lines that matter here:

```text
IO_LOC  "btn[0]" 4;
IO_LOC  "led[0]" 10;
```

`IO_LOC` 是命令，引号里是端口名，最后的数字是引脚号。板子上 `btn[0]` 是按键（按下为低电平），
`led[0]` 是第一个 LED（低电平点亮）。原文的 `i_sw` 就是我们的 `btn[0]`，原文的 `o_led` 就是我们的 `led[0]`。

> `IO_LOC` is the command, the quoted name is the port, the number is the pin. On this board
> `btn[0]` is a button that reads low when pressed, and `led[0]` is an LED that lights when driven low.

## 3. 你的任务 / Your task

不是抄上面那五句。任务分三步，每一步都要看到结果：

> Not copying the five lines above. Three steps, each with a result you can see:

**第 1 步：写 `rtl/thruwire.v`。** 模块名必须是 `thruwire`，端口名必须是 `i_sw` 和 `o_led`，
位宽都是 1 位。内容由你按要求写，但**这次给了一次完整的参考**，因为原文第 3 页也是直接给的：
`thruwire` 就是把 `o_led` 连到 `i_sw`，多一行都是多余。这一步的重点不是这个模块，而是第 2 步和第 3 步。

> Step 1: write `rtl/thruwire.v`, module `thruwire`, ports `i_sw` and `o_led`, one bit each. This one
> is given in full because the original gives it in full on slide 3; the point of the lesson is the
> next two steps.

**第 2 步：写 `rtl/top.v`，把它接到板子上。** 这是这一课真正的作业。`top` 模块的端口必须是
`input wire [1:0] btn` 和 `output wire [5:0] led`，因为约束文件里就是这两个名字（见第 2 节那两行）。

> Step 2 is the real homework: a `top` module with ports `input wire [1:0] btn` and
> `output wire [5:0] led`, which is what the board file expects.

有两处要你自己想明白，我不给答案：

1. `btn` 是 2 位，`i_sw` 是 1 位，**怎么只取其中一位**接过去
2. 板子上 LED 是低电平点亮，按键按下也是低电平，那么「按下键，灯亮」时，`i_sw` 和 `o_led`
   之间还需不需要取反？**为什么**？

> Two things to work out yourself: how to pass one bit of a 2-bit input into a 1-bit port, and
> whether the active-low LED and active-low button mean a `~` is needed somewhere. Answer the second
> in your own words; a wrong reason here shows up in lesson 7's debouncing.

**第 3 步：跑起来，两遍。**

> Step 3: run it, twice.

```powershell
cd C:\Local_Data\Dev\fpga
```

`cd` 切到项目目录。

> switches the current folder to the project.

```powershell
. .\env.ps1
```

`env.ps1` 把工具链加载进当前终端。

> loads the toolchain into this terminal.

```powershell
.\scripts\build.ps1 -Project examples/tutorial/01_wires
```

`build.ps1` 是构建脚本，`-Project` 指定练习目录。它会依次做综合（yosys）、布局布线（nextpnr）、
生成位流，全部成功才算过。

> synthesises, places and routes, and writes the bitstream.

```powershell
.\scripts\flash.ps1 -Project examples/tutorial/01_wires
```

`flash.ps1` 把位流写进板子（`openFPGALoader`）。写完按 `btn[0]`，`led[0]` 应该跟着亮灭。

> writes the bitstream to the board. Press `btn[0]`; `led[0]` follows.

## 4. 通过条件 / What "pass" looks like

1. `build.ps1` 有 `success` 输出，不是报错
2. 板子上按 `btn[0]`，`led[0]` 跟着变
3. 你能回答第 3 步里那两个问题，并且回答得出**为什么**，不是「试出来的」

> Three things: the build succeeds, the LED follows the button, and you can answer the two questions
> with a reason.

## 5. 问题 / Questions

写在下面任何一句看不懂的地方下面，回答就长在那句话下面。

> Write questions under whatever sentence lost you; the answer goes there.

### Q1

> 原文第 45 页有个例子：`assign o_irq = |i_irq_source;`，其中 `i_irq_source` 是 8 位。
> 这一句的作用是什么？`|` 放在信号名**前面**和放在两个信号**中间**，含义有什么不同？

### Q2

> 原文说「`wire` 没有记忆，环状逻辑或者反馈是非法的」。用你自己的话解释：为什么
> `assign a = b; assign b = a;` 这种写法在硬件里不可能成立？

### Q3

> 板子上按键和 LED 都是低电平有效，你的 `top` 里有没有某个地方需要取反？给出你的判断和理由。
