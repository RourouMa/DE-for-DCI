# 显式 Chen 解析函数的独立数值求值

这里直接计算 `solution/All88PhysicalBoundaryChen.jsonl.gz` 中已经给出的有限解析表达式，在 (x,y)=(1/4,3/4) 对全部88个分量求值。共使用62140个非零表达式项，top对应3084项，最大词长8。求值程序没有使用任何88×88微分方程矩阵。

采用两段路径的局部变量 u=1−x、v=1−y，其目标点分别是3/4、1/4。x段字母多项式是1−u、u、2−u；y段字母从独立的 `ScalarChenAlphabet.json` 读入并代入x=1/4、y=1−v。该标量输入文件没有DE矩阵；求值器也断言Rx、Ry、Bx、By、Matrices等字段全部不存在。程序运行时只读取显式word文件、标量字母文件和有理逆基变换点值，完全不读取DE矩阵文件。

对word=(a,suffix)和相应字母多项式P，直接使用迭代积分定义

P F_word' = P' F_suffix，F_word(0)=0。

若P=p0+p1 u+…且p0≠0，幂级数系数满足

f_n = (1/n) Σ_(k=1)^deg(P) (p_k/p0) [k g_(n−k)−(n−k) f_(n−k)]。

这里g是suffix的系数，越界系数为0。若P=u，则f_n=g_n/n；程序精确拒绝会导致内端发散的g0≠0情形。物理边界代入后的词集合已经不存在这类最内端奇异词。多项式最高3次，所以每个词的计算复杂度为O(N deg(P))，全部后缀只计算一次。

`evaluate_chen_series.py` 分别以240/320/400/480阶和80/100/120/140位目标算术精度求值。每次实际加15位保护精度。先直接累加全部canonical表达式，再使用独立导出的有理逆基变换点值恢复88个原生积分；top另外核对简单归一化。四个一圈函数还与原生闭式单独比较。

结果见 `ExplicitChenNumericalValidation.json`：

- top相邻截断阶差依次为约2.00×10⁻³¹、2.15×10⁻⁴¹、2.19×10⁻⁵¹；
- 最佳top值约为1.2949774454346312026756864422914142929288329003802768566657；
- 全部88个原生值与独立DE求值的最大差约4.32×10⁻⁴⁹，满足此前保守40位精度声明；
- 四个一圈原生闭式的最大差约9.44×10⁻⁶³。

各次完整结果保存在 `ChenEvaluation-N*-P*.json`，运行时还会生成 `WordValues-N*-P*.jsonl.gz` 逐词缓存，可按需重建。截断阶间的符合用于数值收敛检查，所请求的算术精度本身不是误差界。本结果独立检验了显式解析表达式的路径和求值；原始四圈参数积分的直接数值比较另行记录。

复现环境：Python 3，依赖 mpmath 和 sympy，系数递推使用标准库 decimal。运行例如 `python3 evaluate_chen_series.py 400 120`，再运行 `python3 compare_evaluations.py` 汇总四档结果。`NativeInverseAtPoint.json` 已包含所需精确有理点值；如需重建，可用 Mathematica 运行 `export-inverse-point.wls`。
