# 完整88个原生积分的有限 Chen 解析函数

本目录给出积分本身的函数表达式。第1—53项是四圈原生积分，第54—88项是低圈积分；原先要求的83项仍是第1—83项，第84—88项是补齐闭合所增加的5个三圈积分。

所有积分常数已用特殊点边界确定，不再含未知的积分常数。结果采用有限 Chen 迭代积分，可按明确规则转为通常的 Goncharov GPL。最大词长为8，不含未展开的路径有序指数。

## 逐项使用

在 Wolfram Language 中执行：

```wolfram
solution = Get["/absolute/path/to/solution/AnalyticSolution.wl"];

(* 第1项：原生四圈 top ladder 的解析函数 *)
f1 = DCIAnalytic`Integral[1];

(* 代入运动学变量，返回同一个解析函数的特殊函数表达式 *)
f1AtPoint = DCIAnalytic`Integral[1, 1/4, 3/4];

(* 任意原生积分：i=1,...,88 *)
fi = DCIAnalytic`Integral[i];

(* 转为GPL，先保留有限根集合求和，避免表达式膨胀 *)
gpl = DCIAnalytic`ToGPL[fi];

(* 需要时展开这些有限根集合求和 *)
gplExpanded = DCIAnalytic`ExpandGPLRootSums[gpl];
```

`Integral[i,x0,y0]` 返回可继续符号处理的解析式；`GPL` 按下述数学定义使用。数值求值可接常规 GPL 求值器。`AnalyticSolution.wl` 会自动读取同目录的两个函数文件，变量显式使用 `DCIAnalytic` 上下文，避免与其他软件包的 x、y 同名符号混淆。

- `NativeFunctions88.wl`：全部88个原生积分的解析函数列表，可直接按索引读取。
- `CanonicalFunctionsExplicit88.wl`：全部88个 dlog 基函数。
- `TopLadderFunctionExplicit.wl`：单独的四圈 top 函数。
- `CanonicalToNative88.wl`：精确有理逆变换。
- `All88ChenTriples.wl`：13108个不同双词及其稀疏系数向量。

第1项尤其简单地满足

    I1(x,y) = J1(x,y) / [(x²−1)(y²−1)^4].

J1 的实际非零双词有3084项。全部88个 canonical 分量合计62140项；有理边界代入精确消去了通用解的69679项。

## 路径、词方向与 GPL 定义

初始实区域为

    0 < x < y³ < 1.

路径为先沿 y=1 从 x=1 到 x，再固定 x 从 y=1 到 y。词采用“最外层在前”的顺序：

    C({},z)=1,
    C({a,w},z)=Integral_1^z dlog(P_a(t)) C(w,t).

X 字母依次为 `{x,1-x,1+x}`。Y 字母依次为

    {1-y, y, 1+y, y-x, x+y, 1-xy, 1+xy,
     y²-x, x+y², 1-xy², 1+xy²,
     y³-x, x+y³, 1-xy³, 1+xy³}.

Y 段中 x 固定。对象中的整数词是这两个列表的1起始索引。

通常的 GPL 定义为

    G({},z)=1,
    G({a,w},z)=Integral_0^z dt/(t-a) G(w,t).

若 P(t) 的根为 r（本区域均为单根），则

    dlog P(t) = sum_r dt/(t-r).

再令 u=1-t，即把该字母换成 GPL 字母集合 `{1-r}`，终点变为 `1-x` 或 `1-y`。X 的三个单字母因此是 `{1,0,2}`；二次、三次 Y 字母按完整根集合进行有限求和。`ToGPL` 保存的 `GPLRootSum` 精确表示这些有限笛卡尔积求和，`ExpandGPLRootSums` 仅负责把它们展开。所有15个 Y 核的转换已用符号有理恒等式逐一验证。

## 特殊点、普通收敛与分支

canonical 边界并未直接取成原生积分在(1,1)的数值。它来自完整有理逆变换在 generic ray 上的 Laurent 展开、canonical Frobenius 递推、原生负阶项消除及全部88个已知原生边界值。root 的纯有理约束系统共有704行、秩88，给出唯一的正则 canonical 常数向量，所有方程残差精确为零。

函数中只出现 Pi、Log[2]、Zeta[3]、PolyLog[4,1/2]。四圈共同特殊点常数已经代入：

    B4 = Li4(1/2) + log(2)^4/24 − pi^4/720
         + pi²[3−6log(2)+2log(2)^2]/24 + 7zeta(3)/8 − 5/4.

已精确检查：初始 x 段的 x=1 留数湮灭边界；y=1 留数湮灭整条初始 x 解的每个系数；在(1,1)消失的8个字母，其单独留数也全部湮灭该边界。

因此，所有剩余非零 Chen 项的最内字母都避开基点奇性，逐项是普通收敛积分。没有在计算中静默把发散的端点积分指定为某个正则化常数。沿任意避开切向奇面的 generic ray，非空双词均趋于零：非空 X 词给出至少一个小参数因子；X 词为空时，纯 coalescing Y 词的系数为零，剩余词至少有一个不随角点消失的核，同样给出小参数因子。所以折线路径解回到同一 canonical 常数向量。

本文件给出的实区域内两个段都不穿过其他字母的零点。区域外的值由同一分支做一致解析延拓。

## 解析式的验证链

1. 完整88维原生DE的有理变换、常数留数 dlog 分解及符号曲率均已精确验证。
2. canonical 边界通过有理约束唯一确定，原生全部88个特殊点值同时匹配。
3. 有限词系数直接由常数留数矩阵相乘构造；实际第9层全部为零，最大词长8。
4. 196671条独立系数递推精确检查全通过：全部 y 方程、初始 x 方程、边界系数以及终止层均匹配。
5. 由精确平坦性，x 方程的残差满足齐次 y 方程；其 y=1 正则边界为零，故残差恒等于零。这避免把关于参数字母的繁复 GPL 求导误当作独立假设。
6. 原生解析函数由已精确验证的 T^-1 作用到上述函数得到。一圈第80—83项另行精确复现其已知对数公式。

上述检查记录于 `ChenRecurrenceCertificate.json`、`BoundaryPathReport.json`、`LoaderAndGPLAudit.json`。原生物理分支与 canonical 正则性之间的独立论证已经完成，并由独立的前向 Taylor 路线与全局逆向路线逐项精确核对；两条一般射线给出相同的88项边界。证明见 `../boundary/BoundaryRegularityProof.zh-CN.md`，证书见 `../boundary/IndependentBoundaryCrossCheck.json` 与 `../BoundaryRayComparison.json`。因此全部53个四圈及35个低圈原生积分的解析函数均已确定，无未知积分常数。

四圈top在一般点的直接积分比较单独记录：最终采用全部sector先求和再统一Vegas积分，两个事先固定seed均通过0.1%统计精度检查，见 `../numerical/FinalDirectValidation.json`。旧QMC及不适合验收的配置仍全部保留；没有用任何直接数值拟合解析常数。

## 已记录的后续结构约化线索

只有 canonical J83 恒等于零：其两个DE行都为零，而真实边界常数为零。这给出涉及14个原生低圈积分的显式有理关系，见 `PhysicalZeroRelation83.zh-CN.md/.wl`。该关系已从解析DE与物理边界证明，但尚未声称由旧原生IBP池导出。它提示一个87维 physical quotient 候选；当前冻结的88维系统保持不变。


## 构造脚本与复核

本目录补充了可在 package 内定位输入的 ladder 构造脚本。`prepare-residues.wls` 从冻结 dlog 连接导出路径留数；`iterate-all-formal.py` 枚举有限词；`substitute-boundary.py` 代入精确常数；`export-native-functions.wls` 导出原生函数。`path-regularity-constraints.wls` 和 `validate-boundary-path.wls` 检查边界路径；`check-chen-recurrence.py` 独立重验全部 196,671 条系数递推。

构造脚本会重写同目录的派生文件，完整重建请先复制本案例目录。`All88FormalChen.jsonl.gz` 是可由枚举脚本生成的中间文件，未上传。最终的 `All88PhysicalBoundaryChen.jsonl.gz`、函数和边界均已提供。父目录 `global-boundary.wls` 可从冻结逆变换与原生边界重建射线约束；物理正则性证明另见 `boundary/BoundaryRegularityProof.zh-CN.md`。这些是 ladder 专用配方，新拓扑须重算字母、终止阶数和边界。
