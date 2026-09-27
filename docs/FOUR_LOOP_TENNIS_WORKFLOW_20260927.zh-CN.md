# 四圈 tennis court：复用流程与验收标准

本次同步将三圈选基经验、四圈 ladder 完整闭合、dlog 化简、边界与解析函数、数值并发修复和 tropical 接口整合到 0.6.0。已完成的四圈结果属于 ladder；新的 tennis court 拓扑须从其真实 Top 定义和物理关系池开始计算。

## 1. 定义与有限覆盖

固定 Top 指标、传播子顺序、对称群、运动学和积分归一化，生成该拓扑的 IBP/symmetry。使用 [四圈配置](../Examples/four-loop-physical-closure-policy.wl) 和 `RunPhysicalCoordinateDE`；参见 [物理行坐标接口](PHYSICAL_ROW_COORDINATES.zh-CN.md)。最高圈的工作上限为 70，超过时修复关系，不能截断基冒充闭合。

优先单积分，其次短常系数组合。所选有限代表的分母正幂必须满足 `Xa Yi ≤ 3`、`Yi Yj ≤ 2`；这个限制不删除物理方程或求导目标。逐项检查有限性，负幂分子必须完整保留。

浮动量使用 `(覆盖项数−实际联合秩)/实际联合秩`。三圈有效历史最大值为 1，其 150% 为 3/2，所以当前配置的最宽允许值为 `floor((1+3/2) rank)`；这是异常轮次的容忍上限，选择时仍尽量贴近秩。不能解释成多留固定数量，也不能解释成每轮都选满上限。定标数据见 [比例校准](THREE_LOOP_COVER_SLACK_0.6.0.json)。

同一方向链累计增加至少三次，就停止接受该方向的新轮次，扩大 IBP/symmetry 或加入有证明的新物理关系，然后从 Top 重放。保存链历史及修复前后池哈希。闭合后再做结构约化，同时比较两个 DE 矩阵的非零数、极点阶数和表达式规模；三圈经验表明更少覆盖项可能造成更复杂矩阵，见 [选基经验](FINITE_COVER_COMPLEXITY_LESSONS.zh-CN.md)。

## 2. 完整含源闭合

最高圈闭合后递归处理全部低圈源。未映射源保留为未知列；源间关系也必须保留。旧基可提供坐标参考，旧 DE 不作为新物理关系。先在完整池中重新求导，再重构有理矩阵。

ladder 的完整系统为 `53+24+7+4=88`，后加的五个方向均为三圈。这个计数不能直接用于 tennis。新结果至少在三个独立非奇异点核对原生求导、Top 坐标和所有源，并对完整有理矩阵做精确曲率检查。IBP 接触项的物理有效性另行核验；ladder 的审计结论不能自动覆盖新拓扑的 whole/coupled 向量场。

## 3. dlog 化简

从 x、y 两张矩阵的联合依赖图分块；使用可逆有理变换 `J=T I`。源项剪切必须包含完整双侧反馈：

`Q_new = Q + B_high R − dR − R B_low`。

按高圈行依赖顺序、低圈列反向依赖顺序处理。不能只优化高圈齐次块，也不能用秩不足的旧映射充当可逆变换。详细推导见 [ladder 方法记录](../reproduction/four-loop-full-20260927/dlog/METHOD.zh-CN.md)。

可复用的精确工具在 [Adapters/DLogTools.wl](../Adapters/DLogTools.wl)：

```wl
Get["Adapters/DLogTools.wl"];
decomposition = ConformalIBPDLog`FindConstantDLog[Bx, By, letters, {x,y}];
certificate = ConformalIBPDLog`VerifyGauge[Ax, Ay, T, Tinv, Bx, By, letters, {x,y}];
```

拟合使用常数有理采样矩阵，随后必须完整符号重构。`VerifyGauge` 检查左右逆、两个 gauge 恒等式、曲率和常数留数。`RationalPrimitivePart[f,z]` 提供单变量 Hermite 有理部分；它不是自动求解整个 gauge 的算法。ladder 的 18 字母、有限词长及简洁 Top 方程均须在 tennis 上重新判断，不预设 ε-form 或 UT 性质。

## 4. 边界与解析函数

选择原生积分正则、可独立计算的特殊点，先求原生边界，再经 Laurent/Frobenius 约束确定 canonical 常数；不能把原生边界直接当作 canonical 边界。至少用两条非切向射线交叉核对，检查约束矩阵满秩、全部精确残差和物理正则性。

只有积分定义在特殊点确实相同，才能复用 ladder 的 B4 常数。有限 Chen 展开须检查留数作用的实际终止和所有系数递推，注明积分路径、分支、初始区域。ladder 的 [88 个解析函数及加载器](../reproduction/four-loop-full-20260927/analytic-88/solution/README.zh-CN.md) 和 [独立 Chen 数值求值器](../reproduction/four-loop-full-20260927/analytic-88/chen-evaluation/README.zh-CN.md) 可作为完整实例。

## 5. Tropical 数值验证

优先试用 [通用 tropical 接口](../Adapters/TropicalMonteCarlo.py)，安装与示例见 [数值接口说明](../Adapters/TropicalMonteCarlo.zh-CN.md)。从真实积分独立构造动量图，精确比较 U/F、传播子幂次和 Gamma 归一化后再采样。特殊点上完全相同的分母应先合并；ladder 边界的参数维数因此从 12 降至 8，试跑时间和方差均改善。

当前接口支持有限的正幂标量图首项。ladder 88 项中 37 项含分子、51 项只有非负传播子指标；这只是 [初筛](../reproduction/four-loop-tropical-20260927/IntegralRouting88.json)，不是 51 项全部可直接输入的证明。分子须另行推导有限参数表示，乘积积分须拆分连通分量。

固定样本预算、至少两个独立种子，保留实际线程数、误差、警告和原始输出。采样器不读取解析值；比较在采样完成后进行。tropical 的 ladder Top 试跑每种子一千万点仍只有约 1–2% 报告误差，尚未达到 0.1%；不能替代已经通过 0.1% 检查的完整 sector 和单次 Vegas 验证。

采用 pySecDec 回退时，把所有 sector 逐点求和作为一个被积函数，避免共享可变积分器和把同种子相关 sector 误差按独立误差合成。并发可按独立积分、独立种子或经过线程审计的后端分配；边界确定不依赖数值拟合。

## 6. 保存与发布

每轮保存覆盖数、实际秩、方向链、源列状态、幂次审计和池哈希。最终保存原生基、两张矩阵、可逆变换、字母/留数、解析函数、边界及独立验证报告。大型关系池、缓存、编译产物和临时高精度数据留在本地；GitHub 中保留可读取的最终结果和复核脚本。新计算使用独立输出目录，避免覆盖已认证的 ladder 文件。
