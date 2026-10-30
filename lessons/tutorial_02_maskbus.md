# ZipCPU 教程 · 第 2 课 · 总线、位选择和仿真

> Source: [ZipCPU beginner tutorial](https://zipcpu.com/tutorial/), still lesson 1 (`lsn-01-wires.pdf`),
> slides 18-44: "Simulation", "Bus Signals", "Bit Select", "Internal Signals", "Schematic",
> "Circular Logic", "Dual Assignment", "Sim Result". The board half of the same source lesson is
> Tutorial 01.
>
> 来源：ZipCPU 教程第 1 课的后半，第 18 到 44 张幻灯片。同一课的板子那一半是 Tutorial 01。

## 0. 这一课要拿到什么

原文第 19 到 21 页讲的第一件事是为什么要仿真：在板子上你只能看到一部分信号，在仿真里能看到全部；
硬件上复现一次问题要几分钟，仿真里几秒钟。原文有一句直接引自幻灯片：

> The source's reason for simulating, in its own words: hardware lets you see only some signals and
> debugging it is very hard; the simulator lets you see everything and debugging is easy. "A
> successful complex project ... requires simulation!"

这一课把上一课那根一位的线换成**多位线**（bus），学会取位、拼位、用内部线，然后写这个仓库里第一份
正式的 Verilog 测试台。

> One wire becomes many bits, plus bit selects, concatenation, internal wires, and the first real
> Verilog testbench in this repo.

## 1. 总线：一条线可以是一个向量

原文第 31 页：

> From slide 31:

```verilog
input  wire [8:0] i_sw;
output wire [8:0] o_led;
```

`[8:0]` 是**位范围**，从高位写到低位，所以这是 9 位：第 8 位到第 0 位。`i_sw` 现在是九根输入线，
`o_led` 九根输出线，名字还是一个。

> `[8:0]` is a bit range, written high index first, so this declares nine bits: bits 8 down to 0.

一个上机就踩的细节：`[8:1]` 也是 8 位，`[7:0]` 也是 8 位，两者宽度一样但编号不同。
自己写的时候统一从 0 开始，跟原文一样，**除非有理由不这么写**（比如字节对齐、和别人的接口对接）。

> `[8:1]` and `[7:0]` are both eight bits wide. Keep index 0 as the LSB unless there is a reason
> not to, which is what the source does.

## 2. 取位和拼位

原文第 32 页给了三种动作：

> From slide 32, three things you can do with a bus:

| 写法 | 意思 |
|---|---|
| `o_led[7] = i_sw[0]` | 取一位：把 `i_sw` 的第 0 位接到 `o_led` 的第 7 位 |
| `o_led[6:5] = i_sw[5:4]` | 取一段：两边的宽度必须相等，而且是**按顺序**对应，没有翻转 |
| `{i_sw[2:0], i_sw[7:6]}` | 拼位：花括号把几段拼成一个新向量，**左边是高、右边是低** |

> 拼位这条必须记牢：`{a, b}` 里 `a` 在高位。这是后面写移位、写字节序、写 UART 串行数据的
> 基础。写反了不会报错，只会算错。

> Concatenation puts the left operand in the high bits. Reversing it is not an error, it is a silent
> wrong answer, and UART framing in lesson 06 is where that shows up.

## 3. 内部线、字面量和符号扩展

原文第 33 到 35 页。内部线既不是输入也不是输出，只是设计内部的一根线：

> Slides 33-35. An internal wire is neither input nor output; it is a wire inside the design:

```verilog
wire [8:0] w_internal;

assign w_internal = 9'h87;
assign o_led = i_sw ^ w_internal;
```

`9'h87` 是一个**字面量**，原文第 34 页给出它的四段结构：

> `9'h87` is a literal. The source breaks it into four parts (slide 34):

| 段 | 在这里 | 意思 |
|---|---|---|
| 宽度 | `9` | 这个常量占几位 |
| 撇号 | `'` | 分隔符，不是英文的引号 |
| 类型 | `h` | 十六进制，还有 `d` 十进制、`o` 八进制、`b` 二进制 |
| 数值 | `87` | `87` 的十六进制就是 0x87 = 一百三十五 |

> 可选地在类型前加 `s` 表示有符号（原文写 `sd`），负数把负号写在**宽度前面**：`-7'sd124`。

> An optional `s` before the type makes it signed, and a negative number puts the minus sign before
> the width: `-7'sd124`. Underscores may be used inside the digits for readability
> (`32'hdead_beef`).

**符号扩展的规则**（原文第 35 页，这条对你以后写 CPU 立即数很有用）：

> Sign extension, slide 35, which matters later for CPU immediates:

- 字面量比上下文窄，又没有 `s`：**零扩展**，高位补 0
- 字面量比上下文窄，有 `s`：**符号扩展**，高位补符号位
- 字面量比上下文宽：**截断**，只留低位，很多工具会给警告

> Narrow and unsigned: zero extended. Narrow and signed: sign extended. Too wide: truncated, often
> with a warning.

## 4. 两条不能犯的错

原文第 38 到 39 页，两个错误各占一张幻灯片，因为它们在硬件里是**致命**的：

> Slides 38-39, two errors that each got a slide because they are fatal in hardware:

**环状逻辑。** `assign o_led = i_sw + o_led;` 在软件里看起来像「累加」，在硬件里等于自己驱动自己，
原文的说法是「相当于短路」，大多数工具直接拒绝构建。

> Circular logic: `assign o_led = i_sw + o_led;` makes the output drive itself. Most tools, verilator
> included, refuse to build it.

**重复赋值。** 同一个信号被 `assign` 两次，原文两个字：**一个值只能被设置一次**。因为那不是
「后一次覆盖前一次」，那是两根线同时驱动同一根线。

> Dual assignment: `o_led` assigned twice is not "the second one wins", it is two drivers on one
> wire. A value can be set once.

## 5. 你的任务

`examples/tutorial/02_maskbus/`。原文第 40 页的设计是一个异或掩码：

> The source's design on slide 40 is an XOR mask, and it is given to you complete, as the original
> gives it: `w_internal = 9'h87`, `o_led = i_sw ^ w_internal`.

我给你的部分：`rtl/maskbus.v`（就是原文那个设计，一字未改）和 `sim/tb_maskbus.v`（我的测试台，
十行期望值全是手算的）。**你要写的是自己的测试台 `sim/tb_mine.v`**：

> I give you `rtl/maskbus.v` and my `sim/tb_maskbus.v`. **You write `sim/tb_mine.v`**, which must:

1. 覆盖 `README.md` 里那张表的三行（`0x150`、`0x087`、`0x0F0`）
2. 再自己挑**至少两个**边界值：全 0、全 1、只有一位是 1、或者正好等于掩码本身
3. 每个用例打印一行，格式自定，但通过时打印 `=== tb PASS ===`，失败时打印失败的行和期望值
4. 期望值必须**手算**。不许在你的测试台里写 `expected = i_sw ^ 9'h87`，那是拿被测代码自己的运算符
   算答案，错了会一起错

> Expected values must be computed by hand, never `expected = i_sw ^ 9'h87` inside the testbench.
> That is the same-origin trap: one misunderstanding passes twice.

写完，先跑我的测试台确认设计对，再跑你自己的：

> Run mine first, then yours:

```powershell
cd C:\Local_Data\Dev\fpga
```

`cd` 切到项目目录。

```powershell
. .\env.ps1
```

`env.ps1` 加载工具链。第一个点是 dot-source 运算符，第二个点属于 `.\`。

```powershell
.\scripts\sim.ps1 -Project examples/tutorial/02_maskbus
```

`sim.ps1` 是仿真脚本，`-Project` 指定练习目录，它默认编译 `sim/` 下所有测试台。

## 6. 通过条件

1. `tb_maskbus` 打印 `=== tb PASS === all 10 rows match`
2. `tb_mine` 打印 `=== tb PASS ===`，而且覆盖了你挑的边界值
3. 你的测试台里**没有任何一处**用 `^` 去算期望值
4. 你能解释：为什么 `0x087` 这个输入会得到全 0 的输出

> Four things, and the fourth is the one I will ask about.

## 7. 问题

写在看不懂的那句话下面，回答就长在那里。

### Q1

> `{i_sw[2:0], i_sw[7:6]}` 一共几位？如果 `i_sw = 9'b1_1000_0011`，结果是多少？写成二进制。

### Q2

> 你的 `tb_mine.v` 里，为什么要写 `#1` 再检查 `o_led`？去掉会怎样？用一句话解释，别试出来再说。

### Q3

> 原文说 `assign o_led = i_sw + o_led;` 在硬件里「相当于短路」。用你自己的话解释：如果综合工具
> 允许这种写法并生成电路，这个电路的行为会不会确定？
