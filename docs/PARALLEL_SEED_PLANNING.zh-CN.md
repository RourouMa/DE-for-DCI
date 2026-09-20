# 并行准备撒点计划（0.2.4）

大范围回退补点可能先产生数百万个 Cartesian 邻域候选。0.2.4 在生成 IBP 关系前，按原始目标中心分片调用同一 GenerateSeeds，再逐算符合并 seed 集合，最后统一扣除已完成应用及跨分片重复应用。域、symmetry images、block expansion、算符集合和 ordering 均不改变。

|选项|默认值|含义|
|---|---|---|
|`SeedPlanningWorkers`|`Automatic`|使用 `Workers` 指定的核数；设为 1 可禁用并行准备|
|`SeedPlanningThreshold`|64|原始目标中心数量至少达到此值才并行；小任务串行以避免启动开销|
|`Workers`|1|IBP 关系生成的核数，也是默认规划核数|
|`VerificationWorkers`|1|精确残差核验核数，独立配置|

规划和关系生成是相继执行的阶段，不同时启动两组 worker。库默认仍不自动使用全部机器资源；32 核机器可显式设 `Workers -> 26`、`VerificationWorkers -> 26`。FiniteFlow 线程另行配置。

GenerateSystem 和 RunDE 支持这些选项。GenerateSeeds 本身保持原来的纯串行几何接口，方便逐项比较。可设置 ProgressFunction 观察“Preparing seed plan”“Seed plan prepared”“Seed plan deduplicated”，区分准备、去重与实际 IBP 生成。

所有分片必须成功退出，且实现哈希、family、精确目标索引和目标哈希均一致，才接受合并结果。规划代码与 worker 脚本均纳入 checkpoint 实现指纹。失败分片目录保留；不会把部分计划误当作完整撒点。

实际四圈案例：652 个原始中心对应 3,708 个域内 symmetry 中心，产生 7,057,355 个筛选前 Cartesian 候选。25 个分片在约 55.06 秒内完成计划计算，合并为 91,442 个不同 seed、670,576 个普通候选应用；扣除 90,092 个历史已完成应用后，执行 580,484 个增量普通应用。这里 55 秒仅指规划分片，不是整轮 IBP 生成或 DE 求解耗时。

`Tests/ParallelSeedPlanning.wls` 比较 Original/Cartesian、Original/SingleBlock、Extended/Cartesian 下的完整串并行计划，覆盖连通及 factorized 中心，并验证生成的关系和应用集合一致、统一账本去重、小任务回退与参数检查。关系集合的比较忽略无关的输出顺序；约化 ordering 不受影响。

当前四圈正在使用冻结 0.2.2 加一次经独立校验的预生成计划接续，未热替换为 0.2.4。后续使用新版本时仍须通过正常 checkpoint 兼容性检查或显式审计的兼容迁移。
