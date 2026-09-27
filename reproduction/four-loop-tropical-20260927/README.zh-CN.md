# 四圈 ladder 的 tropical 数值试跑

本目录保存有限参数积分的图映射、精确审计、固定预算试跑和原始输出。它验证新数值后端的接入，没有将 tropical 试跑当作已达到 0.1% 的最终 Top 验证。

`prepare_and_audit.py` 独立枚举生成树和二森林，精确对比 pySecDec 从原始动量传播子构造的 U/F，并核对 Gamma 归一化。Top 与一圈的原生指标还分别对照完整基的 I1、I83。四个输入均通过；F 的非零系数均为正。需要 Python、sympy、pySecDec；可在本目录运行：

```sh
python3 prepare_and_audit.py
python3 compare_pilots.py
```

第二步另需 mpmath，只在采样完成后读取解析参考。完整统计结果见 `PilotComparison.json`。

| 输入 | 每种子样本数 | 种子 | 估计值 ± 报告误差 | 报告相对标准误差 |
|---|---:|---:|---|---|
| Top (1/4,3/4) | 10,000,000 | 141421 | 1.29882803 ± 0.02273770 | 1.75% |
| Top (1/4,3/4) | 10,000,000 | 17320508 | 1.27901619 ± 0.01542920 | 1.21% |
| 合并分母后的边界 | 10,000,000 | 316227 | 0.11211827 ± 0.00011973 | 0.107% |
| 合并分母后的边界 | 10,000,000 | 331662 | 0.11233856 ± 0.00012059 | 0.107% |

所有试跑与各自解析参考的差异小于三个报告误差。Top 未达到 0.1%，合并边界也略高于 0.1%。这不足以证明 tropical 比已有完整和 Vegas 更高效。边界合并相同分母后由 13 条边、12 维参数积分变成 9 条边、8 维积分；本例同预算耗时约 12 秒降至 5 秒，报告误差也变小。

后端将这些点标为 exceptional Minkowski，并给出警告及 generalized permutahedron 检查信息；原日志全部保留。无丢弃采样点警告。历史报告的 `Threads` 是请求线程上限，`PilotComparison.json` 从日志提取实际线程数；部分小样本旧运行实际为单线程。新通用接口固定 `OMP_DYNAMIC=FALSE` 并同时记录两者。

`Dependency.json` 固定外部 feyntrop 修订版本。源码/编译产物不包含于本目录。后续使用 [通用接口](../../Adapters/TropicalMonteCarlo.zh-CN.md)；`run_feyntrop.py top NEW_OUTPUT ...` 是四个已审计 ladder 输入的便捷包装。包含分子的积分需另行构造有限参数表示，见 `IntegralRouting88.json`。

已通过 0.1% 的 Top 独立验证仍见 [FinalDirectValidation.json](../four-loop-full-20260927/analytic-88/numerical/FinalDirectValidation.json)。
