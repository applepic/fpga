# 练习 01：4 位计数器

**目标**：写出一个 0 到 15 循环的二进制计数器。

**对应路线**：阶段 A，验收第 1 条。

## 你要写的文件

`rtl/counter.v` —— 这个文件现在**不存在**，由你创建。

模块接口已经定死在 testbench 里，不要改名字：

```verilog
module counter (
    input  wire       clk,     // 时钟
    input  wire       rst_n,   // 复位，低有效
    output reg  [3:0] q        // 计数值
);
```

## 跑法

```powershell
. .\env.ps1
.\scripts\sim.ps1 -Project examples/01_counter
```

现在跑会报错，因为 `rtl/counter.v` 还没有。这就是起点。

## 验收

`sim/tb_counter.v` 里的检查全部 PASS。**这个 testbench 是验收标准，不要改它。**
如果你觉得它写错了，来问我，不要自己改。

它检查三件事：
1. 复位期间 `q = 0`
2. 每个时钟上升沿 `q` 加 1
3. 数到 15 之后回 0

## 提示（卡住超过 30 分钟再看）

<details>
<summary>展开</summary>

- 计数器是**时序逻辑**，要用 `always @(posedge clk)`，不能用 `assign`
- 复位用**同步复位**还是**异步复位**？两个都能通过这个 testbench，
  但你要能说出区别。Gisselquist L02 讲了这个
- 4 位寄存器自然就在 15 之后回 0，不需要写 `if (q == 15)`。想想为什么
- `reg` 在这里只是「在 always 块里被赋值的变量」的意思，不等于触发器。
  这个区别是阶段 A 验收第 4 条

</details>

## 做完之后

1. 自己用 `-Open` 看一眼波形，确认 `q` 确实是在上升沿变的
2. 来告诉我，我出题检验。**不要自己宣布通过**

## 上板（可选）

这个练习默认不用上板，但如果你想看 LED 跟着计数变：
把 `q` 接到 `led[3:0]`，注意**低电平点亮**，所以要取反。
然后 `.\scripts\build.ps1 -Project examples/01_counter` 再 `flash.ps1`。
上板时记得把时钟分频，否则 27 MHz 下 16 个状态一闪就过，肉眼看不见。
