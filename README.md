# FPGA Projects

从零学 FPGA，终点是用 Verilog 实现一个 RV32I 处理器核，在 **Tang Nano 9K** 上跑通。

> **状态（2026-10-12）：学习阶段，尚未开始写 RTL。**
> 板子已确认。学习路线见 [LEARNING.md](LEARNING.md)。

## 现在该做什么

**从 [LEARNING.md](LEARNING.md) 的阶段 0 开始。** 不要直接跳到 RV32I。

阶段 0 是环境打通，目标是不看教程独立完成一次「写代码 → 综合 → 约束 → 布局布线 → 烧录」。

## 板子

**Sipeed Tang Nano 9K**

| 项 | 值 |
|---|---|
| FPGA | GW1NR-LV9QN88PC6/I5 |
| 逻辑单元 | 8640 LUT4 |
| 寄存器 | 6480 FF |
| 块状 RAM | 26 个 BSRAM，共 468K bits |
| 板载存储 | 32Mbit SPI Flash，64Mbit PSRAM |
| 时钟 | 27 MHz 晶振 |
| 按键 | 2 个用户按键 |
| LED | 6 个（低电平点亮） |
| 调试器 | 板载 BL702，USB-JTAG + USB-UART |
| 显示接口 | HDMI、RGB 屏、SPI 屏 |

## 环境（已就绪）

| 用途 | 工具 | 位置 |
|---|---|---|
| 仿真 | `iverilog` / `verilator` | `C:\Local_Data\oss-cad-suite\bin\` |
| 综合 | `yosys` | 同上 |
| 布局布线 | `nextpnr-himbaechel` | 同上 |
| 烧录 | `openFPGALoader` | 同上 |
| 厂商 IDE（交叉验证用） | Gowin EDA | 配置在 `C:\Users\str\.gowinsemi` |
| 编辑器 | VS Code + Verilog HDL 扩展 | 已装 |

工具链版本：oss-cad-suite `20260518`。

## 文档

| 文件 | 内容 |
|---|---|
| [LEARNING.md](LEARNING.md) | **学习路线**。四个阶段 + 每阶段的客观验收标准 |
| [SPEC.md](SPEC.md) | RV32I 的架构边界与规划，含未确认的开放问题 |
| [AGENTS.md](AGENTS.md) | AI 开工须知，动手前先读 |
| [LOG.md](LOG.md) / [LOG-INDEX.md](LOG-INDEX.md) | 变更史 |
| `docs/` | 参考书，不进 git |

## 参考资源

- [Gisselquist 的 Verilog 教程](https://zipcpu.com/tutorial/)，10 课，从 C 基础到串口收发
- Readler《Verilog by Example》，114 页语法速查，在 `docs/`
- [Sipeed Wiki](https://wiki.sipeed.com/hardware/zh/tang/Tang-Nano-9K/Nano-9K.html)，板子和工具链的一切
