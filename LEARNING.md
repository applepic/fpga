---
status: 进行中
last_updated: 2026-10-18
---

# FPGA 学习路线（压缩版）

> 目标：从零学会用 Verilog 做 FPGA 设计，最终能独立实现 RV32I 处理器核。
> 板子：**Tang Nano 9K**（GW1NR-LV9QN88PC6/I5，8640 个 LUT4，27 MHz 板载晶振）
>
> **2026-10-18 改版**：原版四个阶段里有一步（FIFO）挡在 RV32I 前面，
> 而它对 RV32I 不是必需的。改版把它挪到 RV32I 之后。理由见文末「为什么改了顺序」。

## 三个阶段

| 阶段 | 内容 | 验收 |
|---|---|---|
| **A. 能写时序逻辑** | `wire`/`assign`、`always @(posedge clk)`、复位、分频、计数器、状态机 | 计数器 + 分频器 + 按键走马灯，全部有仿真波形 |
| **B. 能跟外界说话** | UART 发送、UART 接收、按键消抖 | 板子发字符串到电脑；电脑发字符板子收到并显示 |
| **C. RV32I** | 单周期处理器核，见 [SPEC.md](SPEC.md) | 跑通 37 条指令的测试程序，UART 输出结果与仿真一致 |

**每一阶段的验收都必须由别人出题检验。** 你的已知问题是容易把「学过」当成「掌握了」，
所以验收不能自己说了算。做完一阶段跟我说，我出题。

## 环境：怎么跑

所有命令在仓库根目录（`C:\Local_Data\Dev\fpga`）执行。

```powershell
. .\env.ps1                                          # 必须带前面的点
.\scripts\sim.ps1   -Project examples/blinky         # 仿真
.\scripts\build.ps1 -Project examples/blinky         # 综合 + 布局布线 + 生成 .fs
.\scripts\flash.ps1 -Project examples/blinky         # 烧到 SRAM（掉电丢）
.\scripts\flash.ps1 -Project examples/blinky -Flash  # 烧到 Flash（掉电保留）
```

**`env.ps1` 前面那个点不能省。** 不 dot-source 的话 PATH 只在子进程里有效，
下一条命令又找不到工具。这是 PowerShell 的规则，不是我们的约定。

### 目录约定

```
fpga/
├── env.ps1                    工具链环境
├── constraints/tangnano9k.cst 整块板子的引脚（所有项目共用）
├── scripts/                   build / sim / flash
├── infra/toolchain_smoke/     工具链自检，不是学习材料
├── examples/                  学习过程中的练习
│   └── NN_名字/
│       ├── rtl/*.v            设计
│       ├── sim/tb_*.v         testbench
│       └── build/             产物（不进 git）
└── rv32i/                     阶段 C
```

一个练习 = 一个目录。`rtl/` 放设计，`sim/` 放 testbench，`build/` 自动生成且被 `.gitignore` 忽略。

### 三个工具链的坑（都踩过，已修进脚本）

1. **只把 `bin\` 加进 PATH 会崩。** yosys / nextpnr / openFPGALoader 依赖同目录
   `lib\` 下的 DLL，缺了它们退出码是 `-1073741515`（0xC0000135），**没有任何错误信息**。
   iverilog 恰好不依赖，所以它会正常跑，把人误导成「工具链没问题」。`env.ps1` 已经把 `lib\` 加上了。
2. **`--cst` 不是 nextpnr 的参数。** 约束要写成 `--vopt cst=xxx.cst`，
   而且 GW1N-9 必须再加 `--vopt family=GW1N-9C`，否则报
   `For the GW1N-9 series you need to specify --vopt family=`。
3. **`--report` 写出的是 JSON，不是文本报告。** 想读 Fmax 和资源占用得 `ConvertFrom-Json`。

## 资源：三份，分工不同

| 资源 | 定位 | 怎么用 |
|---|---|---|
| [Gisselquist 的 10 课](https://zipcpu.com/tutorial/) | **主线** | 按顺序做，每课有可下载示例 |
| Readler《Verilog by Example》（114 页） | **语法速查** | 卡住时查对应章节，**不要从头读到尾** |
| [Sipeed Wiki](https://wiki.sipeed.com/hardware/zh/tang/Tang-Nano-9K/Nano-9K.html) | **板子相关** | 只在需要碰硬件时查 |

为什么这么分：Gisselquist 把「语言 + 工具 + 调试」绑在一起教，这正是自学者最容易断的地方。
Readler 是纯语法，单独读容易变成「看懂了但写不出来」。

## 阶段 A：能写时序逻辑

**做什么**：把「代码怎么变成电路」这件事搞明白。

**资源**：Gisselquist L01（wires）、L02（registers & blinky）、L03（FSM）；Readler 第 2、3、4 章

**验收**（全部要仿真波形）：
1. 4 位二进制计数器，从 0 数到 15 再回 0
2. 27 MHz 到 1 Hz 的分频器，让 LED 一秒一闪
3. 按键控制走马灯：按一下换一格，且**按一次只动一格**（这个先不做消抖，阶段 B 再补）
4. 口头解释：为什么 `reg` 不等于「寄存器」，`always @(*)` 和 `always @(posedge clk)` 差在哪

**一个具体的坑**：仿真里 27 MHz 到 1 Hz 要跑 2700 万个时钟周期，
波形文件会大到打不开。**仿真时把分频系数改小**（比如 27），上板前改回真实值。
这是行业常规做法，不是作弊。

## 阶段 B：能跟外界说话

**做什么**：让板子和电脑交换数据。

**资源**：Gisselquist L05 / L06 / L09（UART 收发）、L07（按键消抖）

**验收**：
1. **串口发送**：板子每 0.5 秒发一次 `hello`，电脑串口助手收到
2. **串口接收**：电脑发一个字符，板子收到后把它的 ASCII 码用 6 个 LED 显示出来
3. **按键消抖**：用仿真证明，机械抖动（模拟成一串快速跳变）只触发一次

**串口参数固定成 115200 8N1**，后面 RV32I 要靠它输出结果，先把它调稳。

**接线**：板载 BL702 已经引出了 USB-UART，`uart_tx` = 引脚 17，`uart_rx` = 引脚 18。
插上 USB 线，电脑上会出现一个 COM 口（设备管理器里看）。

## 阶段 C：RV32I

规格见 [SPEC.md](SPEC.md)。前提是 A、B 全部通过。

## 为什么改了顺序（2026-10-18）

原版阶段 3 是「按键 + Block RAM + UART + FIFO」，要求 FIFO 跑通才进 RV32I。
问题在于：**RV32I 的第一版不需要 FIFO。**

- 单周期 RV32I 的指令存储器和数据存储器是**组合读的**（`assign dout = mem[addr]`），
  用 `reg [31:0] mem[0:255]` 数组就够了，综合工具会把它塞进 BSRAM，不需要你手写 FIFO
- UART 是单向输出（把结果打出来），也不需要 FIFO
- FIFO 真正用得上是在「UART 收发都要缓存」或者「做流水线要指令队列」的时候，那是第二轮的事

**所以 FIFO 从「前置条件」降级成「阶段 C 之后的选做」。** 这不是降低标准，
是把挡在目标前面、而目标又不需要的那一步挪开。

Block RAM 同理：你会在阶段 C 自然地用到它（指令存储器），到时候再学，
比现在凭空学一个「存储块」有动机得多。

## 关于仿真：从一开始就用

Gisselquist 的课用 Verilator，还教 SymbiYosys 形式验证。**不要跳过仿真直接上板。**

理由很实际：上板调试只能靠 LED 和串口，一次改动要等几十秒综合布线。
仿真里你可以在任意时刻看任意信号的波形，改一行跑一次只要一秒。
阶段 A 和 B 的验收全部要求「用仿真波形证明」，就是为了把这个习惯立起来。

**本仓库统一用 iverilog**（比 Verilator 好上手，Gisselquist 的 Verilator 用法可以不管）。
Verilator 也装了，但它的 perl 包装脚本在 Windows 上跑不起来，直接用 `verilator_bin.exe` 才行。
需要更快的时候再说。

## 怎么用这份路线

1. **按阶段推进，不要按周推进。** 一个阶段的验收没过，不进下一个阶段
2. **每个阶段结束时找我出题检验。** 不能自己说了算
3. **卡住超过 30 分钟就看示例代码。** 不要硬扛，那是浪费时间
4. 时间投入按 `ai-profile/profile/personal.md` 的实测值排：**一天 2 到 3 块，每块 2.5 到 3 小时**

## 参考文件

- 书：`docs/Verilog-by-Example_Readler-2011.pdf`（6 MB，不进 git）
- 项目规格：[SPEC.md](SPEC.md)
- 变更史：[LOG.md](LOG.md)
