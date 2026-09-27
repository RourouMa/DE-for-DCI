# 直接积分的并发配置审计

## 结论范围

当前pySecDec 1.6.3生成的sum-package把同一积分器对象共享给多个sector。`number_of_threads>1`会使这些sector同时修改共享状态。对Vegas已经用完全独立于DE的常函数实验复现错误；对QMC确认了共享可变状态风险，但尚未用独立已知积分复现其数值偏差。

因此先前设置amplitude `number_of_threads=4/8` 的直接积分不作为当前验收依据。它们的原始数值、误差、参数和日志全部保留，不因结果不一致而删除。新的对照使用 `number_of_threads=1`；QMC仅在单个sector内部用 `cputhreads=4` 并行，Cuba对照用 `CUBACORES=0` 及单amplitude线程。

## 实际代码链

本机安装目录为 `/home/april/.local/lib/python3.10/site-packages/pySecDecContrib/include/`。

1. 生成库 `four_top_p1/src/four_top_p1_integral_weighted_integral.cpp` 在 `make_integral` 内创建一个 `shared_ptr<amplitude_integrator_t>`，随后所有 `convert_integrands` 实例捕获同一个指针。
2. `secdecutil/amplitude.hpp` 的 `evaluate_integrals` 根据 `number_of_threads` 建立线程池，多个sector可同时调用 `compute_impl`。
3. `CubaIntegral::compute_impl` 修改共享积分器的 `statefiledir`、采样预算；`integrators/cuba.hpp` 的 `CUBA_INTEGRATE_BODY` 又将共享成员 `typed_userdata.integrand_container` 设为当前sector地址。另一个sector线程可覆盖这个地址及共享积分结果数组。
4. QMC路径共享 `minn`、`maxeval` 和 `qmc.hpp` 中的 `randomgenerator`。该路径未发现对应锁或每sector独立复制，但此审计尚不能量化具体旧QMC结果偏差。
5. `pylink_amplitude.hpp` 虽接收 `together` 参数，实际构造sum-package amplitude时未用该参数改变sector调度，因此Python调用的默认 `together=True` 不能消除此问题。

误差合并使用 `UncorrelatedDeviation` 的方差相加。在共享状态并发已不正确的情况下，较小的报告误差不能修复实际积分值。

## 与DE无关的最小重现

源文件：`reproduce-shared-vegas.cpp`。

在单位二维方形上分别积分常函数1和3，精确结果是1与3，总和4。同一个Vegas对象先串行，再由两个线程并行调用。每次都用固定seed和100000个采样点，与任何四圈积分或DE数值无关。

编译命令：

```bash
g++ -O2 -std=c++17 \
  -I/home/april/.local/lib/python3.10/site-packages/pySecDecContrib/include \
  four-loop-dlog-analytic-20260927/numerical/reproduce-shared-vegas.cpp \
  -L/home/april/.local/lib/python3.10/site-packages/pySecDecContrib/lib \
  -lcuba -lm -pthread \
  -o four-loop-dlog-analytic-20260927/numerical/reproduce-shared-vegas
```

运行命令：

```bash
CUBACORES=0 taskset -c 31 timeout 20s \
  four-loop-dlog-analytic-20260927/numerical/reproduce-shared-vegas
CUBACORES=0 taskset -c 26,31 timeout 20s \
  four-loop-dlog-analytic-20260927/numerical/reproduce-shared-vegas
```

两次串行都得到总和 `4.0000000000031628`。第一次5次并行中一次得到 `3.9400000000027693`；第二次5次并行中分别出现 `1.9999999999961675` 和 `3.9600000000029008`。所有10次结果（包括碰巧正确的结果）都在两个原始日志中：`reproduce-shared-vegas.log` 与 `reproduce-shared-vegas-two-cores.log`。这足以证明该共享Vegas并发调用方式不能作为可靠积分方式。

## 对照与预算

`direct-serial.py` 的所有计划在运行前写入对应JSON；使用固定seed、固定精度目标和固定最大采样/时间，不读取DE或解析参考值，不以接近某个答案为停止条件。

旧高预算QMC按原定时间结束；`direct-deadline-watch.py` 在配置wall-clock之外最多增加60秒关闭余量，且只操作登记过的本任务PID。若库的首轮全部sector计算超过内部时间限制，外部watcher写明超时并结束任务。不得把超时或并发不可靠的结果解释为验证通过。

## 旧边界直接积分同样受影响

`four-loop-analytic-20260927/integrate-boundary-numerical.py` 也设置 `number_of_threads=4`，因此此前两次四圈 `(1,1)` 边界QMC即使与精确B4落在报告误差内，也不能继续作为独立验收或归一化证据。它们的原始输出仍保留并标记并发配置风险。精确B4的依据是另外的径向积分、谱展开及解析推导（这些相互核对约90位），并不依赖这两个QMC结果。

## 串行 Vegas 的另一项统计问题：跨 sector 重复 seed

串行调用排除了共享对象被同时覆盖，但还不能证明 sector 误差互不相关。`integrators/cuba.hpp` 每次向 `llVegas` 传入不变的 `seed`；不同 sector 的首次积分会重复随机序列。生成 amplitude 最后使用 `UncorrelatedDeviation` 合并误差，没有包含这些协方差。

`reproduce-vegas-seed-correlation.cpp` 用已知函数 `x^(-0.3) exp(y)` 独立重现这一点：同一个 Vegas 对象串行积分两次，返回完全一样的值 `2.4582531462481167` 与误差 `0.0044119215144239913`。按不相关误差相加为 `0.0062393992418240535`；单次积分两倍函数给出同一总值，但误差为 `0.0088238430288479826`，恰大 `sqrt(2)`。原始 JSON 保留在 `VegasSeedCorrelation.json`。编译参数与上述常函数实验相同，仅替换源文件与输出文件名。

这证明重复 seed 时“无相关性”假设可能错误，但尚未量化实际 1492 个不相同 sector 的协方差，不能直接将实际误差统一乘上 `sqrt(1492)`。串行主点 Vegas 得到 `1.29652372447698716 ± 0.0000927472216725`，仍与 DE 不符；它没有并发覆盖问题，却也不能据原报告误差直接作显著性判断。并发错误不能解释所有尚存差异。

QMC 的串行路径使用连续推进的共享随机数发生器，不是每个 sector 固定 seed 从头运行。其随机误差仍需独立种子及收敛检验。

## 单次积分全部 sector 的总和

`direct-total-sum.cpp` 直接调用已编译原积分库的 `four_top_p1_integral::make_integrands({}, {})`，得到 1492 个 epsilon 零次被积函数，组成一个 12 维函数 `24 * sum_sector f_sector(x)`。在每一个采样点先求总和，再只调用一次 QMC 或 Vegas；这样总量误差由该单次积分直接估计，不再依赖 sector 间误差独立的假设。1492 个 sector、12 维及 prefactor 24 都由实际库读取。

编译命令：

```bash
g++ -O2 -std=c++17 \
  -I/home/april/.local/lib/python3.10/site-packages/pySecDecContrib/include \
  -Ifour-loop-analytic-20260927/numerical-work/four_top_p1/four_top_p1_integral \
  four-loop-dlog-analytic-20260927/numerical/direct-total-sum.cpp \
  four-loop-analytic-20260927/numerical-work/four_top_p1/four_top_p1_integral/libfour_top_p1_integral.a \
  -L/home/april/.local/lib/python3.10/site-packages/pySecDecContrib/lib \
  -lcuba -lgsl -lgslcblas -lgmp -lm -pthread \
  -o four-loop-dlog-analytic-20260927/numerical/direct-total-sum
```

`run-total-sum.py` 在调用前保存方法、seed、最多100000次总函数评估、600秒上限及0.1%请求精度，不读取任何 DE 或解析数值。全部 stdout/stderr 和超时状态保留；这些总和实验是否收敛需根据实际返回结果报告。

单次总和的粗预算结果全部保留：100000次总函数预算下，Vegas为 `1.29763760075 ± 0.00271724144`，与DE相容但未达0.1%目标；QMC为 `1.41548776492 ± 0.13039812625`，方差过大。后续预先声明两个不同seed（141421、17320508）各1M最低及最高总函数预算、900秒上限的Vegas运行，每次仅单一总函数调用，Cuba内部fork2进程。`direct-total-sum-vegas-v2.cpp` 直接记录实际采样次数、Cuba返回fail标记及chi-square probability。`run-total-sum-refined.py` 保存运行前的计划和源程序/二进制hash，超时时结束其独立进程组。比较标准在 `final-direct-comparison.py` 中明确；所有粗预算和失败路线仍保留。
