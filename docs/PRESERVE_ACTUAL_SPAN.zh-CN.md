# 原空间选基：PreserveActualSpan（0.4.0）

目标是在完整 DE 闭合的前提下，让有限基尽可能简单。这里的“原空间”是当前输入和微分表达式经已验证 IBP 约化后实际张成的有理函数空间，不是这些表达式中所有积分原子分别张成的空间。低圈源项始终保留，最高圈空间的计算仅取模低圈源项；取商不等于删除源项。

## 与 ordering 的关系

`StrictOrdering` 仍是默认有限覆盖策略：保留给定 ordering 的单独有限不可约原子，只对剩余发散支持构造有限组合。

`PreserveActualSpan` 是显式选择的另一种策略：ordering 用于 IBP 消元，有限基可以选择已经约化掉的简单积分，但其已验证正规形必须属于实际空间，所选基必须独立且完整覆盖该空间。因此它不能被报告为“严格遵循 ordering 的不可约积分”。ordering 和有限选基策略必须分别记载。

```wolfram
InitializeFiniteFlow[finiteFlowDirectory, mathlinkDirectory];
FiniteFlow`FFNThreads = 24;
result = RunDE[family, input,
  "Solver" -> "FiniteFlow", "FiniteBasisPolicy" -> "PreserveActualSpan",
  "SeedGeometry" -> "InverseTargets", "InverseOperatorPolicy" -> "Complete",
  "SeedDomain" -> "Extended", "Workers" -> 24,
  "VerificationWorkers" -> 24];
```

`Extended` 只适用于事先声明并论证的 supersector。上面的配置不指定 O7；生产实验的 O7 是独立冻结的 tennis-court 文件排序，不能把任何 family 的默认排序称作 O7。

## 接受一个有限覆盖的条件

1. 完整物理表达式有限；发散原子必须随整个组合处理。
2. 使用已验证约化给出候选积分的正规形，不把未知积分当成自由的已知候选。
3. 候选正规形属于实际有理空间，候选数等于实际秩。
4. 重构全部输入与 DE 的坐标，符号检查覆盖残差；完整保留低圈余项。
5. 对所有候选作复杂度判断，不局限于用户举出的例子。联合升幂一阶常见，二阶结合拓扑判断，三阶及以上触发针对性关系审查，不直接宣判可约。
6. 只有上述条件满足后才求导下一轮。扩充方程池后保留旧池，并从原 top 重放。

优先简单单积分，再考虑少项常系数组合。变量系数组合是有证据的后备选择：先记录常系数搜索范围、遗漏关系审查、候选复杂度与实际收益。不能将一次二项差搜索失败描述成“常系数组合不存在”。

0.4.0 的通用 `BuildSpanPreservingFiniteBasis` 使用 FiniteFlow 计算空间和坐标，候选包括已验证的查询单积分、已输入的常系数整组合以及默认有限覆盖的候选。它是有界候选构造器，不自动穷举高项组合或采用变量系数。候选不足时返回 `SpanFiniteCoverIncomplete`，保留此前已验证状态。生产实验中更大的候选搜索、定向补关系和人工记录的后备决策不应冒充此接口已有的自动能力。

## Tennis court 实验的当前证据边界

2026-09-23 的 O7 自适应实验曾在 332672 行关系池中得到最高圈秩序列 `3,14,25,31,31,31`，31 个基的 62 行导数有理重构通过同池比较，齐次曲率 961 项为零；原 top 保留，未导入参考 MI 或参考 DE。**这些是旧池中的代数结果，现不接受为物理闭合证书。**

接入横纵低圈后，完整 47 维曲率出现 125 个非零项，联合池甚至将非零一圈 box 消成零。已保存 311 行关系的精确矛盾证书。暂时隔离产生发散二圈接触源的 30536 行关系后，box 不再被消为零，31 个三圈输入的微分仍覆盖；候选 46 维系统的 2116 项完整曲率精确为零。当时历史生成器与实际使用关系的有效性尚未复核，因此该隔离实验不作为验收证书。

后续完整重生成复核已完成：修正 package 从 seed/operator 记录重新生成所有关系，在新联合池中重构全部高低圈 DE，得到 31+11+4 的完整 tennis 系统；有限性、原 top、全部导数覆盖、单点全池核对和精确完整曲率均通过。ladder 的 19+7+4 系统也重新通过，矩阵与旧结果完全一致。采用的基仍是原空间选基分支所得候选，没有使用用户的参考 MI；详见[新验收工件](../reproduction/corrected-three-loop-20260923/README.zh-CN.md)。这次确认的是完整 DE，并不将旧无效池上的轮次历史改写为已验证历史。

这说明：完整池残差只证明重构遵循所给方程；它不能证明方程本身正确。齐次曲率为零也不能替代含低圈源项的物理一致性。迁移选基策略时必须独立验证生成器与接触结构。详细记录见 [接触源有效性](CONTACT_SOURCE_VALIDITY.zh-CN.md)。

工作区审计工件位于 `tennis-o7-expanded-pool-replay-20260923/`：`CertifiedContradictionSubset.wl`、`ContactAblationCurvature.wl`、`WitnessGenerators-*.wl`。此前矩阵保存在[暂停接受的历史工件](../reproduction/tennis-o7-adaptive31/README.zh-CN.md)，不作为通过验收的 benchmark。

## 横向与纵向的低圈闭合

Tennis court 的真实子拓扑同时包含横向、纵向 ladder。每次接入低圈时，逐项记录被收缩环、剩余环与外点映射，再生成对应 family 与 supersector；factorized symmetry 在同一声明域中寻找。不能任取两个环组成 ladder，也不能只复用横向表。

本实验复用了 12 个二圈与 4 个一圈积分的横纵联合系统。纵向由外点循环置换及 `x ↔ y` 构造，导数矩阵同时交换 `Mx ↔ My`，并验证 Gram 映射和连接变换。

必须针对当前三圈的**整行源项**复核覆盖。旧低圈 DE 闭合不意味着它涵盖新出现的每个源项方向；旧规则中没有新查询也不等于它不可约。对发散残差应先约化新出现的一圈积分，保留接触项和整组合，分别报告局部残差、积分后残差和完整源项覆盖的证据。
