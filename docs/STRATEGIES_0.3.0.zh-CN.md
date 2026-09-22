# 0.3.0：撒点与优先覆盖策略

本次将运行快照中已验证的优化移入正式 package。版本与实现指纹已更新；旧 checkpoint 必须继续使用旧快照，不能直接作为新版本状态恢复。

## 撒点

- component-local axial ±1 邻域与 operator degree 匹配；Cartesian 默认，SingleBlock 可显式选择。
- 大规模 seed planning 可按中心并行；分片合并后按 operator hash 与 seed 全局去重，已完成 application 不再派发。
- worker 仅接收所需 ledger 和 symmetry cache，避免复制全套历史。
- 每次新增方程覆盖其全部积分支撑的 ordinary/factorized symmetry；合并关系后重新从原始 top 开始，重核历史约化。
- 默认 `SeedDomain -> "Original"` 保留原域搜索；需要 factorized supersector 时显式设 `"Extended"`。Extended 仍受已声明 family/completion/supersector 约束，不允许任意正幂 ISP。
- tennis court 示例使用 `Completion -> "FamilyOnly"`，以实际拓扑收缩确定 Y1–Y2、Y1–Y3 的横向 ladder 和 Y2–Y3 的纵向 ladder，再补旁观一圈 box。没有把横向或纵向 ladder 任意配给各对圈变量。
- 已有联合 seed/operator 约束搜索作为显式功能保留；它不证明局部撒点完备性。

## 优先保留的列排序

排序键升序排列：前面的列先消去，较大的键优先保留。

| 策略 | 名称 | `IntegralOrdering` |
|---|---|---|
| O1 | 积木优先 | `Legacy` |
| O2 | 梯子优先 | `LadderFirst` |
| O3 | 参考导航 | `Reference` |
| O4 | 四层积木 | `TierBlocks` |
| O5 | 四层梯子 | `TierLadder` |
| O6 | 四层导航（默认） | `TierReference` |

四层保留优先级：认证有限 factorized、未认证有限 factorized、认证有限 connected、未认证有限 connected。O6 各层使用 ordering01 的结构/低圈参考形状键，最后沿用基础键打破平局。参考形状来自既有 ordering01 比较的形状列表，仅提供排序分数，不导入约化规则、积分值或 tennis court 结果。`ClosureFirst` 是保留的旧配置，其列键同 O1，但规范化偏好原域代表。O2 也偏好原域规范代表，其余新策略使用字典序规范代表。

## 全有限时直接覆盖

若实际约化表达式的全部 G 都通过 `FiniteIntegralQ`，直接以这些 G 为覆盖，不再计算最小行空间、候选成员资格或有限组合。以线性系数映射精确保留 weights 和所有 `BoundaryIntegral` 源项。仅有发散支撑时才构造并认证常系数有限组合。

这不等于 DE 已闭合：新导数仍需 IBP 约化，并在同一输入空间内检验闭合。计数稳定和覆盖成功都不能代替闭合验证。闭合后的原域偏好改为显式 `BasisPreference -> "FamilyAfterClosure"`；默认 `"None"`。

## 后端与验证

生产计算显式加载 FiniteFlow 并使用 `Solver -> "FiniteFlow"`。加载后，含参数的行空间及逆矩阵改走 FiniteFlow；每次保留精确重构检查。常数矩阵与未加载 FiniteFlow 的小型精确回归路径保留 Wolfram 实现。

数值残差默认一个非奇异点，两变量为 (11,17)，残差模素数 1000003；全池对照使用 FiniteFlow 自身的有限域素数。显式两点列表仍支持。单点检查是数值证据，不冒称符号证明。完整 residual 行覆盖及低圈源项均保留。`Workers` 和 `VerificationWorkers` 可设为 24，FiniteFlow 的 `FFNThreads` 需另外设为 24。

## 验证边界

[验证记录](VALIDATION_0.3.0.json) 包括 27 组完整回归与单独执行的 FiniteFlow 线性代数检查，共 28 组。覆盖直接有限重构、非线性输入拒绝、排序、拓扑收缩、并行撒点/去重/残差、历史重放、单点/显式两点及 FiniteFlow 原方程子集对照。它不声称新的 tennis court 全系统已经闭合。
