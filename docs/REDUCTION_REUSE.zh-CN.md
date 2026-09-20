# 相同完整系统的约化结果复用

`ReduceIntegrals` 默认启用 `ReuseVerifiedReduction -> True`，仅在当前 Wolfram 进程中保留最近一个成功的完整约化。工作副本包含此修改；正在运行的旧生产进程不受影响。

在完成对称规范化与列排序后，用 family hash、实现指纹、完整非零关系、完整有序列、求解器和限制参数计算 SHA-256。仅当这些内容一致，且求解器为 Exact 或 FiniteFlow，才复用此前通过完整方程残差和幂等检验的规则。新查询的约化结果、masters、低圈源项、自约化和未覆盖查询均重新计算。新关系、新列、排序或设置变化都会使缓存失效；自定义求解器始终执行与验证。缓存不从检查点历史规则中构建，不跨源码版本导入。

进度日志增加 `Reusing verified full reduction`；返回值增加 `ReductionReused`。命中时 `StageTimings` 仅记录本次规范化与列排序的实际耗时，不将旧求解耗时算入本次。可设置 `ReuseVerifiedReduction -> False` 强制独立求解作为对照。

验证：ReductionReuse 的 13 项检查通过，含 FiniteFlow 复用/重新求解/Exact 三方一致、新关系及新列失效、完整低圈约束、自定义错误规则拒绝、失败不污染缓存和参数限制不能被绕过。核心 29 项、BoundaryReduction（含 FiniteFlow）10 项、OnDemandDE 7 项通过。

此优化不能缩短首次大系统求解，只避免完全相同系统在后续 DE 轮次中重复求解。仍须从 Top 重放扩充后的系统，并由精确检验判断闭合。
