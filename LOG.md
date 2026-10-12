# 开发变更史

> 格式：`日期 | hash | 动作 | 涉及文件 | 理由`
> hash = `MD5(日期 + 动作)` 的前 8 位
> 本文件记录**开发变更**，永不自动清理。仿真波形、综合报告等构建产物不写在这里。

| 日期 | hash | 动作 | 涉及文件 | 理由 |
|---|---|---|---|---|
| 2026-05-18 | `9fe373c` | `init` | `README.md` | 建仓库。见 git commit `9fe373c` |
| 2026-10-12 | `4aff2e34` | 建立项目文档骨架 | `AGENTS.md`、`SPEC.md`、`LOG.md`、`LOG-INDEX.md`、`README.md` | 项目尚未开始，先把约定和规划落下来，避免开工时从零摸索 |
| 2026-10-12 | `9bcacf23` | 确认目标板，新增学习路线 | `LEARNING.md`（新建）、`SPEC.md`、`README.md`、`AGENTS.md`、`.gitignore` | 用户确认板子为 Tang Nano 9K 并说明要从头学 FPGA。项目定位从「直接做 RV32I」改为「先学完阶段 0 到 3 再做 RV32I」 |

## 关于 2026-05-18 那条

那次的 hash 没有按规则记录（约定是后来才建立的），这里用 git commit 短 hash 代替。
