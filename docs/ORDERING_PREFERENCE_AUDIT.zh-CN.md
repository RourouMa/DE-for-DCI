# ordering 与约化后选基的审计（2026-09-23）

检查实际运行脚本及保存的 `FiniteBasis.wl`、`ReducedBasis`、`ReducedInput.wl` 和 `ReducedDE.wl`，发现部分历史计算在按 ordering 消元之后，又从原查询中选择已被消去的单独有限积分。实现是 `PreserveActualSpan`，并非只在当前剩余发散原子中构造有限组合。

| 保存结果 | 有限基元素 | 原始正规形支撑 | 重新引入的单积分 |
|---|---:|---:|---:|
| tennis O3，E2 R5 | 42 | 71 | 19 |
| tennis O6，旧 E6 R2 | 24 | 44 | 7 |
| ladder O5＋PreserveActualSpan，闭合轮候选 | 19 | 24 | 3 |
| ladder O6＋PreserveActualSpan，闭合轮候选 | 19 | 21 | 2 |
| 早期 ladder-priority，闭合轮 | 25＝18 单积分＋7 常系数组合 | 32 | 0 |

闭合时最终 DE 使用该轮的输入基；保存的 `FiniteBasis.wl` 是该轮覆盖候选，两者可有个别代表不同。反推 ordering 必须以最终 `DifferentialEquations.wl` 的 `Basis` 为准。

计数依据：所选 `G` 不在本轮约化后原子支撑中，而其保存的正规形包含多个原子。数值不是按选基函数是否被加载推测的。另有 fresh O6 control 没有保存有限基结果，不应当拿其他 O6 分支的数据代替。

这些事实不自动否定精确覆盖、闭合或曲率证书；它们否定了“只改变 ordering 就得到这些优先主积分”的归因。已验证的 ladder19 仍保留为有效成果：19 个都是单独有限积分，两套版本均含原始 top，位于第 3 项。两套基各有 2 个 factorized、17 个 connected 元素，最大分母幂 3，最大总分子次数 1。

原始 top 是：

```wl
G[1,1,0,1,0,1,0,1,0,1,1,1,1,1,0,1,1,1]
```

用户后续明确安排：保留现有 O7＋自适应有限覆盖计算；另开严格 O7 对照；分析 ladder19 能对应怎样的新 ordering。三者应分开记录。严格 O7 从同一原始 top、同一 E2 方程池复用已验证约化，禁止悄然引入被消去的积分。方程池扩充后仍须补齐相同 supersector 的 symmetry 并从 top 重放。

对 ladder19 反推 ordering 时，首先将已认证独立的 19 个积分显式放到列序末端，检验完整方程池是否直接保留它们、DE 是否只落在这 19 个同圈代表及保留的低圈源上。这是已知基集合的对照键，不是已经发现可推广的拓扑排序规则。之后再分析能否用有限性、结构、复杂度以及原始 top 的微分可达空间描述这种偏好。

本地可复查审计脚本：`ladder-validation-20260920/ordering-basis-audit-20260923/audit.py`，明细 `Result.json`。冻结实验保留原文件，不覆写历史结果。

已完成的 O8“梯子十九”对照：对最终 DE 的19元基设置最高保留优先级，在原公共池63989条非零方程、51457列上进行单个 generic 点 FiniteFlow 约化，全部19元保持自身，DE 同圈支撑恰为19，无基外项。这是数值对照；不等于对所有 family 推广了该排序。
