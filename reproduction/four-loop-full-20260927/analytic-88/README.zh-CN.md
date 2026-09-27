# 全部88项积分的解析结果

已完成 **53项四圈 + 35项低圈** 积分本身的解析函数，覆盖原先要求的83项及新增5项。所有积分常数均已确定，不含未知边界参数。

结果是显式有限 Chen 迭代积分，可按有限根集合转换为 Goncharov GPL。最高词长为8；top有3084个非零双词项。初始实区域为 0<x<y³<1，其他区域按同一分支一致解析延拓。

从 `solution/AnalyticSolution.wl` 加载后，可直接用 ``DCIAnalytic`Integral[i]`` 读取第i项，或用 ``DCIAnalytic`Integral[i,1/4,3/4]`` 代入参数。完整定义、GPL转换和使用示例见 [函数说明](solution/README.zh-CN.md)。

主要文件：

- `solution/NativeFunctions88.wl`：全部原生积分的函数列表。
- `solution/TopLadderFunctionExplicit.wl`：四圈top的单独解析表达式。
- `CanonicalBoundaryConstants88.wl`：全部88个新基常数。
- `boundary/BoundaryRegularityProof.zh-CN.md`：原积分解析性、边界充分性证明。
- `AnalyticCertification88.json`：综合证书；196671条精确词系数递推全部通过。

边界通过两条独立构造和两条一般射线逐项精确核对；704×88纯有理约束矩阵满秩，故无额外自由Taylor初值。历史计算报告中的待论证标记由本目录最终边界证书更新其结论，原始记录保留。

在 (x,y)=(1/4,3/4)，两个Taylor路径与独立NDSolve共同给出

    I_top = 1.294977445434631202675686442291414292929…

它们保守一致到40位。显式62140项Chen表达式另行求值，完全不读取DE矩阵；全部88个原生分量与DE解的最大绝对差为4.32e−49，见 `chen-evaluation/ExplicitChenNumericalValidation.json`。

**top 的独立原积分检验已通过预设0.1%统计精度检查**。两个事先固定seed各完成1,050,000次完整sector总和采样，结果分别为1.29479831892550±0.00046444701710与1.29568022167161±0.00047171385151；与解析值相差0.39和1.49个报告误差。见 `numerical/FinalDirectValidation.json`。统计误差不是严格界，这也不是对全部88个积分逐项作独立原积分数值检验。

旧多sector线程共享积分器会造成并发风险，串行Cuba逐sector复用seed又可能使误差相关。最终计算先在每个采样点把全部1492个sector相加，再对这个完整函数作一次Vegas积分，排除这两项配置问题。旧结果及未收敛尝试全部保留，不用于验收。

边界B4的经典式、谱展开和径向积分又经全新单进程复算，最大差1.69e−98；88项精确边界的求解未读入任何直接QMC结果。原始边界积分的两次串行sector复核都在一个报告误差内支持B4，但实际相对误差约4e−5，尚未达到请求的1e−5。详见 `boundary/BoundaryConcurrencyAudit.zh-CN.md`。

另记录了物理解析分支上的J83=0及其14项原生积分关系，供后续有限覆盖约化使用；未改变冻结88维系统，也未声称该关系已由旧IBP池推出。
