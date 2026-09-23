# DE 选基与进度汇报规范

适用于 package 和实验脚本；2026-09-23 用户澄清后的策略。目标是**保证有限性、完整覆盖和 DE 闭合的前提下，让有限基及微分方程尽可能简单**。不得将策略偏好当作数学上的禁止条件。

## 选基与自主判断

1. 优先单独有限积分和简单常系数组合，先试两项、小支撑、小整数系数。不能为了全部使用单独有限积分而无说明地增加实际空间之外的方向。确需扩大覆盖时，报告新增维数和后续求导成本。
2. 常系数搜索未成功，先检查实际系数空间、候选筛选是否过严、已有方程池复用、遗漏的 IBP 与 symmetry。factorized symmetry 必须覆盖相应的实际撒点 supersector，并尊重 family 能包含的子拓扑。
3. 三圈已知可找到常系数有限基，应优先诊断独立计算中的缺口；这一先验不能替代独立计算、导入参考答案或预设闭合维数。四圈不预设常系数必然足够。
4. 当常系数搜索在明确范围内受阻，或变量系数候选可能显著简化覆盖与 DE 时，可以自主尝试变量系数。记录搜索范围、关系审计、替代方案、选择理由及复杂度比较，不需要把科学判断交回用户审批。有限基数量、组合项数、系数大小/表达式复杂度、系数引入的极点以及 DE 复杂度都应纳入比较；探索时尚未测出的指标明确标为未知。
5. 任何候选都须验证完整表达式有限、原输入和全部导数精确覆盖，保留低圈源项。变量系数必须按乘积法则完整求导。失败的候选保留诊断，不能丢弃裸发散项或未覆盖项后推进。

默认 `BuildFiniteBasis` 仍实现常系数搜索，不宣称已实现自动变量系数搜索。扩展构造器可提交 `VariableCoefficientDecision`，包含非空的 `Reason`、`ConstantSearchSummary`、`RelationAudit`、`AlternativesCompared`。`finiteBasisContract` 检查该记录、全量计数、有限性和覆盖证书标志；它不是重新证明覆盖的求解器，也不把填写记录本身当成数学证书。

## 每轮必须报告

使用固定顺序：**策略 / equation-pool epoch / 本 epoch 轮次 / 当前阶段 → 输入与 DE → 约化支撑 → 有限覆盖 → 秩与闭合 → 验证 → 下一步**。

| 字段 | 含义与限制 |
| --- | --- |
| `Strategy`, `Epoch`, `ReplayNumber`, `Round` | 初始 epoch 为 0；进程重启、换基不是扩池重放。 |
| `EquationCount`, `EquationPoolHash`, `NewRelations` | 明确方程池身份；只有关系实际加入才算扩池。 |
| `InputCount`, `DERows`, `Targets` | 本轮完整输入基数、求导行数、查询原子数，不能互相代替。 |
| `RawSupport`, `RawSingleFinite`, `RawNotIndividuallyFinite` | 实际约化表达式中的原子支撑，后两者之和等于前者。未单独通过有限判据不等于已证明全局不可约。 |
| `SingleFinite`, `ConstantCombinations`, `VariableCombinations`, `OutputCount` | 输出总数必须等于这三类之和；`Combinations` 为后两类之和。不得隐藏组合基。 |
| `InputRationalRank`, `ActualRationalRank`, `ActualRankVerified` | 区分输入秩与输入加导数空间秩。未算则 `Missing`，不能用 raw support 或覆盖数量代填。 |
| `CombinationComplexity`, `VariableCoefficientDecision` | 每个组合的项数、系数复杂度及变量方案的理由；完整定义保存到 artifact。 |
| `UnclosedDERowCount`, `UnclosedDERows` | 未回到同一输入空间的导数行及索引。失败、未检查与 0 必须区分。 |
| `ExactCoverage`, `BoundarySources`, `FiniteBasisArtifact` | 精确覆盖证书、低圈源项和可复现定义的位置。不能把源项设零或当常数求导。 |
| `ReductionVerificationMode`, `VerificationPoints` | 有理函数重构、单点数值残差与精确表达式覆盖分别说明。一个 generic 点验残差不等于只在该点重构。 |
| `ClosedOnSameInput`, `FullClosureVerified`, `FlatnessVerified` | 单圈空间闭合、完整含源系统闭合、曲率验证分开。每轮有限覆盖成功不等于 DE 已闭合。 |
| `NextAction` | 具体下一步和原因；不要只写“继续计算”。 |

`RoundStarted` 报告正在做哪轮；`RoundVerified` 只在验证后报告数值。构造失败用 `FiniteCoverFailed`，下一轮基数标为未接受。`PoolExpanded` 必须说明新增关系、对应 symmetry、历史目标重约化和从原始 top 重放。每次扩池都如此；无新关系时不为相同方程池反复重放。`CampaignFinished` 给出最终闭合层级，不能用最后一条有限覆盖汇报冒充终态。

长任务还应报告当前阶段、已经耗时、活跃 workers、是否复用缓存以及卡点；无法读到的状态写未知。单点验证要保存足够 generic 的点、素数及分母/异常点筛查，避免把特殊点降秩当成普遍关系。实际点值与验证证据保存到 reduction artifact，摘要保留链接。

示例（已验证的 O7 第 3 轮，不代表最终闭合）：

> O7 网球分区，epoch 0，第 3 轮：输入 14，DE 28 行；约化原子支撑 83，其中 49 个单独有限、34 个未单独有限。输出 25＝24 个单独有限＋1 个常系数组合＋0 个变量系数组合；实际空间秩 25，精确覆盖通过。尚未闭合，低圈源项保留；下一步对这 25 个完整有限表达式求导。

## 结果比较

比较 ordering 时固定方程池、目标和验证口径，区分计算用时、基数、实际秩、组合复杂度、DE 复杂度、闭合和 flatness。只证明新空间包含于旧空间，不能写成两套完整系统等价。没有证明全局独立性之前，使用“当前有限基/覆盖”而非“最终不可约主积分数”。

运行中的实验快照不会因 package 文档或源码更新自动改变。汇报必须注明已部署的 runtime 与仅在 package 中完成的更新；保留 checkpoint 的源版本和 hash。
