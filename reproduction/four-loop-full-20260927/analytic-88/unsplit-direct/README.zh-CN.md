# 原始参数表示的独立数值审计

`direct.cpp` 直接从13条传播子的四阶Schwinger矩阵K计算U=det K及F。它不读取任何DE、解析值、边界值或几何sector库。

四维四圈13条一次传播子的原始参数被积式是24 U³/F⁵。源码中的W按外部点顺序记录每个loop相邻的外线参数，内部三条链边给K的Laplacian。由给定的Minkowski外点Gram矩阵，F/U=Σαm²−Σαq²+QᵀK⁻¹Q。`audit-input.py` 在20个固定seed的正参数点，独立核对pySecDec原始U、F多项式；最大相对差约1.4e−14。这个代数检查不等于积分收敛检查。

实现三种完整表示，均为12维：

- 表示0：Cheng–Wu规范固定最后一条内部参数为1，其余α=u/(1−u)，Jacobian为Π(1−u)⁻²。
- 表示1：按最大参数划分13个primary sector，逐一固定最大参数为1、其他α=u²，把13个sector的完整被积函数相加后交给同一个串行Vegas。
- 表示2：同样13个primary sector，改用α=u⁴、Jacobian Π4u³；Vegas用较短初轮获得更多适应迭代。

三种表示都利用被积式的−13次齐次性；后两者仅作初级sector划分，没有使用1492个几何sector。所有Cuba调用串行且CUBACORES=0，避免共享积分器并发。

运行计划依次为：表示0两个seed各maxeval=50,000,000；表示1同两个seed各10,000,000；前两种均未达到精度目标，原始结果全部保留。依据Cuba失败标记和极差的迭代一致性，表示2同两个seed各固定50,000,000，nstart=nincrease=100,000。所有运行的相对目标为1e−4、绝对目标1e−8；不读取参考值，也不根据与参考值的距离停止。Cuba按整轮运行，实际neval可能超过maxeval至下一轮边界。

失败或不收敛的结果不作为DE或解析值的验收证据；只用于独立原始参数表示的审计。

编译链接本机pySecDecContrib的`include/cuba.h`和`lib/libcuba.a`，例如：

```bash
g++ -O3 -std=c++17 -I /path/to/pySecDecContrib/include direct.cpp \
  /path/to/pySecDecContrib/lib/libcuba.a -lm -o direct
CUBACORES=0 ./direct 20260927 50000000 2
```

第三个参数选择表示0/1/2。生成`direct.so`以复查U/F时，再增加`-fPIC -shared`即可。源文件中积分点固定为(x,y)=(1/4,3/4)。
