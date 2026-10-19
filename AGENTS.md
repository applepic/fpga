# AGENTS.md — AI 开工须知

> 每次会话开始时自动注入（等价于 `CLAUDE.md`）。
> 适用范围：**本项目从零开始的 RTL 开发**。

## #1 语言
- 用**中文**回复。
- 代码、命令、路径、信号名、错误码保持原文，不要翻译。

## #2 先读文档，再动手
- 不知道这是什么项目？→ 先读 [README.md](README.md)。
- **不知道从哪开始？→ 读 [LEARNING.md](LEARNING.md)。当前是学习阶段，不是开发阶段。**
- 要做架构判断？→ 看 [SPEC.md](SPEC.md) 的边界与「开放问题」。
- 需要变更历史？→ 扫 [LOG-INDEX.md](LOG-INDEX.md)，按行号跳进 [LOG.md](LOG.md)。

## #3 改前必须确认

**项目处于学习阶段。用户要从零学 FPGA，`LEARNING.md` 的阶段 A、B 还没完成。**
以下操作必须先停下来说明并等用户确认：

- 跳过 `LEARNING.md` 的阶段，直接开始写 RV32I
- 改动 `SPEC.md` 里「明确不做」的范围（加扩展指令、加缓存、加流水线）
- 引入新的工具链依赖（换仿真器、换综合工具、引入第三方 IP）
- 提交大段生成的 RTL。AI 生成的硬件代码必须逐段解释清楚再提交

**可以直接做**：读文件、跑仿真、写文档、写测试程序、调试已有代码、**出题检验用户**。

## #4 必须记变更
- 每次**有效改动**后，更新 [LOG.md](LOG.md) 与 [LOG-INDEX.md](LOG-INDEX.md)。
- LOG 格式：日期 + hash + 动作 + 涉及文件 + 理由。hash = `MD5(日期 + 动作)` 前 8 位。
- 目的：下一个 AI / 下一次会话能一眼看懂演进过程，不用从零重新摸索。

## #5 验证要动真格
- 不要用「看起来应该对了」下结论。**每个改动都要有仿真输出或波形证据。**
- 验收标准是三层：单元仿真 → 指令级仿真 → 上板实测。见 `SPEC.md` 的「验证策略」。
- 上板结果和仿真不一致时，先怀疑约束文件（引脚、时钟），再怀疑 RTL。

## #6 禁止行为
- **不要在阶段 A、B 完成前直接给 RV32I 的答案。** 用户要的是学会，不是拿到成品。
  他卡住时给思路和定位方法，不要直接把完整代码贴上去
- **不要替用户写 `examples/` 下的练习实现。** 那里只有 testbench（验收标准）和 README，
  `rtl/` 空着是**故意的**。他卡住时给提示，不给代码
- **不要扩大范围。** 第一版只做 RV32I 基础指令，不加 M / A / F / D 扩展、不加缓存、不加特权态。
  范围一放开，这个项目永远做不完
- **不要在没有仿真证据的情况下说「完成了」。**
- **不要建议用户休息、改天再做、或重新考虑要不要做。** 直接把活干完。

## #7 关键路径速查

| 东西 | 路径 |
|---|---|
| 工具链 | `C:\Local_Data\oss-cad-suite\bin\`（**`lib\` 也要进 PATH**，见 `env.ps1`） |
| 环境脚本 | `env.ps1`（必须 dot-source：`. .\env.ps1`） |
| 构建 / 仿真 / 烧录 | `scripts\build.ps1` / `sim.ps1` / `flash.ps1` |
| 板级引脚约束 | `constraints\tangnano9k.cst`（所有项目共用） |
| 工具链自检 | `infra\toolchain_smoke` |
| 仿真器 | `iverilog.exe` / `vvp`（Verilator 只有 `verilator_bin.exe` 可用，perl 包装脚本坏了） |
| 综合 | `yosys` |
| 布局布线 | `nextpnr-himbaechel.exe`（**`--vopt cst=` + `--vopt family=GW1N-9C`**，没有 `--cst`） |
| 烧录 | `openFPGALoader.exe -b tangnano9k` |
| 厂商 IDE 配置 | `C:\Users\str\.gowinsemi` |
| 参考书 | `C:\Local_Data\Dev\fpga\docs\Verilog-by-Example_Readler-2011.pdf` |
| 仓库远端 | `https://github.com/applepic/fpga.git` |

> **改脚本前先读 `LEARNING.md` 的「三个工具链的坑」。** 那三条都是 2026-10-18 实际踩出来的，
> 其中第一条（缺 `lib\` 导致 `-1073741515`）没有任何错误信息，很容易被误判成别的问题。

## #8 日志文件区分
- 仿真波形、综合报告、时序报告 → 构建产物，随时可重新生成，**不进 git**。
- `LOG.md` / `LOG-INDEX.md` → **开发变更史**（改了什么、为什么），永不自动清理。
- 两者不要混用。
