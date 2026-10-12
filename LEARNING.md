---
status: 进行中
last_updated: 2026-10-12
---

# FPGA 学习路线

> 目标：从零学会用 Verilog 做 FPGA 设计，最终能独立实现 RV32I 处理器核。
> 板子：**Tang Nano 9K**（GW1NR-LV9QN88PC6/I5，8640 个 LUT4，27 MHz 板载晶振）

## 三个资源，分工不同

| 资源 | 定位 | 怎么用 |
|---|---|---|
| [Gisselquist 的 10 课](https://zipcpu.com/tutorial/) | **主线**。从 C 基础一路到串口收发 + FIFO | 按顺序做，每课都有可下载的示例代码 |
| Readler《Verilog by Example》（114 页） | **语法速查**。书薄，适合当参考手册 | 主线卡住时查对应章节，**不要从头读到尾** |
| [Sipeed Wiki](https://wiki.sipeed.com/hardware/zh/tang/Tang-Nano-9K/Nano-9K.html) + 官方例程 | **板子相关的一切**。引脚、约束、工具链 | 只在需要碰硬件时查 |

为什么这么分：Gisselquist 的课把「语言 + 工具 + 调试」绑在一起教，这正是自学者最容易断的地方。
Readler 的书是纯语法，单独读容易变成「看懂了但写不出来」。

## 工具链：两套都用

| | 开源工具链（`oss-cad-suite`） | 厂商 IDE（Gowin EDA） |
|---|---|---|
| 内容 | yosys + nextpnr-himbaechel + iverilog/verilator + openFPGALoader | 官方综合、时序约束、IP 核生成器、在线逻辑分析仪 |
| 优点 | 命令行、可复现、可 git 管理；和 Gisselquist 的课无缝对接 | 官方支持，功能全，Sipeed 的教程都基于它 |
| 缺点 | Gowin 器件支持靠 apicula 项目，新器件滞后；没有厂商级时序分析 | 图形界面不可脚本化；教育版要申请 license |

**建议**：学习阶段以开源工具链为主（配合 Gisselquist 的课），上板遇到问题时用 Gowin IDE 交叉验证。
两套都装，不要二选一。

## 阶段划分

### 阶段 0：环境打通（不写代码）

**做什么**：把流程跑通，点亮第一个 LED
**资源**：Sipeed Wiki 的[点灯 LED 例程](https://wiki.sipeed.com/hardware/zh/tang/Tang-Nano-9K/examples/LED.html)

**验收**：不看教程，自己新建工程 → 写代码 → 综合 → 约束 → 布局布线 → 烧录，LED 按你的意图亮

**三个已知的坑**（都会直接卡住你）：
- 器件型号要选 `GW1NR-UV9QN88C6/I5`。datasheet 上写的是 `LV9QN88PC6`，Gowin IDE 里的名字不一样
- 要在 Place & Route 里勾上 `Use DONE as regular IO`，否则综合报 error2017
- 板载晶振 27 MHz，LED 是**低电平点亮**

### 阶段 1：组合逻辑与时序逻辑

**资源**：Gisselquist L01（wires）、L02（registers & blinky）；Readler 第 2、3 章

**做什么**：`wire` / `assign`、`always @(posedge clk)`、同步与异步复位、分频

**验收**（不看答案，用仿真波形证明）：
1. 写一个 4 位二进制计数器，能从 0 数到 15 再回 0
2. 写一个 27 MHz 到 1 Hz 的分频器，让 LED 一秒一闪
3. 口头解释清楚：为什么 `reg` 不等于「寄存器」，`always @(*)` 和 `always @(posedge clk)` 到底差在哪

### 阶段 2：状态机与模块化

**资源**：Gisselquist L03（FSM）；Readler 第 4、5 章

**验收**：
1. 用状态机实现「按一下按钮，LED 走马灯换一格」
2. 把走马灯拆成 `clk_div` + `fsm` + `led_driver` 三个模块，顶层只做例化
3. 画出状态转移图，标出每个状态的进入条件和输出

### 阶段 3：按键、存储与通信

**资源**：Gisselquist L07（按键消抖）、L08（Block RAM）、L05 / L06 / L09 / L10（UART 收发 + FIFO）

**验收**：
1. **按键消抖**：按一次只触发一次。用仿真证明你的消抖逻辑真的消除了抖动
2. **串口发送**：板上的数据发到电脑，串口助手收到正确内容
3. **串口接收 + FIFO**：电脑发一串数据，板上收下、存进 FIFO、再原样发回来

### 阶段 4：RV32I（回到原目标）

**资源**：没有现成课程，靠自己。规格见 [SPEC.md](SPEC.md)
**前提**：阶段 0 到 3 全部通过

## 关于仿真：从一开始就用

Gisselquist 的课用 Verilator，还教 SymbiYosys 形式验证。**不要跳过仿真直接上板。**

理由很实际：上板调试只能靠 LED 和串口，一次改动要等几十秒综合布线。
仿真里你可以在任意时刻看任意信号的波形，改一行跑一次只要一秒。
前三个阶段的验收全部要求「用仿真波形证明」，就是为了把这个习惯立起来。

## 怎么用这份路线

1. **按阶段推进，不要按周推进。** 一个阶段的验收没过，不进下一个阶段
2. **每个阶段结束时找 AI 出题检验。** 你的已知问题是容易把「学过」当成「掌握了」，
   所以验收必须由别人出题，不能自己说了算
3. **卡住超过 30 分钟就看示例代码。** 不要硬扛，那是浪费时间
4. **时间投入等你填了 `ai-profile/profile/personal.md` 再排。** 现在那份文件里
   「一次能专注多久」「精力最好的时段」都是空的，凭猜排出来的计划没有意义

## 参考文件

- 书放在 `docs/Verilog-by-Example_Readler-2011.pdf`（6 MB，已加进 `.gitignore`，不进 git）
- 这份文档对应的项目规格见 [SPEC.md](SPEC.md)
- 变更史见 [LOG.md](LOG.md)
