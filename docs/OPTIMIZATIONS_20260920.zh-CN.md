# 0.2.0：矩阵约化优化与域内缺口撒点

本版本把 2026-09-20 工作副本中的优化及经过三圈检验的策略纳入 package。默认策略的组合仍需逐任务验证；不宣称四圈已闭合。

## 实现优化

- 按积分原子提取、整理有理系数，避免将不同积分项合成巨大公分母；系数矩阵每行只展开一次，Exact 消元仍使用原矩阵语义。
- FiniteFlow 稀疏输出避免重复展开辅助规则；记录 canonicalization、列排序、求解、残差和幂等检查耗时。
- `ReduceTargetIntegrals` 用依赖选择缩小原始方程行，保留行索引和证书；两素数采样与精确残差/幂等检查认证所选行空间。FiniteFlow 选择路径另以完整池目标求解验证正常形相同。Python 选择路径的证书只认证所选子系统，返回值明确标记范围。
- 相同关系池、列序、求解器与限制参数下复用已验证约化；条件改变使缓存失效。采样缓存与约化缓存分开。
- 预编译普通 IBP shifts；contact 项仍独立保留。每个邻域只生成一次，再按 degree 分配给算符。
- 已完成应用哈希查询；slot permutation 和 block symmetry 轨道缓存；批量合并 worker 缓存；checkpoint 保存指纹并拒绝跨实现恢复。

## 默认策略和可选策略

`RunDE` / `RunReduction` 默认 `SeedDomain -> "Original"`、`GapSeeding -> True`、`GenerationPolicy -> "OnDemand"`、`ReductionScope -> "Targets"`。OnDemand 的跳过生成逻辑适用于 DE；普通约化仍生成关系直到固定点。

初始系统用域内实际 seeds；已有池出现未覆盖 targets 或有限覆盖失败时，优先对缺口的所有域内 symmetry 图像撒点，不限于 factorized 积分。局部无新增行再扩大到当前查询和关系邻域，实际 seeds 仍在原始域。有限组合 seeds 同样执行域内过滤。每次扩充后从原输入重放。

- `SeedDomain -> "Extended"`：显式允许声明的 completion/supersector seeds；不会自动放宽 family 的其他条件。
- `GapSeeding -> False`：生成时使用广泛中心，供消融对照。
- `BlockExpansion -> "SingleBlock"`：独立分块逐个移动，减少笛卡尔积；默认保留 `"Cartesian"`，因为新组合策略尚未普遍认证。
- 直接 `GenerateSeeds` / `GenerateSystem` 支持 `SeedCenters -> "Raw" | "Representative" | "AllOriginalImages"`。找不到域内图像的目标会记录，不伪造代表元。
- family 的 `IntegralOrdering -> "LadderFirst"` 优先选择域内自由代表元；`"Legacy"` 保留旧 ordering。ordering 进入 family 指纹。

`GenerationHistory` 保存每次生成的候选缺口、实际中心策略、域内审计、拒绝应用、工作量及是否扩大搜索。候选缺口不等于证明可约化；只有得到合法精确关系才能确认。反复增长也不是不可闭合的数学证明。

## 三圈策略测评（发布前的冻结实验）

| 对照 | 结果 |
|---|---|
| 完整 supersector 池，旧 ordering | 76,198 应用、27,938 行；三圈 26 分量，完整 37 维 |
| 同池 ladder 优先 ordering | 三圈 25 分量，完整 36 维 |
| 固定 15,362 行域内池，不补点 | 4→15→26→29→40→64→112，未闭合 |
| 三个缺口补域内 symmetry 图像 | 新增 3,535 应用、912 条不同生成行；4→15→25→25，完整 36 维 |
| 相同 ordering 下域内修补 vs supersector | 基底、完整 DE 和 Top 坐标逐项相同 |
| 同池相同缺口，域内 vs extended | 新增应用 3,535 vs 6,373，域内少 44.53% |
| 独立 block 逐个移动的冷启动试点 | 50,008 应用、20,080 行；应用减少 34.37%，完整 36 维且与基线满足精确连接变换；仍保留 supersector |
| 全 targets 代表元中心 vs 原 targets 中心 | 双方一次扩充、累计八次导数轮次；50,635 vs 50,627 应用；未显示代表元中心减少轮次 |

以上方程数不是秩；有限基底分量包括常系数组合，不能直接当作整个 family 最小 MI 数。针对三个已发现缺口的修补不等于盲冷启动优势。单次测时受共享负载影响，尤其第一组 333/345 秒修补对照存在旧进程竞争，不作为可靠加速比。

第二轮 12→15 的审计中，加回全部 174 条原独立规则未改变实际目标正常形；没有发现目标选行删除必要 IBP 的证据。三个 factorized 缺口的两圈因子可由自身 sector 及子 sectors 降圈，不需要两圈 topsector magic relation。67 个两圈查询在 proper-sector/含 topsector 测试池下正常形相同，但双方仍有一个未覆盖查询。

Gram 的三圈试点新增独立行却没有改善实际目标；四圈试点也没有改善查询。`Extensions/GramCandidates.wl` 仅提供严格四维候补，未自动接入 campaign。

## 四圈使用边界

默认自动补点依据当前池的未覆盖 targets 和有限覆盖失败，不读取参考 DE。对持续出现但已有覆盖的新增方向，还应检查实际低圈分块、指数增长和固定查询的导数跨度缺口，再决定扩大 seeds 或添加其他关系。该更全面的诊断调度尚不是本版本已经实现的自动证明器。

新旧源码不能复用旧 checkpoint 的应用记录；使用新的输出目录。冻结生产计算不随 package 文件更新而迁移。运行方式与选项见 README；发布时的测试摘要另存于 `VALIDATION_0.2.0.json`。
