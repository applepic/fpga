# 开发变更史

> 格式：`日期 | hash | 动作 | 涉及文件 | 理由`
> hash = `MD5(日期 + 动作)` 的前 8 位
> 本文件记录**开发变更**，永不自动清理。仿真波形、综合报告等构建产物不写在这里。

| 日期 | hash | 动作 | 涉及文件 | 理由 |
|---|---|---|---|---|
| 2026-05-18 | `9fe373c` | `init` | `README.md` | 建仓库。见 git commit `9fe373c` |
| 2026-10-12 | `4aff2e34` | 建立项目文档骨架 | `AGENTS.md`、`SPEC.md`、`LOG.md`、`LOG-INDEX.md`、`README.md` | 项目尚未开始，先把约定和规划落下来，避免开工时从零摸索 |
| 2026-10-12 | `9bcacf23` | 确认目标板，新增学习路线 | `LEARNING.md`（新建）、`SPEC.md`、`README.md`、`AGENTS.md`、`.gitignore` | 用户确认板子为 Tang Nano 9K 并说明要从头学 FPGA。项目定位从「直接做 RV32I」改为「先学完阶段 0 到 3 再做 RV32I」 |
| 2026-10-18 | `4ce23a96` | 打通工具链并重建学习骨架 | `env.ps1`（新建）、`scripts/build.ps1`、`scripts/sim.ps1`、`scripts/flash.ps1`（新建）、`constraints/tangnano9k.cst`（新建）、`infra/toolchain_smoke/`（新建）、`README.md`、`AGENTS.md`、`.gitignore` | 原来只有文档，没有任何能跑的脚本，`rv32i/` 是空目录。实测发现三个坑：①只把 `bin\` 加进 PATH 时 yosys/nextpnr/openFPGALoader 全部崩溃，退出码 `-1073741515` 且无任何错误信息（缺 `lib\` 下的 DLL），而 iverilog 恰好不受影响，极易误判；②nextpnr 没有 `--cst` 参数，要用 `--vopt cst=` 且 GW1N-9 必须加 `--vopt family=GW1N-9C`；③`--report` 写出的是 JSON 不是文本。三个坑都修进脚本，并用 `infra/toolchain_smoke` 端到端验证：仿真 PASS、综合布线打包全部 exit 0、产出 2,070,048 字节的 `top.fs`。引脚来源核对了 Sipeed 官方例程、Apicula 与 Lushay Labs 三处，出处写在 `.cst` 文件头 |
| 2026-10-18 | `5562b49e` | 学习路线压缩为 A/B/C 三阶段，FIFO 从 RV32I 前置条件降级为选做 | `LEARNING.md`（重写）、`SPEC.md` | 原路线四个阶段里，阶段 3 要求「串口收发 + FIFO 跑通」才能进 RV32I。核对后确认单周期 RV32I 用不到手写 FIFO：指令/数据存储器用 `reg` 数组综合进 BSRAM 即可，UART 第一版是单向输出也不需要 FIFO。把不构成前置条件的一步挡在目标前面，只会拖慢而不提高标准。FIFO 移到阶段 C 之后的选做。同时把「阶段 0 环境打通」并入 A（工具链已经由 `infra/toolchain_smoke` 客观验证，不需要再靠「不看教程独立走一遍」来证明）。SPEC 的开放问题因此定掉三条：单周期、iverilog、不用 riscv-tests（本机无 RISC-V 交叉编译器，手写 37 条指令的机器码本身就是理解编码的过程） |
| 2026-10-18 | `be8d7608` | 新建练习 01_counter（只有 testbench 与 README，实现留空） | `examples/01_counter/sim/tb_counter.v`、`examples/01_counter/README.md` | 给学习阶段一个能立刻开始的入口。testbench 当验收标准写死，`rtl/counter.v` 故意不存在，用户跑起来先看到编译错误。testbench 本身做过反向验证：正确实现（同步复位、异步复位两种）全部 PASS；三种错误实现都能抓到（忽略 `rst_n` 报 `q=x`、数到 9 就回 0 在第 10 拍报错、输出恒为 0 在第 1 拍报错） |
| 2026-10-18 | `acee70b2` | 新建 lessons/ 逐步课程与第 1 课，00_gates 练习 | `lessons/README.md`、`lessons/01_verilog_basics.md`（新建）、`examples/00_gates/sim/tb_gates.v`、`examples/00_gates/README.md`（新建） | 用户明确要求「教我，一步步学过去」，不要 AI 代写。原来的 `examples/01_counter` 直接丢一个计数器给人做，中间缺了组合逻辑、`wire`/`assign`、位运算、仿真机制这几层，等于跳步。新增 `lessons/` 作为课程层：路线（`LEARNING.md`）说「阶段 A 要会时序逻辑」，课程说「第 1 课讲 `assign`，第 2 课讲 `always`」。第 1 课从最简单的门电路切入，目的是让人亲眼看见「Verilog 描述电路结构而非执行顺序」，这是后面理解 `always @(posedge clk)` 的地基。`examples/01_counter` 降级为第 3 课，编号保留不动，避免改已有的 testbench 引用 |
| 2026-10-18 | `3b190498` | 全仓库文档改为英文 | `AGENTS.md`、`README.md`、`LEARNING.md`、`SPEC.md`、`lessons/README.md`、`lessons/01_verilog_basics.md`、`examples/00_gates/README.md`、`examples/01_counter/README.md` | 用户问「英文规范去哪里了」。查证：`ai-profile/profile/language.md` 的项目级覆盖表在 2026-10-12 15:46（`4bac95b`）写入了 `fpga / 中文`，而 `AGENTS.md` #1 在当天 12:00（`f395056`）已写「用中文回复」，两条互相加固，且项目级覆盖优先级最高，压过了 language.md 本表「默认中文、技术语境英文优先、正在过渡到英文」的总规则。用户 2026-10-18 确认改为「技术内容全英文，仅生活/规划类问题用中文」。已同步改 `language.md` 的覆盖表并加注成因。教训写进 language.md：项目级覆盖表写进去就是长期生效，加行必须先问用户 |

## 关于 2026-05-18 那条

那次的 hash 没有按规则记录（约定是后来才建立的），这里用 git commit 短 hash 代替。
