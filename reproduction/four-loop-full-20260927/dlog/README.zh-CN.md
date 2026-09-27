# 完整 88 维 dlog 形式

完整系统已通过显式有理、可逆基变换 J=T(x,y) I 化为 dJ=(Σ C_a dlog W_a)J，全部 C_a 是精确有理常数矩阵。

字母表共 18 项：x、y、1±x、1±y，以及 x±y^k、1±xy^k（k=1,2,3）。原始系统的五类额外复杂分母已消去。

独立验证覆盖全部 88 行：T 与 T⁻¹ 左右互逆、x/y 两个方向与原生矩阵的 gauge 恒等式、两个方向常数留数重构、7,744 个曲率元素，所有残差精确为零。见 `Full88DLogVerification.json`。原始物理方程池的三点检查在父目录，基变换不改变原始 88 个有限积分的物理覆盖。

- `Full88DLog.wl`：验证过的完整候选，保持字节及哈希不变。
- `T88.wl`、`Tinv88.wl`：显式变换与逆；`NewBasis88.zh-CN.md`：88 项新基的逐项定义。
- `Alphabet.wl`、`ConstantResiduesSparse.wl`、`DLogConnection.wl`：推荐的紧凑 dlog 表示。
- `B_x.wl`、`B_y.wl`：新基下的两张有理矩阵。
- `ComplexityComparison.json`：统一简化方式下的复杂度对比。非零数为 Ax 1163→973、Ay 1147→1012；合并有理表达式规模减少约 76.7%，最高不可约极点幂由 5 降至 1。
- `TopDLogEquation.zh-CN.md`：top 的简洁方程。
- `METHOD.zh-CN.md`：构造步骤及应避免的优化误区。

特别地，J1=(x²−1)(y²−1)^4 I_top，且 dJ1=2 J24 dlog x+4(J2+J3)dlog y。

可以在本目录运行 `WolframKernel -script standalone-verify.wls`，从父目录原矩阵独立重验全部等式；不需要 FiniteFlow 或原生 IBP 池。

已证明的是常数矩阵 dlog 形式，未将其额外称作 ε-form 或 UT 基。联合依赖图无环、最长路径为 9；这给出完整解的有限迭代长度上界，不能直接当作物理积分的均匀权重。后续已完成全部 88 个积分的解析函数和新基边界常数，见 [解析结果](../analytic-88/README.zh-CN.md)。
