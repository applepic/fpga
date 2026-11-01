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

> [!question]- 提问 · sw 是什么，为什么这样命名
> **原话**
> sw是什么东西，为什么这样命名
>
> **整理**
> What is `sw`, and why is the signal named that way?
>
> **回答**
> `sw` 是 switch，原文那块板子上是一个拨动开关。我们这块 Tang Nano 9K 没有开关，只有两个按键，
> 所以同一个信号在这里叫 `btn[0]`。名字是从原文照搬的，功能没变：一个输入，一根线接到 LED。
>
> 名字里的 `i_` 和 `o_` 是作者的命名习惯：`i_` 开头是输入，`o_` 开头是输出，`w_` 开头是内部线。
> 原文的代码从头到尾这么写（第 1 课后半的 `w_internal`，第 10 课的 `w_wr`、`w_rd`）。
> Verilog 不强制，写成 `a` 和 `b` 电路一模一样。它的用处是读代码时不用翻回端口声明就知道方向，
> 第 7 课以后一个模块几十根线，这个差别会很明显。
>
> `thruwire` 是 through wire，直通线。

> [!question]- 提问 · assign 左右两边能不能对调
> **原话**
> assign 后面的意义所以可以是o在前也可以i在前
>
> **整理**
> 所以 `assign` 后面写 `o` 在前可以，写 `i` 在前也可以？
>
> **回答**
> 不能对调。`assign 左边 = 右边` 的意思是「用右边驱动左边」，左边必须是可以被驱动的东西：
> 一根 `wire`，包括 `output wire`。`i_sw` 是 `input`，它的值来自芯片外面的引脚，
> 设计内部不能去驱动它。
>
> 实测（2026-11-01），把 `assign o_led = i_sw;` 写成 `assign i_sw = o_led;`：
>
> | 谁 | 结果 |
> |---|---|
> | `iverilog` 编译 | 退出码 0，两行 warning：`input port i_sw is coerced to inout`、`output port o_led is coerced to inout` |
> | `iverilog` 仿真 | `led[0]` 恒为 `z`（高阻），按键怎么按都不动 |
> | `build.ps1` | 走完全程，3 个 IOB，位流照出，没有 error |
> | 综合后的网表仿真 | `led[0]` **跟着 `btn[0]` 变**，和正确写法一样 |
>
> 最后一行是这件事里最值得记住的地方：**yosys 把 `assign` 的两端当成同一根线**，方向写反了它不报错，
> 直接把线接上。所以板子上灯会亮，仿真里却是 `z`。两个工具对同一份代码给出了不同答案，
> 而「板子上能用」并不能证明代码写对了。
>
> 一句话：**左边写你要驱动的东西，右边写你要读的东西。**
>
> 这一条也解释了为什么仿真和上板都要做。仿真抓的是语言规则，综合抓的是能不能变成电路；
> 两边不一致，通常是代码踩到了规则边界，不是工具坏了。
>
> 如果你问的是端口列表的顺序（`module thruwire(i_sw, o_led)` 能不能写成 `(o_led, i_sw)`）：
> 可以，顺序自由。但按位置连接时（`thruwire u(btn[0], led[0])`），实参顺序必须和它一致。
> 这个练习用按名字连接，所以顺序无所谓。

逐句说清楚，这五句是后面二十几课的基本骨架：

> Line by line, because this skeleton is the shape of every later design:

| Line | What it says |
|---|---|
| `module thruwire(i_sw, o_led);` | Defines a module named `thruwire`; the names in parentheses are its **ports**. One module per file is best, and slide 4 says so explicitly |
| `input wire i_sw;` | `i_sw` is an input port of type `wire` |
| `output wire o_led;` | `o_led` is an output port of type `wire` |
| `assign o_led = i_sw;` | Connects `o_led` to `i_sw` permanently. `assign` is "solder a wire", not "run an assignment once" |
| `endmodule` | Ends the module |

> `assign` 那一行是整课的重点：两个名字被永久接在一起，接上就一直有效。它没有「执行一次」的意思，
> 所以和顺序、和执行次数都无关。

整个教程的端口和信号都按方向起名：`i_` 是输入，`o_` 是输出，`w_` 是内部线。照着做，以后读别人
三百行代码时不用翻回声明就知道方向。这条习惯只出现在原文的示例代码里，幻灯片上没有一句话把它写成
规定；Verilog 本身也不要求，这个仓库从第 1 课起跟着用。

> A convention the whole tutorial keeps in its examples: `i_` for input, `o_` for output, `w_` for an
> internal wire. Following it means you never have to scroll back to a declaration to know a signal's
> direction while debugging 300 lines of someone else's code. It is not a Verilog rule and it is not
> printed on any slide; it is the author's habit, and this repo follows it from lesson 1 on.

> [!question]- 提问 · 什么是 internal wire
> **原话**
> 什么是internal wire
>
> **整理**
> What is an internal wire?
>
> **回答**
> 既不是输入也不是输出的线，只在这个模块内部存在。三种名字对比：
>
> | 名字 | 方向 | 谁驱动它 | 例子 |
> |---|---|---|---|
> | 输入 | 外面进芯片 | 引脚 | `input wire i_sw;` |
> | 输出 | 芯片出外面 | 模块内部 | `output wire o_led;` |
> | 内部线 | 只在内部 | 模块内部的 `assign` 或子模块输出 | `wire [8:0] w_internal;` |
>
> 为什么需要它：一个设计里常常有「中间结果」，它既要被下一级用到，又不需要露到芯片外面。
> 内部线就是给它一个名字。这一课的设计只有一根线，所以没有内部线；
> 第 2 课的 `w_internal`（`assign w_internal = 9'h87;`）是第一次用到它，那里的讲义已经展开讲了。
>
> 内部线必须自己声明：`wire w_x;` 或者声明时就定好位宽 `wire [7:0] w_x;`。

> [!quote]- 已处理 · 这一段没有中英对照（2026-11-01）
> **原话**
> 这里为什么不是中英对照了
>
> **处理**：那一段原来是只有英文的译者注（`i_` / `o_` / `w_` 命名习惯），没有配中文，是漏写。
> 已补成正常的中英对照两段，并写明它不是原文幻灯片上的内容。

原文在 `module` 之前还有一行 `` `default_nettype none ``。它的作用是把「用了没声明的名字」从
「工具悄悄补一根线」改成硬错误。这一课就用它，两个 `.v` 文件的第一行都写。

> The original puts `` `default_nettype none `` above the module. It turns "used a name that was never
> declared" from "the tool silently invents a wire" into a hard error. This lesson uses it: first line
> of both `.v` files.

> [!question]- 提问 · `default_nettype none` 是什么意思
> **原话**
> 什么意思
>
> **整理**
> What does `` `default_nettype none `` mean, and what happens without it?
>
> **回答**
> Verilog 有一条老规矩：**用了没声明过的名字，工具自动给你补一根 1 位的 `wire`**。这条规矩叫
> implicit net。它让写错名字的代码也能编译通过，只是电路是错的。
>
> 实测（2026-11-01），`assign o_led = i_sww;`（`i_sw` 多打一个 `w`）：
>
> | 情况 | `iverilog` | `yosys`（`build.ps1` 用的） |
> |---|---|---|
> | 不加这条指令 | 报错 `Unable to bind wire/reg/memory 'i_sww'`，退出码 2 | 只给一行 `Warning: Identifier 'i_sww' is implicitly declared`，然后**综合通过**，位流照出 |
> | 加上这条指令 | 同一句报错 | 报错 ``ERROR: Identifier 'i_sww' is implicitly declared and `default_nettype is set to none``，退出码 1 |
>
> 所以它主要拦的是综合那一步。仿真里 iverilog 本来就拦得住，但 `build.ps1` 走的是 yosys，
> 而 yosys 只警告不报错，警告混在几十行 log 里很容易漏掉。
>
> 拼错的名字出现在 `assign` 的**左边**更糟（`assign o_ledd = i_sw;`）：不加指令时 iverilog 退出码
> **0**，yosys 也只有一行 warning，板子上 `led[0]` 永远不亮；加了指令，iverilog 报
> `Net o_ledd is not defined in this context`，yosys 报同一个 `ERROR`，两边都停。
>
> **这条指令只对写了它的那个文件生效**，不是全局开关。实测：`top.v` 写了、`thruwire.v` 没写，
> `thruwire.v` 里的 `assign o_led = i_sww;` 照样综合通过，`led[0]` 没有驱动，只是多两行 warning。
> 所以每个 `.v` 都写。
>
> 讲义原来写「这一课先不加，等第 3 课再加」，两个地方都不对：第 3、4 课的参考代码里从来没有它
> （今天查过，`03_registers`、`04_dividers` 都没有），而且「先让它帮你兜住拼写错误」这句话说反了，
> implicit net 的作用是**掩盖**拼写错误，不是兜住。已经改成这一课就加。

## 2. 板子那边：约束文件 / The board side: constraints

FPGA 不知道你的 `i_sw` 在哪个引脚上。原文第 5 到 8 页就在讲这件事：设计写完只是「纸上的电路」，
还要告诉工具「这个端口接第几号引脚」，这个信息放在**约束文件**里（原文用 iCE40 的 `.pcf` 格式）。

> The FPGA does not know which pin your port should be on. Slides 5-8 cover exactly this: the design is a paper circuit until a constraint file says "this port lives on pin N". The original uses the
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

> [!question]- 提问 · 我需要会写这个 cst 吗
> **原话**
> 我需要会写这个cst吗
>
> **整理**
> Do I need to be able to write this `.cst` file myself?
>
> **回答**
> 这一课不用，你写 `top.v` 就够了。`constraints/tangnano9k.cst` 已经写好，`build.ps1` 默认就用它。
>
> 但要知道它为什么长这样，因为它决定了你的端口**必须**叫 `btn` 和 `led`。原文第 5 到 8 页花四页讲
> 这件事，因为写错引脚是新手最常见的「代码没错、板子不动」。
>
> 什么时候你要自己写：
>
> - 换一块板子（引脚号全变）
> - 用到一个这个文件里没有的引脚（比如板子上的 SD 卡、PSRAM）
>
> 格式就两行一组：`IO_LOC "名字" 引脚号;` 定位，`IO_PORT "名字" IO_TYPE=... PULL_MODE=...;`
> 声明电平标准和上拉。引脚号从板子的原理图或官方例程里查，**不能猜**。
> 这个仓库的 `.cst` 开头记了三个查证来源，就是当时这么做的。
>
> 一个练习想用自己那份约束，在练习目录下放 `board.cst` 即可。`build.ps1` 的优先级是
> `-Cst` 参数 > 练习目录的 `board.cst` > 共享的 `constraints/tangnano9k.cst`（见脚本第 25 到 31 行）。
> 这一课不需要。

## 3. 你的任务 / Your task

三步，每一步都要看到结果：

> Three steps, each with a result you can see:

**第 1 步：`rtl/thruwire.v` 已经给你了。** 模块名 `thruwire`，端口 `i_sw` 和 `o_led`，都是 1 位，
内容是 `assign o_led = i_sw;`。原文第 3 页也是直接给全文的，所以这一份不让你从零写。
这一步你只做一件事：**在文件第一行加 `` `default_nettype none ``**，空一行，再让 `module` 开头。

> Step 1: `rtl/thruwire.v` is given, the same way slide 3 gives it. Your only edit is the first line:
> `` `default_nettype none ``, a blank line, then `module`.

**第 2 步：写 `rtl/top.v`，把它接到板子上。** 这是这一课真正的作业。`top` 模块的端口必须是
`input wire [1:0] btn` 和 `output wire [5:0] led`，因为约束文件里就是这两个名字（见第 2 节那两行）。
第一行同样写 `` `default_nettype none ``，空一行再写 `module`。两个文件都要写，这条指令只对写了它的
那个文件生效。

> Step 2 is the real homework: a `top` module with ports `input wire [1:0] btn` and
> `output wire [5:0] led`, which is what the board file expects. Same first line:
> `` `default_nettype none ``. Both files need it; the directive is per file.

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

1. `build.ps1` 最后打出绿色的 `Done: ...\build\top.fs`，不是 `yosys failed` / `nextpnr failed`
2. 板子上按 `btn[0]`，`led[0]` 跟着变
3. 你能回答第 2 步里那两个问题，并且回答得出**为什么**，不是「试出来的」

> Three things: the build finishes with `Done:` and a `top.fs`, the LED follows the button, and you
> can answer the two questions from step 2 with a reason.

> [!quote]- 已处理 · 通过条件里两处字不对（2026-11-01）
> **处理**：原来写「有 `success` 输出」，`build.ps1` 实际打的是 `Done: <路径>`；原来写「第 3 步里那两个
> 问题」，那两个问题在第 2 步。都改成实际的样子。

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
