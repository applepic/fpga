---
tags:
  - hardware
---

# Lesson 02 · Binary arithmetic and signed numbers / 二进制运算与有符号数

> Bilingual, 2026-10-28 format: English is the primary text and complete on its own, Chinese
> follows each paragraph as a blockquote. Code, signal names, commands and error messages are
> never translated.
>
> 中英对照。英文是正文，单独读也完整；中文按段落跟在后面，放在引用块里。
> 代码、信号名、命令、报错原文不翻译。
>
> Previous: `lessons/legacy_01_verilog_basics.md` (the first lesson under the old numbering;
> passed 2026-10-29). Next: `lessons/03_always_and_clocks.md`.
> Exercise: `examples/02_adder`
>
> **Cut in half on 2026-10-30.** Your comment at the bottom said the lesson was too long and had
> things you had not been taught. Both were true. `wire` and `reg` had never been taught: the old
> lesson 1 showed them in code and its testbench read as gibberish to you, which I recorded on
> 2026-10-29. Subtraction's "plus one" and the carry out were my framing, not your gaps. They are
> now section 0 and section 4 and they are the first thing you hit. What was cut: the second pass
> over the 4-bit table, the login-name table, the 8-bit table, the overflow section (moved into
> lesson 03, where there is an `always @*` example to hang it on) and the lesson's copy of
> `signed` (now only in `examples/02_adder/sim/README.md`, where you need it). Questions are
> answered in place below, under the line they were written on.
>
> **Table and code-block rendering was my layout error, not your reading.** A Chinese mirror table
> or a `> `-quoted Chinese copy directly under an English table or code block makes Obsidian read
> the two as one block, and the whole thing collapses into vertical bars. From this version on:
> one table per point, Chinese as a blockquote under it, a blank line between every code block,
> and no Chinese inside code blocks.

---

## 0. `wire` and `reg`: the two things a name can be / 名字只有两种

A module has inputs, outputs and internal names. **Every one of them is declared with a type**, and
there are only two you need:

> 模块里有输入、输出和内部名字。**每个名字都要声明类型**，现在只需要两种：

| Type | What it is | What it can hold | Where it can be assigned |
|---|---|---|---|
| `wire` | a physical connection | nothing; it is whatever drives it, right now | in `assign` |
| `reg` | a variable inside a procedural block | the last value written to it | inside `always` or `initial` |

> | 类型 | 是什么 | 能存什么 | 能在哪里被赋值 |
> |---|---|---|---|
> | `wire` | 一根连接线 | 什么也不存，永远等于此刻驱动它的东西 | `assign` 里 |
> | `reg` | 过程块里的变量 | 最后一次写进去的值 | `always` 或 `initial` 里 |

Two facts matter more than the table:

> 比表格更要紧的两件事：

1. **`reg` does not mean flip-flop.** A `reg` inside `always @(posedge clk)` becomes a flip-flop. A
   `reg` inside `always @*` becomes a combinational block with no memory at all. The keyword only
   means "can be assigned inside a block"; which circuit comes out is decided by the block around it.
2. **An `output` is a `wire` unless you write `reg`.** `output reg [1:0] y;` is how you get a port
   that is assigned inside an `always`. With `output wire` and an `always` assignment, iverilog
   refuses to compile.

> 1. **`reg` 不等于触发器。** 写在 `always @(posedge clk)` 里的 `reg` 才是触发器；
>    写在 `always @*` 里的 `reg` 是组合逻辑，一点记忆都没有。
>    这个词只表示「可以在块里被赋值」，出什么电路由外面那个块决定。
> 2. **`output` 默认是 `wire`。** `output reg [1:0] y;` 才是「在 `always` 里赋值的端口」。
>    写 `output wire` 却在 `always` 里赋值，iverilog 直接编译不过。

`wire` and `assign` appeared in the legacy lesson, and `reg` appeared in every testbench I wrote.
From lesson 03 on, `reg` appears in your own designs, and fact 1 stops being trivia.

> `wire` 和 `assign` 旧第 1 课见过，`reg` 在我写的每个测试台里出现过。
> 从第 03 课起 `reg` 会出现在你自己写的设计里，那时第一条就不再是冷知识。

## 1. The 4-bit table once / 4 位的表一次性过

The method you chose stays: read the bits as unsigned, and if the top bit is 1, subtract 2ⁿ.

> 你选的算法不变：先当无符号读，最高位是 1 就减 2ⁿ。

| Bits | Unsigned | Signed | Subtraction |
|---|---|---|---|
| `0000` | 0 | 0 | none |
| `0001` | 1 | 1 | none |
| `0111` | 7 | 7 | none |
| `1000` | 8 | -8 | 8 - 16 |
| `1011` | 11 | -5 | 11 - 16 |
| `1100` | 12 | -4 | 12 - 16 |
| `1111` | 15 | -1 | 15 - 16 |

> 中文说明：最高位是 0 的行，两种读法一样，不用减；最高位是 1 的行，无符号读数减 16 就是有符号读数。

## 2. Eight bits: the same 2ⁿ / 8 位：还是那个 2ⁿ

Eight bits is the same rule with a bigger n:

> 8 位就是同一个规则换个大一点的 n：

```text
1011_0100      unsigned 180, top bit 1, so 180 - 256 = -76
0110_1100      unsigned 108, top bit 0, so it stays   +108
```

Two shortcuts make the table fast, both from the `-1` row above:

> 两个捷径让推表变快，都来自上面 `-1` 那一行：

- `1111_1111` is -1: every `1` bit adds its own sign, so all ones is -1. `1111_1110` is -2,
  `1111_1100` is -4.
- `1000_0000` is -128 and `0111_1111` is 127, so 8 bits holds -128 to 127, 256 values in all.

> - `1111_1111` 是 -1，每个为 1 的位按符号加起来，全 1 就是 -1。`1111_1110` 是 -2，`1111_1100` 是 -4。
> - `1000_0000` 是 -128，`0111_1111` 是 127，所以 8 位是 -128 到 127，共 256 个值。

## 3. Adding in binary: the carry / 二进制加法：进位

Column by column, right to left, carrying 1 when the column totals 2:

> 一列一列从右往左，一列加起来到 2 就进 1：

```text
    0 1 1 0      (6)
  + 0 1 0 1      (5)
  ----------
    1 0 1 1      (11)
```

And when the top column carries out, the result needs one more bit than the inputs:

> 最高列也进位出去时，结果比两个加数都多一位：

```text
    1 0 1 1      (11)
  + 0 1 1 0      (6)
  ----------
  1 0 0 0 1      (17)   the fifth bit is the carry out
```

A one-bit adder therefore has three inputs and two outputs: `a`, `b`, `c_in` in, `sum` and `c_out`
out. `c_in` is not a bit of `a` or `b`, it is **whatever the column on the right handed over**. The
rightmost column's `c_in` is an input of the whole adder, and that is the pin the `SUB` trick in
section 4 ties to 1.

> 一个 1 位加法器三个输入 `a`、`b`、`c_in`，两个输出 `sum`、`c_out`。
> `c_in` 不是 `a` 或 `b` 的某一位，而是**右边一列送过来的那个数**；
> 最右一列的 `c_in` 是整个加法器的一个输入引脚，第 4 节的减法就把它接 1。

## 4. Subtraction is addition, explained / 减法为什么就是加法

**Inverting is "subtract from all ones".** Every column of `b + ~b` adds to 1, so n ones, which is
2ⁿ - 1:

> **取反就是「用全 1 去减」。** `b + ~b` 的每一列都加到 1，n 位全是 1，就是 2ⁿ - 1：

```text
b + ~b = 2^n - 1       4 bits: 0101 + 1010 = 1111 = 15 = 16 - 1
```

**Adding one fixes the missing one.** `~b + 1 = 2ⁿ - b`, a number that makes `b` wrap to 0 in n
bits:

> **加一补上差的那个 1。** `~b + 1 = 2ⁿ - b`，它加上 b 在 n 位里正好回到 0：

```text
b + (~b + 1) = 2^n      4 bits: 0101 + 1011 = 10000, the 5th bit is dropped -> 0000
```

So `-b = ~b + 1`, and `a - b = a + (-b) = a + ~b + 1`. The `+1` is not a convention: it is the 1
that `b + ~b = 2ⁿ - 1` was short of. In hardware it is free, because it is the adder's `c_in`.

> 所以 `-b = ~b + 1`，`a - b = a + ~b + 1`。那个 `+1` 不是约定，就是 `b + ~b = 2ⁿ - 1` 差的那 1。
> 硬件里它不花钱，就是加法器的 `c_in`。

Check with 4 bits, `3 - 5`:

> 用 4 位验一下，`3 - 5`：

```text
  3       0011
  5       0101
  ~5      1010          = (2^4 - 1) - 5 = 15 - 5
  ~5 + 1  1011          that is -5 in 4 bits
  0011 + 1011 = 1110    read as signed: 14 - 16 = -2   correct
```

So `SUB` is `ADD` with the b input inverted and `c_in` tied to 1. That is why the RV32I ALU gets
one adder and not two (lesson 13).

> 所以 `SUB` 就是「b 取反、`c_in` 接 1」的 `ADD`。这就是 RV32I 的 ALU 只要一个加法器的原因（第 13 课）。

**The carry out, and why it means two different things.** The carry out is the (n+1)-th bit, the only
evidence the hardware gives about going past the unsigned range. In `3 - 5` the carry out is 0, which
read as unsigned means "the sum 3 + 11 = 14 did not pass 15". As a subtraction it means "the result
came out below zero when read unsigned", i.e. 3 < 5. For `ADD` the carry out is "went past the top",
for `SUB` it is the complement of "a borrow happened". `SLT` leans on exactly that difference (lesson
13).

> **进位输出，以及为什么它有两个意思。** 进位输出就是第 n+1 位，是硬件给出的、关于「超出无符号范围」的唯一证据。
> `3 - 5` 里进位输出是 0：当无符号看，3 + 11 = 14 没超过 15，所以是 0；
> 当减法看，意思是「无符号读时结果掉到 0 以下」，也就是 3 < 5。
> `ADD` 里它表示「超过最大值」，`SUB` 里它是「发生了借位」的取反。`SLT` 用的正是这个区别（第 13 课）。

## 5. Sign extension / 符号扩展

In the legacy lesson you saw `1111` extended to `11111111` keeps -1 while zero extension turns it into
15. Here is the 8-bit to 16-bit version with the values the testbench uses:

> 旧第 1 课你看过 `1111` 扩成 `11111111` 保持 -1，零扩变成 15。这里是 8 位到 16 位，用测试台里的值：

| `x` | Zero-extended, unsigned | Sign-extended, unsigned | Sign-extended, signed |
|---|---|---|---|
| `0000_0000` | 0 | 0 | 0 |
| `0100_0000` (64) | 64 | 64 | 64 |
| `1000_0000` (-128) | 128 | 65408 | -128 |
| `1111_1111` (-1) | 255 | 65535 | -1 |

> 中文说明：第三列不是笔误。位是对的，读出来还是 65535，因为读的那一方不知道你指的是有符号数。
> **一个数落在哪一列，由读它的一方决定，不由写它的一方决定。**

## 6. Your task / 你的任务

Two parts in `examples/02_adder/`:

> `examples/02_adder/` 里两个部分：

| Part | File | Graded by |
|---|---|---|
| 1. one-bit full adder (carry in, carry out) | `rtl/full_adder.v` | `sim/tb_adder.v`, mine, 8 rows |
| 2. two's complement + sign extension | `rtl/sign_extend.v` **and your own `sim/tb_sign.v`** | the specification in `sim/README.md`, plus my hidden copy |

Part 2 is the first testbench you write. The `wire` / `reg` / `signed` reasoning it needs lives in
`sim/README.md`, not here, so the file you work from and the file that judges you are the same
statement.

> 第 2 部分是你写的第一份测试台。它要用的 `wire` / `reg` / `signed` 推理放在 `sim/README.md` 里，
> 不放这里：你照着写的文件和验你的文件是同一份说法。

Run:

> 运行：

```powershell
cd C:\Local_Data\Dev\fpga
```

`cd` switches the current folder to the project.

> `cd` 切到项目目录。

```powershell
. .\env.ps1
```

`env.ps1` loads the toolchain into this terminal. The first dot is the dot-source operator, the
second dot belongs to `.\`.

> `env.ps1` 把工具链加载进当前终端。第一个点是在当前会话执行（dot-source），第二个点是 `.\` 的一部分。

```powershell
.\scripts\sim.ps1 -Project examples/02_adder
```

`sim.ps1` is the script, `-Project` tells it which exercise folder to compile and run.

> `sim.ps1` 是脚本，`-Project` 告诉它编译运行哪个练习目录。

**Pass condition, part 1:** `=== tb PASS === all 8 rows match`.

> **第 1 部分通过条件**：`=== tb PASS === all 8 rows match`。

Then run three wrong versions and note which rows catch them. A test you have not seen fail is a
test you do not know the coverage of.

> 然后按 README 改三个错版本，看哪几行抓到。**没见它失败过的测试，你不知道它覆盖了什么。**

Time budget: 10 minutes for section 0 and section 4, 20 minutes for the adder and the three wrong
versions, 30 to 45 minutes for your own testbench.

> 时间：第 0 节和第 4 节 10 分钟，加法器和三个错版本 20 分钟，自己的测试台 30 到 45 分钟。

## 7. Questions / 问题

Write new questions anywhere in this file, under the paragraph that caused them. The whole file is
read every time. Original words stay, answers go in place.

> 新问题写在这份文件的任何位置，哪一段看不懂就写在下面。每次都读整篇，原话照抄，回答就地写在下面。

### Answers to the questions written on 2026-10-30

Your questions from that pass are below, in the order they appeared, each with the line it was
written under. They stay here because that order is the record of where the lesson lost you.

> 2026-10-30 那轮的提问在下面，按出现顺序，每条注明写在哪一行下面。
> 保留在这是因为它记录了讲义在哪几句上跟丢了你。

> [!question]- 提问 · 第 1 节的表渲染错误了，可以删掉
> **原话**
> 这个表格渲染错误了，可以删掉
>
> **整理**（写在 `0000` 到 `1111` 那张 4 位表下面）
> This table does not render. You may delete it.
>
> **回答**
>
> 表格内容没错，坏的是排版：英文表下面紧跟一行 `> | 位 | ... |` 的中文表，两张表之间只隔一个空行，
> Obsidian 把它们读成一张表，列数对不上，整块退化成竖线文本。**是我的排版错误。**
>
> 处理：这一课改成对每个点只放一张表，中文说明用引用块写在表下面，不再放第二张表。
> 你原来看到的表内容一字没改，`2ⁿ` 和减 16 的说明现在在表下面那句话里。

> [!question]- 提问 · 要学会速算吗，什么方法好
> **原话**
> 要学会速算吗，什么方法好
>
> **整理**（写在「两个捷径让推表变快」那两条下面）
> Do I need to learn fast hand conversion of two's complement, and which method is best?
>
> **回答**
>
> 要学会，但不是为了快，是为了**不再靠逐位加减去推**。理由在第 11 到 13 课：
> 写 `SLT` 和立即数符号扩展时要一直判断「这个位模式当有符号是多少」，判断错一次就是一条指令错，
> 而且不会有任何报错。
>
> 最省的方法是这一个，其余都是它的变体：
>
> **取反加一换符号。** 把 x 的每一位取反，再加 1，得到 -x，位数不变；反过来做一样，所以只需要记一次。
>
> ```text
> 4 位   +5  0101  -> 取反 1010 -> 加 1 -> 1011   (-5)
> 4 位   -5  1011  -> 取反 0100 -> 加 1 -> 0101   (+5)
> 8 位  -76  1011_0100 -> 取反 0100_1011 -> 加 1 -> 0100_1100 (+76)
> ```
>
> 两个省时间的推论，不算新方法：
>
> - 最高位是 0：不用算，两种读法同一个数。
> - 最高位是 1：无符号读数减 2ⁿ 就是有符号读数。
>
> 为什么必须是「加一」，第 4 节现在从头推了一遍。练到能不看表写出任意 8 位负数就够了，不用练心算速度。

> [!question]- 提问 · 为什么需要我登录名
> **原话**
> 什么玩意，为什么需要我登录名
>
> **整理**（写在 16 行的 8 位表格下面）
> What is this, and why does my login name matter?
>
> **回答**
>
> 那条设计是错的，我撤了。原本的想法是拿你自己的字符串当素材，让表里的数对你有意义、抄不动。
> 问题有两个：一个是把 16 行表塞进讲义，和「讲义要短」直接矛盾；
> 另一个更实在，**登录名是账号信息，不该出现在笔记里，也不该成为学习任务的一部分**。
>
> 现在那张 16 行的表整个删了。8 位补码的练习改成口头的：
> 随便给一个 8 位位模式，30 秒内说出它的有符号值和无符号值。
> 第 1 节和第 2 节的两张小表已经覆盖了它要教的东西。

> [!question]- 提问 · 这个渲染也有问题 / 那 carry in 是哪个
> **原话**
> 这个渲染也有问题
> 。
> 这个没问题
> 。
> 这个渲染有问题
> 那carryin是哪个
>
> **整理**（写在第 3 节的两个 `text` 代码块之间）
> 1. The first `text` block does not render, the second does.
> 2. So which bit is the carry in?
>
> **回答**
>
> **一、渲染。** 两个代码块内容都对，坏的是排版：英文代码块下面紧跟一行以 `> ` 开头的中文副本，
> 中间没有空行，Obsidian 把它接进代码块，代码块就没闭合，后面整段都变成灰色代码。
>
> 处理：**代码块之间留空行，代码块里不放中文**。中文副本改成表下面的引用块说明，这一课已经重排。
> 第 4 节那个也有同样的问题，一并改了。
>
> **二、carry in 是哪一位。** 它是**右边一列送进本列的那个数**，不是 a 或 b 里的某一位。
>
> ```
> 本列：a + b + c_in
>        结果的最低位 -> sum
>        结果的高一位 -> c_out，交给左边一列，成为左边那列的 c_in
> ```
>
> `0110 + 0101`（6 + 5）从右往左，四位分别是：
>
> | 列（从右数） | a | b | c_in | 本列值 | sum | c_out |
> |---|---|---|---|---|---|---|
> | 1 | 0 | 1 | 0（最右一列，外部输入） | 1 | 1 | 0 |
> | 2 | 1 | 0 | 0 | 1 | 1 | 0 |
> | 3 | 1 | 1 | 0 | 2 | 0 | 1 |
> | 4 | 0 | 0 | 1 | 1 | 1 | 0 |
>
> 结果 `1011` = 11。整个加法器的 `c_in` 就是**第 1 列的那个 c_in**，它露在外面是为了让减法能用：
> 第 4 节把 b 取反之后，把这个引脚接 1，那个「加一」就接上了。

> [!question]- 提问 · 为什么写两遍
> **原话**
> 为什么写两遍
>
> **整理**（写在 `a - b = a + (-b) = a + (~b + 1)` 下面）
> Why is this written twice?
>
> **回答**
>
> 同一个内容出现了两次：一次在正文代码块里，一次在它下面以 `> ` 开头的中文副本里。
> **这是排版问题，不是课文重复。** 中文副本如果必须保留，就不该用代码块，改成一句话说明。
>
> 这一段现在只有一份代码块，后面跟一句中文解释，没有再抄一遍公式。

> [!question]- 提问 · 搞不懂，为什么取反还要加一，2ⁿ-1-b 为什么是这样
> **原话**
> 搞不懂，为什么取反还要加一，然后`2ⁿ - 1 - b`为什么是这样
>
> **整理**（写在 `~b + 1` 那段定义下面）
> I do not follow why inverting must be followed by a plus one, or why the inverted value is
> `2ⁿ - 1 - b`.
>
> **回答**
>
> 两个问题的推导都在第 4 节开头，现在它是这一节的第一件事。一句话版：
>
> - **为什么是 `2ⁿ - 1 - b`**：`b` 和 `~b` 的每一列加起来都是 1，n 列就是 n 个 1，即 `2ⁿ - 1`。
>   所以 `~b = (2ⁿ - 1) - b`。
> - **为什么还要加一**：只取反时 `b + ~b = 2ⁿ - 1`，离 `2ⁿ` 差 1；补上这 1 才有 `b + (2ⁿ - b) = 2ⁿ`，
>   在 n 位里 `2ⁿ` 就是 0。两数相加为 0，才是相反数。
>
> 先拿 `0101` 验一遍再回来看公式：取反得 `1010`，5 + 10 = 15 = 16 - 1，差的就是那个 1。

> [!question]- 提问 · 渲染有问题，估计是前面有尖尖
> **原话**
> 渲染有问题，应该你打错了吧估计是前面有这个尖尖>
>
> **整理**（写在 `3 - 5` 的验算代码块下面）
> This does not render either; I guess it is the `>` at the front.
>
> **回答**
>
> 猜对了，就是 `>`。那一行是中文副本的引用标记，紧贴在代码块结束的 ``` 下面、中间没有空行，
> Obsidian 于是把引用行当成代码块内容，代码块没闭合。
>
> 这一课现在所有代码块的结束 ``` 后面都跟一个空行，代码块内部不放任何以 `>` 开头的行。

> [!question]- 提问 · 进位输出是 0 是什么意思
> **原话**
> 什么意思
>
> **整理**（写在第 4 节「The carry out of this addition is 0」那段下面）
> What does "the carry out is 0" mean, and why does the same carry mean different things for
> `ADD` and `SUB`?
>
> **回答**
>
> 进位输出就是**第 n+1 位**，也就是「这次加法有没有超出 n 位能装的范围」的那个证据。
>
> 在 `3 - 5` 里：`0011 + 1011 = 1110`，第 5 位是 0。当无符号看，3 + 11 = 14，没超过 15，
> 所以第 5 位当然是 0，这是对的。
>
> 当减法看时它的含义变了：减法实际算的是 `a + (~b + 1)`，那个「补 1」是从高位借来的 1。
> 如果 `a < b`，高位那个 1 就还不上，第 5 位不会出现，读作「发生了借位」；
> 如果 `a >= b`，会多出一个 1，读作「没有借位」。
>
> 一句话：**同一个进位位，`ADD` 读作「超过最大无符号值」，`SUB` 读作「没借位」，两者互为取反。**

> [!question]- 提问 · 这都没渲染成表格
> **原话**
> 这都没渲染成表格
>
> **整理**（写在签名扩展那张表下面）
> These do not render as tables.
>
> **回答**
>
> 和第 1 节同一个原因：两个表并排，或者表格后面紧贴 `> ` 行。这一课的表格已经全部改成单份，
> 中文说明放在表下面，`reg [7:0] u;` 那个例子也一样。

> [!question]- 提问 · wire 和 reg 也没和我讲
> **原话**
> 这又是啥，wire和reg也没和我讲
>
> **整理**（写在 `reg [7:0] u;` 那个例子下面）
> What are these? `wire` and `reg` were never taught either.
>
> **回答**
>
> 成立，是**我的漏教**，而且比这一课更早：旧第 1 课只在代码里出现过 `wire`，没有解释过；
> `reg` 从头到尾只出现在我写的测试台里。2026-10-29 的记录里写过「测试台语法几乎完全没教」，
> 今天补上了。
>
> 现在在第 0 节，是这一课第一节。一句话版：
> **`wire` 是连线，只能在 `assign` 里赋值；`reg` 是能存值的变量，只能在 `always` / `initial` 里赋值；
> `reg` 不等于触发器，是不是触发器由外面那个 `always` 决定。**
>
> `reg signed [7:0] s;` 里的 `signed` 只说「读它的时候按有符号读」，和 `reg` 能不能存值无关，
> 是两件不相干的事。

> [!question]- 提问 · 这节课太长了，很多东西我都没学过
> **原话**
> 这节课太长了，很多东西我都不知道
>
> **整理**（写在文件末尾）
> This lesson is too long, and much of it is material I have not had.
>
> **回答**
>
> 成立，原因有三类，分开说：
>
> | 哪一类 | 具体是什么 | 处理 |
> |---|---|---|
> | 我漏教 | `wire` / `reg` 从没讲过 | 补成第 0 节，放在最前面 |
> | 我写多了 | 4 位表讲两遍、8 位表 16 行、登录名表、`signed` 整节、溢出整节 | 删掉或挪去第 03 课 |
> | 我没讲清 | 减法的 `+1`、进位是什么、进位输出的两种含义 | 第 4 节重写成两行推导 |
>
> 删掉的内容不会丢：溢出进第 03 课（那一课有 `always @*` 的例子才讲得动），
> `signed` 只留在 `examples/02_adder/sim/README.md`。
>
> 这一课是这一轮唯一以**新模型**为主的课，第 03 课是语法和电路结构，不叠新模型。
> 判法很直接：一段 15 分钟推不完，就说明还有没讲清的地方，直接在那段下面写。

### Q1 (I set this one)

> On paper, write the 8-bit value of `-100` in binary using "invert and add one" from a positive
> number, and then read the same bits back unsigned. What are the two numbers, and how far apart
> are they?

> **中文**：用「取反加一」把 `-100` 写成 8 位二进制，再把同一组位当无符号读。
> 两个数分别是多少，差多少？这个差是多少位的 2 的幂？

### Q2

> `1111_1111 + 0000_0001` in 8 bits gives `0000_0000` with the carry out equal to 1. Read the
> result as unsigned, then as signed. Did an unsigned overflow happen, a signed one, or both?

> **中文**：8 位里 `1111_1111 + 0000_0001` 得 `0000_0000`，进位输出是 1。
> 先把结果当无符号读，再当有符号读。发生了无符号溢出、有符号溢出，还是两个都发生了？
