# ordering01 撒点与关系快照

## Family 和编号

26 个位置：1--16 为按 Y1、Y2、Y3、Y4 分组的 X1、X2、X3、X4 线性传播子；17--19 为 Y1Y2、Y2Y3、Y3Y4；20--22 为非相邻 loop-loop ISP：Y1Y3、Y1Y4、Y2Y4；23--26 为四个 delta-cut。

```wolfram
G[1,1,0,1, 0,1,0,1, 0,1,0,1, 0,1,1,1,
  1,1,1, 0,0,0, 1,1,1,1]
```

外线 kinematics、Dx/Dy 和具体传播子定义由冻结 `legacy/IBP4loop.wl` 给出。

## 实际撒点策略

1. 围绕 target 和未真正化简的复杂自由代表元；“在矩阵列中”不等于“已经约掉”。
2. 在相关因子块的局部指数空间取中心及每轴 +1、-1。不同块分别选局部点，再作笛卡尔积。因此完整指数向量允许多个块同时变化，不等于只对完整四圈向量整体移动一轴。
3. 因子块补全为相应 ladder/box supersector：三圈乘一圈使用三圈 ladder 与一圈 box；两圈乘两圈使用两个 double box；两圈乘一圈乘一圈同理。新增外线分母仅在每条记录明确给出的 `AllowedDenominatorTemplates` 中合法。
4. 非相邻 loop-loop ISP 20--22 不得为正；17--19 的种子遍历合法的 0、1、2，不引入三次极点。不得通过丢弃 `sp[_,inf]` 使关系“合法”。
5. 每个种子严格与该行 `DegreeID`、`OperatorIDs`、`Degree` 配对；对线性 X.Y 也按 Y 缩放。所有 degree 类均保留，不能只用零 degree。几何候选须经过整体 conformal/power-counting 和 domain 检查。
6. 任意 Y 置换，以及允许的 X1/X3、X2/X4 交换及其组合；factorized 各连通块独立选择外线变换，枚举笛卡尔积。判断连通块包含非零 loop-loop 分子耦合，不只看正幂边。

## 必须保留的修复与增量

`targeted14` 使用 `targeted13` 的相同几何 seeds，在修复 factor-local contact action 后重新计算，不能把旧 rejected/zero 缓存当作已通过的新关系。冻结 `IBP4ContactLaurentCache.wl` 等文件和 generator fingerprint 一起发布。

`expanded13/GenerationAudit.wl` 记录 `targeted16` 的 73,372 次作用已纳入；其 block neighborhood 为严格轴向。`expanded14/GenerationAudit.wl` 记录另外 84 条跨种子的零-degree 完整算符恒等式，新增 81 条 canonical rows；它们不新增种子指数向量，完整作用已检查 degree、domain、无 infinity 丢项及 literal collision residue。`ordering01` 在该矩阵上进一步固定代表元偏好和列顺序。

完整快照为“基线矩阵 + 累计 canonical 增量”，不是只包含最近一次 targeted seeding。`matrix/CanonicalAddedEquations.wl` 含 1,322,411 个累计条目，装配后应得到发布的总行数。

## 文件如何使用

- `Operators.wl`：原始算符块的可移植 WL 文本；`OperatorAudit.wl` 记录 degree 类及逐算符 homogeneous 检查。
- `data/provenance/campaign/targetedNN/SeedData.wl`：每行的实际 seeds、operator IDs、degree 及分母模板。
- 同目录 `SeedSummary.wl`、`IndependentQA.wl`、`GeneratorUpgrade.wl`：几何规模、domain/degree 检查及生成器版本（文件按历史实际存在情况提供）。
- `data/provenance/campaign/expandedNN/GenerationAudit.wl` 和 `SystemManifest.wl`：哪些关系正式进入哪个系统。
- `data/provenance/campaign/expanded14/CoupledActionProvenance.wl`：跨种子恒等式的具体线性组合。

历史记录中也包含诊断、旧生成器和未采用的探索。保留这些是为了审计，**不能认为每个探索结果都属于当前生产矩阵**。完整历史 normalization/unit archives 未整体上传；已经发布 raw-to-canonical 的最终 `QueryMap.wl`、完整消元矩阵及规则，因此复现第四轮不依赖那几百 GB 历史中间映射。若要从最早 seeds 重新构建每一步 normalization，这不是本次便携复现入口涵盖的任务。

## 在 Ubuntu 重算已保存的 seeds

可移植 `seed_worker.wls` 直接读取 `Operators.wl` 和实际 `SeedData.wl`，使用相同 contact-local 生成器，重新检查 degree、domain 及直接算符作用。以下是在四个独立 shell 中分别运行的四个任务，不使用 Mathematica Parallel：

```bash
IBP4_SHARD_ID=1 WolframKernel -script reproduction/ordering01/seed_worker.wls
IBP4_SHARD_ID=2 WolframKernel -script reproduction/ordering01/seed_worker.wls
IBP4_SHARD_ID=3 WolframKernel -script reproduction/ordering01/seed_worker.wls
IBP4_SHARD_ID=4 WolframKernel -script reproduction/ordering01/seed_worker.wls
```

默认重算 targeted16；可设置 `DCI_SEED_TAG=targeted14` 等已有且含显式 domain 的 campaign。输出默认 `work/seed-targeted16/shardN/`，已有输出时拒绝覆盖。`DCI_SEED_SMOKE=1` 每个 operator 行只测试该 shard 的第一个 seed，**不等于完整重算**。此 worker 产出待合并的 raw IBP，尚不自动执行全部新积分的 ordinary/factorized symmetry 和重新消元；现有完整 symmetry 结果已在发布矩阵中。新扩充不能只拼接 raw IBP 后省略 symmetry。
