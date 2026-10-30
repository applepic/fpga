# ZipCPU 教程 · 第 4 课 · 分频、PPS 与时序检查

> Source: [ZipCPU beginner tutorial](https://zipcpu.com/tutorial/), lesson 2, `lsn-02-regs.pdf`,
> slides 28-37: Strobe, PPS-I, PPS-II, Stretch, Too Slow, Dimmer, Exercises. The first half of the
> same source lesson is Tutorial 03.
>
> 来源：ZipCPU 教程第 2 课的 28 到 37 页。同一课的前半是 Tutorial 03。

## 0. 这一课要拿到什么

原文第 2 页的目标里，前面三条在 Tutorial 03 已经拿到。这一课补第四条和第五条：**知道系统时钟从哪来**，
以及**时序检查为什么重要**。

> The last two of the source's objectives are here: where the system clock comes from, and why timing
> checks matter.

## 1. strobe：把「很快」变成「看得见」

原文第 28 页。Tutorial 03 里你写的 `strobe` 复述一遍是因为它引出后面全部内容：

> Slide 28, repeated from Tutorial 03 because everything below builds on it:

```verilog
assign o_led = &counter[26:24];
```

`&` 放在信号前面是**归约与**：把这三个二进制位全取出来做与。三个位全是 1 的时候结果是 1，
所以每 2^24 个时钟沿里，有 2^24 / 8 次为 1。27 MHz 下 2^24 / 27e6 ≈ 0.62 秒亮一次，
每次亮 2^21 / 27e6 ≈ 78 毫秒。

> `&` in front of a bus is a reduction AND. It is 1 only when all three selected bits are 1, so it
> fires once every 2^24 edges. At 27 MHz that is once every 0.62 s, high for about 78 ms.

这就是「把快信号减慢到看得见」。它的问题是**周期不是整数秒**，想做一个秒针就不能靠它。

> That is slowing a signal to eye speed, but the period is not a whole number of seconds.

## 2. 整数分频：PPS-I

原文第 29 页。想要一秒亮一下，最简单的做法是数够一半的时钟周期数就翻转：

> Slide 29. Count half the clock rate, then flip:

```verilog
always @(posedge i_clk)
if (counter >= CLOCK_RATE_HZ/2 - 1)
begin
	counter <= 0;
	o_led <= !o_led;
end else
	counter <= counter + 1;
```

原文叫它**整数分频**（integer clock divider），因为除法是精确的：27 MHz 下每 13 500 000 个沿翻转一次，
一秒正好一次，不多不少。

> An integer divider: exact. 13 500 000 edges per flip at 27 MHz is exactly one second.

## 3. 小数分频：PPS-II

原文第 30 到 31 页。第二个做法在 32 位加法器上做同一件事：

> Slides 30-31. The second design does the same job with a 32-bit adder:

```verilog
parameter CLOCK_RATE_HZ = 100_000_000;
parameter [31:0] INCREMENT = (1<<30)/(CLOCK_RATE_HZ / 4);
reg [31:0] counter;

always @(posedge i_clk)
	counter <= counter + INCREMENT;

assign o_led = counter[31];
```

原文的解释是：计数器加满 2^32 需要 CLOCK_RATE_HZ 个时钟沿，`counter[31]` 在加满的过程中翻转两次，
所以 LED 的周期正好是一秒。原文说这是**小数分频**，因为 `2^32 / CLOCK_RATE_HZ` 一般除不尽。

> The counter takes CLOCK_RATE_HZ edges to wrap 2^32, and its top bit flips twice per wrap, so the LED
> period is one second. The source calls this fractional because 2^32 / CLOCK_RATE_HZ is usually not an
> integer.

那个 `/ 4` 不是数学，是为了让 `1<<30` 留在 32 位以内（原文的说法：分子分母同时除以四，
只是为了不越界）。

> The `/ 4` on both sides isn't maths. It keeps `1<<30` inside 32 bits, as the source says.

**本仓库用的是另一种等价写法**，原因写在文件里：

> This repo uses an equivalent form, and the reason is in the file:

```verilog
localparam [32:0] INCREMENT = 33'h1_0000_0000 - CLOCK_RATE_HZ/2;
always @(posedge i_clk)
	counter <= counter + INCREMENT[31:0];
assign o_led = counter[31];
```

两个改动，都是实测出来的：

> Two changes, both measured:

1. `33'h1_0000_0000` 是 2^32，写成 32 位常量的话 iverilog 会打印 `Extra digits given for sized hex
   constant` 和 `Numeric constant truncated to 32 bits`。**结果仍然对**，因为截断成 0 之后是
   `0 - D`，而 `0 - D` 在 32 位补码里正是 `2^32 - D`。但让编译器报警一次的写法不值得留
2. 原文用 `(1<<30)/(CLOCK_RATE_HZ/4)`，是本仓库的 `2^32 - CLOCK_RATE_HZ/2`。两者只在
   `CLOCK_RATE_HZ/4` 能整除时相同。27 MHz 除 4 是 6 750 000，能整除，所以两个都行；但
   `2^32 - D` 这个写法对任何 `D` 都对，而且直接接上 Tutorial 02 里那条 `a - b = a + ~b + 1`

> Change 1 avoids two compiler warnings while producing the same value. Change 2 replaces a formula
> that only agrees when `CLOCK_RATE_HZ` is divisible by 4 with one that always agrees, and it is the
> same subtraction identity from Tutorial 02.

## 4. 系统时钟从哪来

原文第 34 到 35 页。你的板子上有一个晶振，Tang Nano 9K 是 **27 MHz**，这个频率从引脚进来，一直走到
你设计的 `i_clk`。没有别的东西会给你时钟。

原文强调两条：做时序检查时用**系统的**时钟频率；**每次上板之前都要检查时序**。

> Slides 34-35. The board's oscillator is the system clock: 27 MHz on the Tang Nano 9K, straight into
> `i_clk`. Check timing at that frequency, and check it before every board load.

## 5. Too Slow：故意让它过不了

原文第 34 页给了一个 1024 位计数器，并说它「保证过不了时序检查」，理由是进位链太长：

> Slide 34 gives a 1024-bit counter and says it is guaranteed to fail timing because the carry chain
> is too long.

**这块板子上的实测结果和原文不一样，这一点必须说清楚：**

> On this board the measured result differs from the source's claim, and that has to be said plainly:

| 位宽 | 结果 |
|---|---|
| 64 | Fmax 156 MHz，pass |
| 128 | Fmax 99 MHz，pass |
| 256 | Fmax 57.6 MHz，pass（目标是 27 MHz） |
| 288 | 布局失败（nextpnr 找不到合法位置），没走到时序检查 |
| 320、512、1024 | 同上，布局就失败了 |

> 288 bits and up do not fail timing; they fail placement first.

要在本仓库看到**时序检查本身失败**，得把目标频率调高。实测：256 位计数器加 `-Freq 100`，
nextpnr 报 `Max frequency for clock 'u.i_clk': 57.62 MHz (FAIL at 100.00 MHz)`，构建失败。
这就是一个时序失败的样本，只是触发方式来自目标频率，不是来自位宽。

> To see a real timing failure here, raise the target: `build.ps1 -Freq 100` on the 256-bit counter
> gives `57.62 MHz (FAIL at 100.00 MHz)` and stops the build.

## 6. Dimmer 与练习

原文第 36 页的 dimmer 就是 Tutorial 03 讲的 `counter[31:8]` 那组高位做比较：

> Slide 36's dimmer compares two parts of one counter:

```verilog
reg [27:0] counter;
always @(posedge i_clk)
	counter <= counter + 1;
assign o_led = (counter[7:0] < counter[27:20]);
```

低位 8 位跑得快，高位 8 位跑得慢，一个是 3.16 MHz 的锯齿，一个是 12 kHz 的锯齿。比较结果就是占空比
跟着慢锯齿走：慢锯齿为 0 的时候 LED 一直灭，为 255 的时候一直亮，中间就是亮度。

> The low byte is a 3.16 MHz sawtooth, the high byte a 12 kHz one, so the duty cycle follows the slow
> one: off at 0, fully on at 255.

原文第 37 页的四道练习，本仓库的对应任务：

> The source's four exercises, mapped to this repo:

| 原文练习 | 本仓库 |
|---|---|
| 在硬件上实现 blinky | Tutorial 03 的参考设计，上板 |
| 实现两个 PPS 之一，用秒表验证 1 Hz，然后把亮的时间变短 | 本课任务 1 |
| 验证 1024 位计数器过不了时序 | 本课任务 2，结论和原文不同，见上面那张表 |
| 实现 dimmer | 本课任务 3 |

## 7. 你的任务

`examples/tutorial/04_dividers/`。三件事，全部要跑起来：

> `examples/tutorial/04_dividers/`, three parts:

**任务 1：`rtl/pps.v`。** 我自己写的那份在 `examples/tutorial/03_pps/rtl/pps.v`，你可以读，
但**不许照抄**：你要自己推导一遍，然后在测试台里证明计数器每 `D = CLOCK_RATE_HZ/2` 个沿回到 0 附近
（不是正好回到 0，`2^32 - D` 的加法不是除法，差多少自己算）。

> Part 1: write `rtl/pps.v`. Mine is in `03_pps/rtl/pps.v` and you may read it, but derive yours
> yourself. Your testbench has to show how far the counter is from zero after `D` edges, which is not
> exactly zero, because repeated addition is not division.

**任务 2：`rtl/tooslow.v` 和时序结论。** 写那个 `parameter NBITS = 1024` 的计数器，构建两次：
一次默认（27 MHz），一次 `-Freq 100`。把两次的输出都贴给我，回答一句话：**这块板子上它为什么不按
原文说的那样失败？**

> Part 2: write `tooslow.v`, build it twice, default target and `-Freq 100`, and answer in one sentence
> why this board does not fail the way the source predicts.

**任务 3：`rtl/dimmer.v`。** 原文第 36 页那个设计，上板看亮度。仿真里只要证明占空比的**两个端点**：
`counter[27:20] == 0` 时 `o_led` 恒为 0，`== 255` 时恒为 1。

> Part 3: the dimmer, on the board, and in simulation only the two endpoints of the duty cycle.

```powershell
cd C:\Local_Data\Dev\fpga
```

`cd` 切到项目根目录。

```powershell
. .\env.ps1
```

`env.ps1` 把工具链加载进当前终端。第一个点是 dot-source 运算符，第二个点属于 `.\`。

```powershell
.\scripts\sim.ps1 -Project examples/tutorial/04_dividers
```

`sim.ps1` 是仿真脚本，`-Project` 指定练习目录。

```powershell
.\scripts\build.ps1 -Project examples/tutorial/04_dividers -Freq 100
```

`build.ps1` 是构建脚本，`-Freq` 是目标频率（兆赫兹），超过综合后的 Fmax 就会失败。不加 `-Freq`
就是 27 MHz。

## 8. 通过条件

1. `pps` 在测试台里通过，且你能说出计数器在 `D` 个沿之后距离 0 差多少
2. `tooslow` 的两次构建输出都在，且你的解释和我上面那张表一致
3. `dimmer` 上板，亮度看得出来，仿真里两个端点通过

## 9. 问题

### Q1

> `2^32 - D` 这个加法，为什么 `D` 个沿之后计数器正好回到 0？用补码加法解释，不要用「因为等于 2^32」。

### Q2

> 256 位计数器在 27 MHz 下 Fmax 是 57.6 MHz，通过；1024 位在布局阶段就失败。**这两种失败
> 是完全不同的事**：说清楚它们分别在哪个阶段、分别是谁报错。

### Q3

> dimmer 的占空比是 `counter[27:20] / 256`，但 `counter[7:0]` 一个完整周期是 256 个时钟，
> 而 `counter[27:20]` 每 2^20 个时钟才加一。换句话说低位在一个慢周期的前 256 个时钟里就跑完了。
> 那么「亮度」这个词在这个设计里到底指什么？

### Q4

> 原文的 PPS-II 用 `(1<<30)/(CLOCK_RATE_HZ/4)`，本仓库用 `2^32 - CLOCK_RATE_HZ/2`。找出一个
> `CLOCK_RATE_HZ`，让这两个式子在 32 位下给出**不同**的结果，并说明差多少。
