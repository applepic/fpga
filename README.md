# FPGA Projects

用 Verilog 从零实现一个 RV32I 处理器核，并在 FPGA 上跑通。

> **状态（2026-10-12）：规划阶段，尚未开始写代码。**
> 仓库建于 2026-05-18，只有一个空 README。`rv32i/` 目录已建但为空。

## 环境（已就绪）

| 用途 | 工具 | 位置 |
|---|---|---|
| 仿真 | `iverilog` / `verilator` | `C:\Local_Data\oss-cad-suite\bin\` |
| 综合 | `yosys` | 同上 |
| 布局布线 | `nextpnr-himbaechel`（支持 Gowin） | 同上 |
| 烧录 | `openFPGALoader` | 同上 |
| 厂商 IDE（备用） | Gowin EDA | 配置在 `C:\Users\str\.gowinsemi` |
| 编辑器 | VS Code + Verilog HDL 扩展 | 已装 |

工具链版本：oss-cad-suite `20260518`。

## 文档

- [AGENTS.md](AGENTS.md) — AI 开工须知，**动手前先读**
- [SPEC.md](SPEC.md) — 架构边界与规划，含**未确认的开放问题**
- [LOG.md](LOG.md) / [LOG-INDEX.md](LOG-INDEX.md) — 变更史

## 开工前必须先定的事

[SPEC.md](SPEC.md) 的「开放问题」那一节还没确认，其中三条会直接影响第一行代码怎么写：

1. 目标板型号（推测 Tang Nano 9K，没有证据）
2. 单周期起步还是直接上流水线
3. 仿真器选 iverilog 还是 Verilator

**这三条定了再动手。**
