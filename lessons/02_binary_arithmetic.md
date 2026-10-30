# Lesson 02 · Binary arithmetic and signed numbers / 二进制运算与有符号数

> Bilingual, 2026-10-28 format: English is the primary text and complete on its own, Chinese
> follows each paragraph as a blockquote. Code, signal names, commands and error messages are
> never translated.
>
> 中英对照。英文是正文，单独读也完整；中文按段落跟在后面，放在引用块里。
> 代码、信号名、命令、报错原文不翻译。
>
> Previous: `lessons/legacy_01_verilog_basics.md` and the vault note `Lesson-01-Combinational-Logic`
> (the first lesson under the old numbering; you passed it on 2026-10-29).
> Next: [[Lesson-03-Always-and-Clocks]]
> Exercise: `examples/02_adder`. This lesson is the one you asked for at the end of lesson 1, so
> the two rules you already met are kept short and the new ones are the focus.

---

## 0. Why this lesson exists / 为什么有这一课

You worked out the 4-bit table from `1100` yourself in lesson 1. This lesson does the same for
**eight bits**, adds the arithmetic the ALU needs, and covers what you did not do yet: sign
extension, subtraction, overflow, and how Verilog decides which of the two readings a comparison
uses. The RV32I core does all of it on 32-bit values, every instruction.

> 第 1 课你自己从 `1100` 推出了 4 位的表。这一课把它做到**8 位**，补上 ALU 要用的加法和减法，
> 再讲你还没碰过的：符号扩展、溢出、以及 Verilog 比较时按哪种读法算。
> RV32I 里面每条指令都在 32 位上做这些事。

**Your table.** In section 2 you build the signed/unsigned table for the eight bits made of the
characters of your UC Davis login name (the part before `@`, lower case). It is your own string,
so the answer is not in this file by design.

> **你的表**：第 2 节要你做一张 8 位的表，用你 UC Davis 登录名（`@` 前面那段，小写）的字符拼。
> 那是你自己的字符串，所以答案本来就不在这份文件里。

## 1. The 4-bit table again, faster / 4 位的表再来一遍

The method you chose in lesson 1 stays: read the bits as unsigned, and if the top bit is 1,
subtract 2ⁿ.

> 第 1 课你选的算法不变：先当无符号读，最高位是 1 就减 2ⁿ。

| Bits | Unsigned | Signed | Subtraction |
|---|---|---|---|
| `0000` | 0 | 0 | none |
| `0001` | 1 | 1 | none |
| `0111` | 7 | 7 | none |
| `1000` | 8 | -8 | 8 - 16 |
| `1011` | 11 | -5 | 11 - 16 |
| `1100` | 12 | -4 | 12 - 16 |
| `1111` | 15 | -1 | 15 - 16 |

> | 位 | 无符号 | 有符号 | 减法 |
> |---|---|---|---|
> | `0000` | 0 | 0 | 不用减 |
> | `0001` | 1 | 1 | 不用减 |
> | `0111` | 7 | 7 | 不用减 |
> | `1000` | 8 | -8 | 8 - 16 |
> | `1011` | 11 | -5 | 11 - 16 |
> | `1100` | 12 | -4 | 12 - 16 |
> | `1111` | 15 | -1 | 15 - 16 |

## 2. Eight bits, and the same 2ⁿ / 8 位，还是那个 2ⁿ

Eight bits is the same rule with a bigger n. Two examples:

> 8 位就是同一个规则换个大一点的 n。两个例子：

```text
1011_0100      unsigned 180, top bit 1, so 180 - 256 = -76
0110_1100      unsigned 108, top bit 0, so it stays   +108
```

> ```text
> 1011_0100      无符号 180，最高位 1，180 - 256 = -76
> 0110_1100      无符号 108，最高位 0，保持 +108
> ```

**Two facts that make the table fast**, both from the last lesson's `-1` row:

> **让推表变快的两件事**，都来自上一课 `-1` 那一行：

- `1111_1111` is -1. Every `1` in a two's complement number adds 2ⁿ; all ones with the sign is
  -1. `1111_1110` is -2 (turn off the last 1 bit, it is 2⁰ = 1), `1111_1100` is -4.
- `1000_0000` is -128 and `0111_1111` is 127, so 8 bits holds -128 to 127, 256 values in all.

> - `1111_1111` 是 -1。补码里每一位 `1` 都加 2ⁿ，全是 1 就是 -1。
>   `1111_1110` 是 -2（去掉最低位那个 1，它是 2⁰=1），`1111_1100` 是 -4。
> - `1000_0000` 是 -128，`0111_1111` 是 127，所以 8 位是 -128 到 127，一共 256 个值。

**Your table** (bits go 0000_0000 to 1111_1111, 16 rows):

> **你的表**（0000_0000 到 1111_1111，共 16 行）：

| Bits | Unsigned | Signed |
|---|---|---|
| `0000_0000` | 0 | 0 |
| `0000_0001` | 1 | 1 |
| `0000_0010` | 2 | 2 |
| `0000_0011` | 3 | 3 |
| `0000_0100` | 4 | 4 |
| `0000_0101` | 5 | 5 |
| `0000_0110` | 6 | 6 |
| `0000_0111` | 7 | 7 |
| `0000_1000` | 8 | 8 |
| `0000_1001` | 9 | 9 |
| `0000_1010` | 10 | 10 |
| `0000_1011` | 11 | 11 |
| `0000_1100` | 12 | 12 |
| `0000_1101` | 13 | 13 |
| `0000_1110` | 14 | 14 |
| `0000_1111` | 15 | 15 |

The bottom sixteen rows are the ones made of your login name's characters; I will add them when
you show the paper.

> 下面那 16 行对应你用登录名拼出来的那些位，等你把纸上的拿给我看，我在这里补全。

## 3. Adding in binary: the carry / 二进制加法：进位

Column by column, right to left, exactly like decimal, carrying 1 when the column totals 2:

> 一列一列从右往左，和十进制一模一样，一列加起来到 2 就进 1：

```text
    0 1 1 0      (6)
  + 0 1 0 1      (5)
  ----------
    1 0 1 1      (11)
```

> ```text
>     0 1 1 0      (6)
>   + 0 1 0 1      (5)
>   ----------
>     1 0 1 1      (11)
> ```

And when the top column carries out, the result needs one more bit than either input:

> 最高列也进位出去时，结果比两个加数都多一位：

```text
    1 0 1 1      (11)
  + 0 1 1 0      (6)
  ----------
  1 0 0 0 1      (17)   the fifth bit is the carry out
```

> ```text
>     1 0 1 1      (11)
>   + 0 1 1 0      (6)
>   ----------
>   1 0 0 0 1      (17)   这第五位就是进位输出
> ```

That is why an adder block has a **carry in** and a **carry out**: chaining 32 of them gives a
32-bit adder, and the hardware has no idea what the bits mean, only where the carries go.
Naming it "carry" is just the usual label for the wire that holds this column's overflow into the
next one; nothing in the circuit depends on the word.

> 这就是**进位输入**和**进位输出**的来历：32 个串起来就是 32 位加法器。
> 硬件不知道这些位是数还是别的，它只负责把进位接下去。

## 4. Subtraction is addition / 减法就是加法

Two's complement has one property that reduces the ALU to one adder:

> 补码有一个性质，让 ALU 只需要一个加法器：

```text
a - b  =  a + (-b) = a + (~b + 1)
```

> ```text
> a - b  =  a + (-b) = a + (~b + 1)
> ```

`~b + 1` is the negation, because flipping every bit takes b to `2ⁿ - 1 - b`, and adding 1 gives
`2ⁿ - b`, which is -b in n bits. So `SUB` is `ADD` with the b input inverted and the carry in set
to 1. That is a real decision for the RV32I ALU and it is why lesson 12 has one adder and not two.

> `~b + 1` 就是取负：逐位取反把 b 变成 `2ⁿ - 1 - b`，加 1 得 `2ⁿ - b`，在 n 位里就是 -b。
> 所以 `SUB` 就是「b 取反、进位输入拉 1」的 `ADD`。这直接决定第 12 课的 ALU 用一个加法器而不是两个。

Check with 4 bits, `3 - 5`:

> 用 4 位验一下，`3 - 5`：

```text
  3       0011
  5       0101
  ~5      1010
  ~5 + 1  1011     that is -5 in 4 bits
  0011 + 1011 = 1110    read as signed: 14 - 16 = -2   correct
```

> ```text
>   3       0011
>   5       0101
>   ~5      1010
>   ~5 + 1  1011     这就是 4 位的 -5
>   0011 + 1011 = 1110    按有符号读：14 - 16 = -2   对
> ```

The carry out of this addition is 0, and that is the signal for "the result went below zero when
we read it unsigned", i.e. 3 < 5. It has a different meaning for `SUB` than for `ADD`: for `SUB`
the usual word for it is "a borrow happened". Keep that in mind for `SLT`.

> 这次加法的进位输出是 0，表示「当无符号算时发生了借位」，也就是 3 < 5。
> 同一个进位在 `SUB` 和 `ADD` 里含义不同：`SUB` 里它表示借位。这个后面 `SLT` 要用。

## 5. Overflow: the wrong answer that carries no signal / 溢出：出了错却没信号

The carry out is about the **unsigned** boundary. Overflow is about the **signed** one, and it is
the dangerous case because the bits look perfectly normal:

> 进位管的是**无符号**的边界。溢出管的是**有符号**的边界，而且危险，因为结果位看上去完全正常：

```text
  0 111 1111   ( +127)
+ 0 000 0001   (   +1)
-----------
  1 000 0000   unsigned 128, signed -128    both rows "fine", the total is not 128 as a signed value
```

> ```text
>   0 111 1111   ( +127)
> + 0 000 0001   (   +1)
> -----------
>   1 000 0000   无符号 128，有符号 -128
> ```

Adding two positive numbers gave a negative one, so signed overflow happened. The rule that
detects it, in one line: **the carry into the sign bit differs from the carry out of the sign
bit.** Positive plus positive crossing into negative, or negative plus negative crossing into
positive, are the same rule. RISC-V has no flag for it: `ADD` wraps and ignores it. `SLT`,
branches and the software all have to keep their values inside the range. You will meet the rule
again in lesson 12; for now, know that "it wrapped and nothing told me" is normal.

> 两个正数加起来得到负数，就是有符号溢出。判断规则一句话：**进入符号位的进位和从符号位出去的进位不同。**
> 正加正变负、负加负变正，都是这一个规则。RISC-V 不设溢出标志：`ADD` 直接回绕不管。
> 保不保得住范围是 `SLT`、分支和软件的事。第 12 会再见这条规则；现在只要知道「回绕了而且没有任何信号」是正常的。

## 6. Sign extension, measured / 符号扩展，实测

In lesson 1 you saw `1111` extended to `11111111` keeps -1 while zero extension turns it into 15.
Here is the 8-bit to 16-bit version with the values you will use in the testbench:

> 第 1 课你看过 `1111` 扩成 `11111111` 保持 -1，零扩变成 15。
> 这里是 8 位到 16 位，用测试台里要用的值：

| `x` | Zero-extended, unsigned | Sign-extended, unsigned | Sign-extended, signed |
|---|---|---|---|
| `0000_0000` | 0 | 0 | 0 |
| `0100_0000` (64) | 64 | 64 | 64 |
| `1000_0000` (-128) | 128 | 65408 | -128 |
| `1111_1111` (-1) | 255 | 65535 | -1 |

> | `x` | 零扩展，当无符号 | 符号扩展，当无符号 | 符号扩展，当有符号 |
> |---|---|---|---|
> | `0000_0000` | 0 | 0 | 0 |
> | `0100_0000` (64) | 64 | 64 | 64 |
> | `1000_0000` (-128) | 128 | 65408 | -128 |
> | `1111_1111` (-1) | 255 | 65535 | -1 |

The "sign-extended, unsigned" column is not a typo and it is the column that catches bugs: the
bits are right and the number reads as 65535, because reading extends without knowing you meant a
signed value. **Which column a number lands in is decided by how the consuming side reads it**, not
by what the producer wrote. For RV32I's immediates that consumer is the ALU and the address
adder, and both are told "signed" once, at the module boundary.

> 「符号扩展，当无符号」这一列不是笔误，正是能抓 bug 的那一列：位是对的，
> 但读出来还是 65535，因为**读的一方不知道你以为它是有符号的**。
> **一个数落在哪一列，由读它的那一方决定，不由写它的那一方决定。**
> RV32I 里读立即数的是 ALU 和地址加法器，两者的「有符号」只在模块接口处声明一次。

## 7. What Verilog does with `signed`, measured / Verilog 的 `signed` 到底干什么，实测

Two declarations, same bits:

> 两个声明，同样的位：

```verilog
reg [7:0]        u;   // u = 8'hff reads as 255
reg signed [7:0] s;   // s = 8'hff reads as -1
```

> ```verilog
> reg [7:0]        u;   // u = 8'hff 读出来是 255
> reg signed [7:0] s;   // s = 8'hff 读出来是 -1
> ```

`!==` compares bits, so `u !== s` is false and can never catch the difference. What decides the
reading is the **comparison**: if both sides are signed, both are read as signed numbers and the
narrow one is sign-extended; if either side is unsigned, everything is read unsigned and
zero-extended. Measured in iverilog for this project:

> `!==` 比的是位，所以 `u !== s` 永远是假的，抓不到区别。决定读法的是**比较本身**：
> 两边都有符号就按有符号比，窄的一边符号扩展；只要有一边无符号，全部按无符号比、零扩展。
> 本项目 iverilog 实测：

```text
u !== s            unsigned comparison, s zero-extended   -> both read 255, equal
s !==  -1          signed comparison, s read as signed    -> equal, -1
u !== 255          unsigned comparison                    -> equal
$signed(y) in %0d  shows the signed reading of an unsigned reg
```

> ```text
> u !== s            无符号比较，s 被零扩展   -> 两边都是 255，相等
> s !==  -1          有符号比较，s 按有符号读 -> 相等，-1
> u !== 255          无符号比较              -> 相等
> $signed(y) 配 %0d  显示无符号 reg 的有符号读法
> ```

One consequence you will meet in the exercise: a comparison between two signed regs of different
widths sign-extends the narrow one, so it can only prove that the extension is self-consistent,
not that it is right. You need both a signed check and an unsigned check with the literal bits,
which is what `examples/02_adder/sim/README.md` asks for.

> 练习里会遇到的一个后果：两个不同宽度的有符号 reg 比较时，窄的那个会被符号扩展，
> 所以它能证明「扩展前后你读法一致」，证明不了「扩展是对的」。
> 需要一次有符号比较加一次对具体位和字面量的无符号比较，`examples/02_adder/sim/README.md` 就是这么要求的。

## 8. Your task / 你的任务

Two parts in `examples/02_adder/`:

> `examples/02_adder/` 里两个部分：

| Part | File | Graded by |
|---|---|---|
| 1. one-bit full adder (carry in, carry out) | `rtl/full_adder.v` | `sim/tb_adder.v`, mine, 8 rows |
| 2. two's complement + sign extension | `rtl/sign_extend.v` **and your own `sim/tb_sign.v`** | the specification in `sim/README.md`, plus my hidden copy |

Part 2 is the first testbench you write. It is also the first place where the table of expected
values is your responsibility rather than mine.

> 第 2 部分是你写的第一份测试台，也是第一次期望值的表归你管。

Run:

> 运行：

```powershell
cd C:\Local_Data\Dev\fpga
. .\env.ps1
.\scripts\sim.ps1 -Project examples/02_adder
```

**Pass condition, part 1:** `=== tb PASS === all 8 rows match`.

> **第 1 部分通过条件**：`=== tb PASS === all 8 rows match`。

Then the exercise asks you to run three wrong versions and see which rows catch them. Do that
before you move on: a test you have not seen fail is a test you do not know the coverage of.

> 然后按 README 改三个错版本，看哪几行抓到。**没见它失败过的测试，你不知道它覆盖了什么。**

Time budget: 15 minutes reading the two tables you already know, 20 minutes on the adder and its
wrong versions, 30 to 45 minutes on your own testbench.

> 时间：15 分钟读两张你已经会的表，20 分钟做加法器和三个错版本，30 到 45 分钟写你自己的测试台。

## 9. Questions / 问题

Write your questions anywhere in this file, under the paragraph that caused them. The whole file
is read every time. Original words stay, answers go in place.

> 问题写在这份文件的任何位置，哪一段看不懂就写在下面。每次都读整篇，原话照抄，回答就地写在下面。

### Q1 (I set this one)

> Fill the 8-bit table with your login name's characters, show the paper, and answer this: which
> rows of your table hold negative numbers, and what does that tell you about the first character
> of your login name?

> **中文**：用登录名的字符填满 8 位表，把纸上的拿给我看，并回答：你的表里哪些行是负数，
> 这说明了登录名第一个字符的什么？

### Q2

> `1111_1111 + 0000_0001` in 8 bits gives `0000_0000` with the carry out equal to 1. Read the
> result as unsigned, then as signed. Did an unsigned overflow happen, a signed one, or both?

> **中文**：8 位里 `1111_1111 + 0000_0001` 得 `0000_0000`，进位输出是 1。
> 先把结果当无符号读，再当有符号读。发生了无符号溢出、有符号溢出，还是两个都发生了？
