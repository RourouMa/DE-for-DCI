# 有限覆盖策略复核（2026-09-27）

这批结果从原始 Top 重新迭代，在完整物理关系池内重构有理坐标；旧 DE 与约化规则不作为新关系使用。

| 系统 | 旧最高圈 / 完整系统 | 新最高圈 / 完整系统 | 状态 |
|---|---:|---:|---|
| ladder | 19 / 30 | 12 / 23 | 最高圈与含源完整系统均独立验证通过 |
| tennis court | 31 / 46 | 23 / 38 | 最高圈与含源完整系统均独立验证通过 |

各图形目录中的 `HighestLoop.wl` 保存最高圈基、矩阵和逐轮记录；`DifferentialEquations.wl` 保存完整基、矩阵、family 和原 Top 坐标。先加载 package 的 `Kernel/ConformalIBP.wl`，再用 `Get` 读取工件。约定为 `D[B,z] = Matrices[z].B`。

ladder 的逐轮最高圈覆盖为 `3, 6, 10, 12, 12`。12 项中有 8 项常系数、4 项含运动学系数，求导已包括系数导数。所选分母正幂满足外点—圈点不超过 3、圈点—圈点不超过 2，内部传播子实测最高为 1。完整系统为 `12+7+4`；低圈候选沿用已有有限定义，不声称低圈或全系统已经全局最小化。

tennis court 的逐轮最高圈覆盖为 `3, 6, 10, 15, 21, 23, 23`。23 项中有 17 项常系数、6 项含运动学系数；完整系统为 `23+11+4=38`，同样满足上述幂次上限。完整物理池中保留了 95 个未显式映射源列，最终 DE 未留下未约化源。

最高圈有限覆盖的组成：ladder 为 5 个单积分、3 个常系数组合、4 个含运动学系数组合；tennis court 为 15 个单积分、2 个常系数组合、6 个含运动学系数组合。每个组合整体计为一项，其有限性按整体检验。最长组合分别包含 10、25 个不同积分，详见各目录 `CombinationAudit.json`。

`HighestVerification.json` 与 `FullVerification.json` 是独立验证的原始报告：重新求原生导数，核对完整物理池、有限性、独立性、原 Top 覆盖及一个非奇异有限域点的曲率。矩阵来自有理重构；此次不默认计算符号残差或符号曲率。

`ArtifactManifest.json` 记录导出文件 SHA-256；各图形的 `FrozenSourceHashes.json` 区分最高圈运行、完整系统重构使用的冻结源码。报告中的 `CandidateSHA256` 对应原始完整候选文件，导出文件去掉了大型关系池的运行路径，故另有自己的工件哈希。大型物理方程池未复制进 Git，原始工件位置与哈希保留在导出数据的 Provenance 中。便携矩阵文件本身不能替代重新生成关系池的完整验证。

四圈比例策略与三圈历史校准见 [物理行坐标说明](../../docs/PHYSICAL_ROW_COORDINATES.zh-CN.md)；本目录不宣称四圈闭合。

组合完整定义见 [ladder](ladder/Combinations.md) 和 [tennis court](tennis/Combinations.md)，对应 `.wl` 文件可直接加载。逐项有理系数核对记录保存在 `CombinationDefinitionsVerification.json`。

当前覆盖项数虽已减少，但尚未优化矩阵复杂度。约分后最高圈矩阵的分子/分母最大总次数分别为 ladder 29/33、tennis 65/71；完整系统为 53/57、108/112。Tennis 完整系统的 Ax[22,26] 在因式分解后仍约 58516 字符，后续选基应同时考虑覆盖数、组合长度和矩阵元复杂度，不能仅以项数评价简洁性。完整审计见 `MatrixComplexity.json` 与 `MatrixFactorComparison.json`。

旧完整系统的最大分子/分母总次数仅为 ladder 18/18、tennis 28/25。新压缩基明显增大了矩阵复杂度，因此本次结果仅说明已验证闭合覆盖项数减少，不应称为整体表达式复杂度改进。对照见 `MatrixComplexityComparison.json`。

后续选基遵循已记录的 [项数与矩阵复杂度经验](../../docs/FINITE_COVER_COMPLEXITY_LESSONS.zh-CN.md)。
