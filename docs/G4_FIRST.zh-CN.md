# 计算顺序：先闭合 G4，再补低圈

按照用户 2026-09-20 的明确要求：

1. 四圈 IBP 生成、消元和方程验证保留 G3 contact 源项。完整消元必须导出已有方程蕴含的低圈约束，不能丢弃低圈 pivot 规则后声称完整残差为零。这一步不生成新的低圈 IBP。
2. 确定四圈有限主积分、构造常系数组合、检验两个方向导数是否回到同一输入空间时，只使用 G4 系数。源项另行保存。
3. `ClosedModuloBoundary -> True` 表示 G4 层次闭合。含源系统的完整物理闭合仍需后续低圈计算。
4. G4 闭合后，`LowerLoopDETargets` 从最终 `BoundaryRows` 的实际低圈支持提取；以这些积分为低圈约化目标，再生成低圈 IBP、约化和 DE。不得提前对无关的全体低圈积分铺开计算。
5. 依次处理三圈及实际出现的更低圈源项，最终组装完整三角 DE，并验证完整重构与一致性。

`ReduceIntegrals` 的 `Rules` 现在同时包含同圈及低圈规则；分别见 `SameLoopRules`、`BoundaryRules`。`ColumnOrder` 是完整消元列序。自定义 solver 的第三个参数现在请求全部列的规则；遗漏必要低圈规则仍会被严格的完整残差检查拒绝。

每次约化验证后即保存检查点，之后才进入耗时的 IBP 扩充。源码更改后新建 campaign，只复用完整关系，从原始输入重放；不改写旧 implementation hash，不继承旧 application ledger。

每轮统计可运行 `WolframKernel -script scripts/report-rounds.wls <campaign目录>`，读取冻结源码与已保存的 `epoch*/round*/` 结果，输出 `CompletedRounds.json`。它不重新计算或修改检查点；扩充后的 Top 覆盖预览应另列，不能冒充下一轮完成结果。

本次按轮次推进采用 `GenerationPolicy -> "OnDemand"`：查询在已有关系中覆盖且有限覆盖已认证时，直接求下一轮导数；有未见查询或有限覆盖失败时才调用 IBP 生成。若生成无新关系，仍保留未见查询审计并按实际有限覆盖和精确闭合检验处理，不能把未见查询数量单独当作闭合结论。新关系合并后仍从原始输入重放并核验历史规则。0.2.0 默认 `"OnDemand"`；显式 `"Always"` 保持原有每轮先生成关系的流程。该选项是通用圈数策略，不是独立四圈引擎。
