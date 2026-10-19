# FPGA Projects

从零学 FPGA，终点是用 Verilog 实现一个 RV32I 处理器核，在 **Tang Nano 9K** 上跑通。

> **状态（2026-10-18）：工具链已打通并验证，学习阶段，尚未开始写自己的 RTL。**
> 学习路线见 [LEARNING.md](LEARNING.md)。

## 现在该做什么

**从 [第 1 课](lessons/01_verilog_basics.md) 开始。** 不要直接跳到 RV32I。

课程一课一课走，每课配一个练习目录：`sim/` 里是 testbench（验收标准，不许改），
`rtl/` 是空的，由你来填。

```powershell
cd C:\Local_Data\Dev\fpga
. .\env.ps1
.\scripts\sim.ps1 -Project examples/00_gates
```

跑起来会报 `Unknown module type`，这就是起点。

课程目录与进度表见 [lessons/README.md](lessons/README.md)。

## 环境

**开新终端先跑一次 `. .\env.ps1`**（前面那个点不能省）。

| 命令 | 作用 |
|---|---|
| `.\scripts\sim.ps1 -Project <目录>` | iverilog 仿真，产出 `build/tb.vcd` |
| `.\scripts\sim.ps1 -Project <目录> -Open` | 同上，并打开 gtkwave 看波形 |
| `.\scripts\build.ps1 -Project <目录>` | 综合 + 布局布线 + 生成 `build/top.fs` |
| `.\scripts\flash.ps1 -Project <目录>` | 烧 SRAM（掉电丢） |
| `.\scripts\flash.ps1 -Project <目录> -Flash` | 烧 Flash（掉电保留） |

**自检**：`.\scripts\sim.ps1 -Project infra/toolchain_smoke` 和
`.\scripts\build.ps1 -Project infra/toolchain_smoke` 都应该通过。
这两个不通，说明工具链有问题，不要往下学。

工具链在 `C:\Local_Data\oss-cad-suite`，版本 `20260518`：
iverilog 14.0 / yosys 0.65 / nextpnr 0.10 / openFPGALoader 1.1.1 / gtkwave。

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
| 按键 | 2 个用户按键（引脚 4、3，低电平按下） |
| LED | 6 个（引脚 10/11/13/14/15/16，**低电平点亮**） |
| 调试器 | 板载 BL702，USB-JTAG + USB-UART（TX=17，RX=18） |
| 显示接口 | HDMI、RGB 屏、SPI 屏 |

引脚全部写在 `constraints/tangnano9k.cst`，来源与核对日期记在文件头。

> **器件型号的坑**：datasheet 写 `GW1NR-LV9QN88PC6/I5`，
> Gowin IDE 里要选 `GW1NR-UV9QN88C6/I5`。
> 开源工具链用 datasheet 那个名字，另外必须加 `--vopt family=GW1N-9C`。

## 文档

| 文件 | 内容 |
|---|---|
| [lessons/README.md](lessons/README.md) | **课程目录与进度表**。一课一课怎么走过去 |
| [lessons/01_verilog_basics.md](lessons/01_verilog_basics.md) | **第 1 课**：`wire` / `assign` / 位运算 / 仿真机制 |
| [LEARNING.md](LEARNING.md) | **学习路线**。三个阶段 + 每阶段的客观验收标准 + 工具链的坑 |
| [SPEC.md](SPEC.md) | RV32I 的架构边界与规划 |
| [AGENTS.md](AGENTS.md) | AI 开工须知 |
| [LOG.md](LOG.md) / [LOG-INDEX.md](LOG-INDEX.md) | 变更史 |
| `docs/` | 参考书，不进 git |

> **路线 vs 课程**：`LEARNING.md` 说「阶段 A 要会时序逻辑」，
> `lessons/` 说「第 2 课讲 `always`，第 3 课写计数器」。前者是目标，后者是路径。

## 参考资源

- [Gisselquist 的 Verilog 教程](https://zipcpu.com/tutorial/)，10 课，从 C 基础到串口收发
- Readler《Verilog by Example》，114 页语法速查，在 `docs/`
- [Sipeed Wiki](https://wiki.sipeed.com/hardware/zh/tang/Tang-Nano-9K/Nano-9K.html)，板子和工具链的一切
