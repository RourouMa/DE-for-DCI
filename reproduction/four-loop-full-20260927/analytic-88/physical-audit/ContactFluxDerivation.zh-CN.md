# 四维碰撞接触项的小球通量审计

审计对象为 `Kernel/ConformalIBP.wl` 的 `contacts` 与 `toIntegral`。本说明区分局部数学公式、单一 G 的接受条件、整组耦合情形；没有据此断言当前已选 DE 中存在错误。

固定其他环坐标，在一次碰撞附近取欧氏局部坐标 z=yi−yj，且 (YiYj)=|z|²。把余下光滑因子记为 H(z)，投影到物理四维坐标的 IBP 向量记为 v(z)。按 d⁴z/π² 的测度，流为

\[
 j^\mu(z)=\frac{v^\mu(z)H(z)}{|z|^4}.
\]

设 W=vH，并展开 W(εn)=W(0)+εnν∂νW(0)+O(ε²)。利用 S³ 面积2π²和球面平均 nμnν=δμν/4，得到从小球内部指向外部的通量

\[
 \lim_{\epsilon\to0}\frac1{\pi^2}\int_{|z|=\epsilon}
 n_\mu j^\mu\,dS
 =\frac12\partial_\mu W^\mu(0)
 =\frac12\{H\,\partial\cdot v+v\cdot\partial H\}_{z=0}.
\]

常向量项的1/ε贡献由于角平均为零而消失，但线性 H 项的有限通量一般不会消失。若是有限项之和，必须先将所有对应 current 相加，再取该通量。这里陈述的是切去小球后的有限通量；若单项 v(0)≠0，其 current 本身不是局部绝对可积分布，不能不加说明就给单项任意指定一个 δ 延拓。

令 ambient 向量为 V=(Y·A)B−(Y·B)A，并记 σ=(∞·V)/(∞·Y)。在 affine gauge ∞·Y=1 中，projected conformal 向量满足 div v=−4σ。因此完整通量是

\[
 \mathcal C=-2\sigma(0)H(0)+\frac12v(0)\cdot\partial H(0).
\]

现实现逐向量分量的 `−2 H c (∞·vector)/(∞·Yi)`，相加后给出首项 −2σH。第二项只有在额外条件成立时才能省略。

若生成元包含碰撞邻点，例如 A=Yj，则 projected v(0)=0。用 Yj=(1,0,0)、Y(z)=(1,|z|²,z) 和内积 (Y(z),Y(w))=|z−w|²，写 B=(b0,b1,b)，可直接算出

\[
 \sigma=-b_1+2b\cdot z,\quad
 v=|z|^2b+(b_1-2b\cdot z)z,\quad
 \operatorname{div}v=-4\sigma.
\]

故通量为2b1H(0)，恰等于程序的 −2σ(0)H(0)，不存在遗漏的 H 梯度项。交换 A、B 同理。这一证明不需要对两个 endpoint 再作对称相加。

对于单一 G seed，传播子幂次上限 YiYj≤2，且生成元不含碰撞邻点，单个有效碰撞的程序项为

\[
 -2H\frac{(Y_jA)(\infty B)-(Y_jB)(\infty A)}{(\infty Y_j)}.
\]

在当前实现的标量积代数中，∞A、∞B、∞Yj 是不同的未指定符号。普通非零单项 H 无法消去这些符号，所以 `toIntegral` 的 `FreeQ[e,infinity]` 检查将其拒绝；它不会悄悄作为普通单项关系进入 pool。若 A 或 B 恰为 Yj，才有显式的比值1和前述安全的 vanishing-vector 情形。没有有效双极点时，幂次≤1 的边界通量趋于0。多个 endpoint 还要分别满足实现的 overlap 与收缩源有限性检查。这里的论证只覆盖这些单一 G primitive，不自动扩展到 whole-seed 或 coupled 组合。

对于合并后才消去∞的组合，令 W=Σa va Ha。消除三次传播子幂等约束可迫使 W(0)=0 或其线性径向部分具有特定形状，但这不等价于 Σa va(0)·∂Ha(0)=0。最简单的局部反例是四个平移向量 va=e_a 配 Ha=z_a：每个 Ha(0)=0，而 W=z，真实通量为2。这个例子证明仅有“整和消去零阶端点项”不足以推出公式，但没有证明它能由当前允许的 DCI seed、degree 和 topology 实现。因此不能拿这个抽象例子当成当前 DE 的反例。

对实际 whole/coupled 关系，充分而可直接检验的条件为：每个 endpoint 上的遗漏梯度和精确为0，或其完整收缩后的低圈积分由独立已证关系精确为0。也可以直接从合并的 physical current 计算 1/2 div W，并与现 contact 逐项比较。仅检查曲率、有限 ordinary 输出、∞消去或两个 endpoint 的标签对称，都不能替代这一步；对 endpoint 同时平移的特殊组合可通过沿碰撞对角线分部积分建立相消，但必须带上全部 current 和相应收缩因子证明。

当前结论：单一 G 中被∞过滤接受的邻点 contact 有上述直接通量证明；组合关系需要独立审计其实际 provenance 和完整 current。本说明不修改 package 或冻结的 DE。
