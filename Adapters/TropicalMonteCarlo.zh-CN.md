# Tropical Monte Carlo 接口

`TropicalMonteCarlo.py` 接收 [feyntrop 官方低层图格式](https://github.com/michibo/feyntrop)，与 ladder 拓扑解耦。方法参考 [Borinsky、Munch、Tellander 的论文](https://arxiv.org/abs/2302.08955)。外部源码固定于 `ad0d683274977836f5c2ab3e71496ba307413d63`，不随本包复制二进制。

从 package 根目录安装（需要 git、make 和支持 OpenMP 的 C++ 编译器）：

```sh
python3 scripts/install-feyntrop.py
```

在一个全新的目录保存一次固定预算计算：

```sh
python3 Adapters/TropicalMonteCarlo.py \
  reproduction/four-loop-tropical-20260927/top-input.json \
  runs/tropical-top-seed141421 \
  --executable external-tools/feyntrop/feyntrop \
  --samples 10000000 --seed 141421 --threads 2 --relative-error 0.001
```

新拓扑只替换第一个图 JSON。`FEYNTROP_EXECUTABLE` 可代替 `--executable`。输出目录必须不存在，防止覆盖；采样前就记录预算、种子、输入与二进制哈希。输出为 `input.json`、`Report.json`、原始 `stdout.json` 与 `stderr.txt`。

feyntrop 低层输出缺少整体 Gamma 因子。本接口对有限首项乘以 `Gamma(sum(nu)−L D/2)/product Gamma(nu)`，采用本项目的正传播子归一化；额外的测度因子、外部前因子或其他符号约定必须由调用方明确换算。输入支持连通图、正传播子幂和 `num_eps_terms=1`。图映射、子图有限性及参数多项式的正确性由外部审计负责，整体 Gamma 有限不能证明所有子图有限。

`UsableSampleRun` 仅表示运行完成且未报告丢弃采样点；`PrecisionTargetReached` 才表示报告统计误差达到了指定阈值。后者也不替代独立种子、参数稳定性和解析比较。退出码 0 不等于物理结果认证。保留后端的运动学警告；不要将有限性理解成所有采样方差都小。

设置 `OMP_DYNAMIC=FALSE`，保存 `Threads`（请求数）及 `ActualThreads`（后端日志）。固定线程数对于复现随机流很重要。每次运行独立进程；采样不读取解析参考值。

用以下命令复核接口及一圈已知函数：

```sh
python3 Tests/TropicalMonteCarlo.py --executable external-tools/feyntrop/feyntrop
```

[ladder 试跑与精确输入审计](../reproduction/four-loop-tropical-20260927/README.zh-CN.md) 包含合并边界分母的实例。其 Top 试跑尚未达到 0.1% 精度；现有完整 sector 和 Vegas 结果仍是已经通过该门槛的独立验证。
