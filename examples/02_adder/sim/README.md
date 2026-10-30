# Specification for `tb_sign.v`: your first testbench

This file says what a correct `tb_sign.v` must do. It is the contract both of us work from: you
write `tb_sign.v` from it, and I keep a second, hidden testbench written from the same text. When
the two disagree, the disagreement points at one copy of this file going stale, not at "one of the
testbenches is right". The reason is in `lessons/README.md`, checkpoint 4.

Every rule below is one that I ran in iverilog before shipping this file, so it is a measured
statement about this simulator, not Verilog textbook prose.

> 这份文件是 `tb_sign.v` 的规格。你照着它写，我另有一份从同一份文字写出来的隐藏测试台，
> 两边对上才算过。下面每条规则都在 iverilog 里跑过一次，是实测，不是教科书说法。

## Rule 5: the same eight bits, two readings / 同样的位，两种读法

In Verilog the bits do not change, only how you read them does:

> 位不变，变的只是读法：

| Declaration | Bits | Reads as |
|---|---|---|
| `reg [7:0] u;` | `8'hff` | 255 |
| `reg signed [7:0] s;` | `8'hff` | -1 |

**The test must show that difference.** The obvious way to write it is `if (u !== s) ...` after
assigning `8'hff` to both, and that can never fail: `!==` compares the eight bit values, which are
equal by construction. A test that cannot fail proves nothing.

> **测试必须把这个差别测出来。** 最顺手的写法是两边都赋 `8'hff` 再比 `u !== s`，这种写法永远不失败：
> `!==` 比的是八位的值，它们本来就相等。**不会失败的测试什么也没证明。**

**So the comparison has to be a number comparison.** In Verilog the sign of a comparison is decided
by the operands: if both sides are signed, both are read as signed numbers and the narrow one is
sign-extended. If either side is unsigned, the whole comparison goes unsigned and every operand is
zero-extended. Two consequences:

> **所以比较必须变成「数的比较」。** 比较的符号由操作数决定：两边都有符号，就按有符号读，窄的一边符号扩展；
> 只要一边无符号，整条比较按无符号走，所有操作数零扩展。两个后果：

- `if (u !== s)` is unsigned, so `s` is zero-extended: `1111_1111` reads 255 on both sides
- `if (s !== -1)` compares a signed reg with an unsized literal (a plain number), so it reads `s`
  signed correctly

> - `u !== s` 是无符号比较，`s` 被零扩展，两边都是 255，永远相等
> - `s !== -1` 是「有符号 reg 对普通数字」，`s` 按有符号读，才测得出

**Required cases**, taken from the spec:

> **必须覆盖的四个值**，来自规格：

| Bits | Unsigned reading | Signed reading |
|---|---|---|
| `8'h00` | 0 | 0 |
| `8'h7f` | 127 | 127 |
| `8'h80` | 128 | -128 |
| `8'hff` | 255 | -1 |

Write each case so that deleting `signed` from the declaration of `s` makes it fail. That is the
only evidence that the test is testing rule 5 rather than the `!==` operator.

> 每个用例都要做到：把 `s` 声明里的 `signed` 删掉，测试就失败。
> 只有这一点能证明测的是规则 5，而不是 `!==` 本身。

**How to see the mechanism for yourself, without me telling you the answer.** Make a tiny testbench
that assigns `8'hff` to both `u` and `s`, prints both with `%0d`, and runs. Then delete `signed`
and run again. `%0d` of a signed variable prints it signed, which I did verify; what changes when
`signed` goes away is the part I am not going to tell you in advance.

> **自己看机制的办法。** 写一个极小的测试台，把 `8'hff` 同时赋给 `u` 和 `s`，两个都用 `%0d` 打印，跑一次；
> 然后删掉 `signed` 再跑一次。有符号变量的 `%0d` 按有符号打印，这一点我验过；
> 删掉之后哪里变了，这个我先不告诉你。

## Rule 6: sign extension keeps the value / 符号扩展保持数值不变

`assign y = {{8{x[7]}}, x};` is a sign extension written in Verilog. The specification states what
it must do in terms of values, not bits:

> `assign y = {{8{x[7]}}, x};` 是 Verilog 里写符号扩展的写法。规格说的是数值，不是位：

| `x` | `y` must read as, signed | `y` must read as, unsigned |
|---|---|---|
| `8'hff` (-1) | -1 | 65535 |
| `8'h80` (-128) | -128 | 65408 |
| `8'h40` (64) | 64 | 64 |
| `8'h00` (0) | 0 | 0 |

> 中文说明：第三列是 `y` 的位，第四列是同一组位当无符号读的结果，两列都要对。

**The test to write.** Declare two signed registers next to the DUT wires, one per width, and
compare them:

> **要写的测试。** 在 DUT 的线旁边声明两个有符号 reg，各一种宽度，然后比较它们：

```verilog
reg signed [7:0]  sx;
reg signed [15:0] sy;
```

Above are the declarations; here is the body, run once per case:

> 上面是声明，下面是每个用例执行的语句：

```verilog
x = 8'hff; #1;      // #1 lets the combinational output settle
sx = x;  sy = y;
if (sx !== sy) $display("FAIL: sign extension changed the value");
```

Both sides are signed, so the narrow one gets sign-extended: good for the check, and useless for
showing the bug in your own RTL, because the same mechanism is then used twice. That is why the
unsigned column exists, and why it goes into a separate check:

> 两边都有符号，窄的一边会被符号扩展：做检查很好，但暴露不了你自己 RTL 的错，因为同一个机制用了两次。
> 这就是要有第三列的原因，它单独一条检查：

```verilog
if (y !== 16'd65535) $display("FAIL: 8'hff extended to %0d, expected 65535 unsigned", y);
```

`y` is an unsigned 16-bit wire, so the 16-bit literal is compared bit for bit, and this catches a
design whose top eight bits are not copies of `x[7]`.

> `y` 是无符号 16 位 wire，所以 16 位字面量逐位比较，上面八个位不是 `x[7]` 的副本就抓得到。

**Required cases:** all four rows of the table. Negative, positive, zero, and a value whose sign
bits are not all ones (`8'h80`). State in your file, as a comment, what each case is there to
catch. A case list without that column is guessing.

> **必须覆盖**：表的四行全部。负数、正数、零，以及符号位不全是 1 的负数（`8'h80`）。
> 在你的文件里用注释写清楚每个用例是用来抓什么的，没有这一列的用例列表只是猜。

## `rtl/sign_extend.v` interface

> 接口：

```verilog
module sign_extend (
    input  wire [7:0]  x,
    output wire [15:0] y
);
```

Combinational, no clock and no `always`. When your `tb_sign.v` passes, come and tell me.

> 组合逻辑，没有时钟，不用 `always`。你的 `tb_sign.v` 过了就来告诉我。

## What happens after you say "done"

I run my hidden testbench, written from this file, with different values from the spec (`8'hc0`,
`8'h01`, `8'h3f`, ...). If the two disagree we find out why before you move on. That is why the
hidden one is announced up front rather than kept a secret.

> 我会用同一份规格写出的隐藏测试台跑一遍，值不一样（`8'hc0`、`8'h01`、`8'h3f` 这些）。
> 两边不一致就先查清楚再往下走。隐藏测试台提前告诉你，而不是瞒着。
