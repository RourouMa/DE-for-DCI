# 完整四圈微分方程（2026-09-27）

完整系统以 **88 个有限单积分**闭合：53 项四圈、24 项三圈、7 项二圈、4 项一圈。原 83 项的顺序保留在前 83 项，84–88 项是新增的五个三圈源项代表。全部代表满足 XaYi≤3、YiYj≤2。

两张有理矩阵为 `A_x.wl`、`A_y.wl`，完整结构与对应积分次序在 `DifferentialEquations.wl`，约定 ∂x I=A_x I、∂y I=A_y I。`MasterIntegrals.wl` 和 `Integrals88.md` 提供积分定义；`OriginalTopCoordinates.wl` 给出原始 Top 的覆盖系数。

已经完成：

- 在完整原生物理方程池中，积分与全部导数的秩均为 88；所有低圈源项保留。
- 有理矩阵重构完成，并在 (11,17)、(13,19)、(23,29) 三点独立重新生成原生导数、求解完整物理池，检查基独立性、矩阵方程和原始 Top 覆盖。
- 完整 88×88 曲率矩阵的 7,744 个元素逐项精确为零。
- 原有四圈 53×53 最高块和新闭合的低圈 35×35 块均与独立结果完全一致。

检查记录分别见 `Report.json`、`SpanAudit.json`、`independent-verification/Report.json`、`ExactCurvatureReport.json`、`ExportIntegrity.json`。`MatrixComplexity.json` 分别记录最高块、低圈源耦合块、低圈块与完整矩阵的复杂度。

本目录包含可直接使用的结果与证书。大型原生物理池未复制进 package；原始审计数据保留其绝对路径、哈希与完整来源。全部积分的解析函数随后已完成，见下方 analytic-88 链接。

在 Wolfram 中先加载 package 的 `Kernel/ConformalIBP.wl`，再用 `Get` 读取 `DifferentialEquations.wl`，即可通过 `data["Basis"]` 和 `data["Matrices"][x]`、`data["Matrices"][y]` 访问数据。

最终综合检查见 `FinalValidation.json`。构建时的 `Report.json` 保留原始哈希，因此其中 `SymbolicCurvatureChecked:false` 记录的是构建阶段；随后完成的全符号检查见 `ExactCurvatureReport.json`。

`analytic/Lower35Functions.wl` 给出全部 35 项低圈积分的解析函数及证书。`analytic/BoundaryValues88.wl` 给出 (x,y)=(1,1) 的 88 项正则边界值，其中 53 项四圈积分具有共同的精确值，推导见 `analytic/SpecialPointDerivation.md`。该阶段的边界记录已由后续完整 dlog/Frobenius 计算补齐：全部初始数据和四圈函数现已确定，见 analytic-88。

完整 88 维已进一步找到并验证常数留数 dlog 形式，见 [dlog 结果与复核](dlog/README.zh-CN.md)。显式有理变换、逆、18 字母及稀疏常数矩阵均已导出；完整回代与符号曲率再次独立通过。

[全部88项积分的解析结果](analytic-88/README.zh-CN.md) 已完成并同步：显式有限 Chen/GPL 函数、全部常数、正则性证明与精确递推证书均可读取。top 在 (1/4,3/4) 的两组独立原积分计算通过预设0.1%统计精度检查，采用全部sector先求和再统一积分。旧并发与相关误差问题及未收敛尝试均保留记录；最终比较见 `analytic-88/numerical/FinalDirectValidation.json`。

后续拓扑的复用方法见 [四圈 tennis court 流程](../../docs/FOUR_LOOP_TENNIS_WORKFLOW_20260927.zh-CN.md)，新增 [tropical 试跑](../four-loop-tropical-20260927/README.zh-CN.md) 独立保存，未替代已通过的 Top 数值验证。

同步验证见 [SYNC_20260927.json](../../docs/SYNC_20260927.json)。从 package 根目录运行 `python3 scripts/verify-artifacts.py` 可核对已发布结果的 SHA-256 清单。
