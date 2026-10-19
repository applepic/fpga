# 练习 00：四个基本门

**对应课程**：[第 1 课](../lessons/01_verilog_basics.md)

**这一课的目标不是学会写门电路**（那个太简单了），是让你亲眼看见
"Verilog 描述的是电路结构，不是执行顺序"。

## 你要写的文件

`rtl/gates.v` —— 现在**不存在**，由你创建。

```verilog
module gates (
    input  wire a,
    input  wire b,
    output wire y_and,   // a & b
    output wire y_or,    // a | b
    output wire y_xor,   // a ^ b
    output wire y_not    // ~a
);
```

## 跑法

```powershell
cd C:\Local_Data\Dev\fpga
. .\env.ps1
.\scripts\sim.ps1 -Project examples/00_gates
```

## 验收

`sim/tb_gates.v` 打印的四种组合全部正确，最后一行是 `=== 全部通过 ===`。

**这个 testbench 是验收标准，不要改它。**

## 做完之后

1. 用 `-Open` 看一眼波形（`. .\env.ps1` 之后 `.\scripts\sim.ps1 -Project examples/00_gates -Open`），
   看 `a` 和 `b` 变化的时候，四个输出是不是**立刻**跟着变，没有任何延迟
2. 把 `assign` 那几行的顺序打乱，重跑，确认结果完全一样
3. 回来找我出题
