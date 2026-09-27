# 物理积分映射与归一化复核

本审计不改变任何已冻结 DE、边界或解析函数，也不据数值差异拟合积分常数。四圈 top 的独立数值验证仍有未解释差异，本文件不宣称该项已通过。

`LegacyPhysicalMappingAudit.json` 使用独立 Python 图指标置换（loop 全排列、每个连通分量外点 1↔3 与 2↔4）检查旧 83 与完整 88 的物理定义。83 项全部保持；16 项还与早期低圈直接积分逐项对应，不需额外有理或 loop 因子。其中 7 项是连通三圈积分，历史直接数值与当前解析值在 2.09 个所报误差内。旧运行的 amplitude sector threads=2，因此这些历史误差不能单独排除后续发现的 integrator 线程共享问题。新的三圈 top 串行 sector 检查使用 amplitude threads=1、QMC 内部 threads=2，结果另行记录。

原数值生成器把每个 loop 的最后一个 `1` 视作光锥测度指标，不把它当作额外 Feynman 传播子。普通传播子为 `(ki-qj)^2-mj^2` 和 `(ki-kj)^2`，外部质量平方依次是 `{x,y,x,y}`；pySecDec 使用 `d^D k/(i pi^(D/2))`。乘以 `(-1)^sum(propagator powers)` 后即为 Wick 转动后的正 Euclidean 传播子约定。没有额外的 loop 阶乘。

四维归一化的基本局域恒等式是

\[
\partial_h\cdot\frac{h}{(h^2)^2}=2\pi^2\delta^{(4)}(h),\qquad
\int\frac{d^4h}{\pi^2}\,2\pi^2\delta^{(4)}(h)=2.
\]

因此在 **IBP 向量在碰撞点为零** 的常用邻点 generator 中，`contacts` 的系数 `-2` 与低一圈归一化相容；不能再额外乘 `pi^2` 或改变 loop 阶乘。

一个可独立作 Feynman 参数积分的两圈例子由 `contact-low-witness.wls` 重新生成：

\[
4x\,G_2[0,0,0,3;0,0,3,0;1;1,1]
-2\,G_1[1,3,0,0;1]=0.
\]

其中外点对称仅用于把最后的一圈积分写成此指标顺序。直接积分消去幂次 3 的 massive 端点给

\[
\int\frac{d^4k}{\pi^2}
\frac1{[(k-q)^2+m^2]^3(k-z)^2}
=\frac12\int_0^1\frac{da}{[m^2+(1-a)(z-q)^2]^2}
=\frac1{2m^2[(z-q)^2+m^2]}.
\]

取该端点 `m^2=x` 即逐项证明上述联系，不使用当前 DE、边界或 contact 算法作为输入。相邻外点标量积为零时还有

\[
G_1[1,3,0,0;1]
=\frac12\int_0^\infty\frac{du}{(xu^2+y)^2}
=\frac{\pi}{8\sqrt{x}\,y^{3/2}}.
\]

一般 nonvanishing-vector 的单边小球通量包含 `v(0)·grad H(0)`；不能从此安全邻点例子推断所有 joint contact 公式普遍正确。实际 primitive 中外点–外点 generator 的双极点 contact 含未消除的 `infinity` 标量积，`toIntegral` 会拒绝。本目录的 `LowContactWitness.wl` 保存了具体拒绝和安全接受的实例。整组合、coupled action 需要另外审计其完整向量；没有用“seed 自身发散”作为判错理由。
