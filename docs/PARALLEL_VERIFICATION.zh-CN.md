# 按需关系邻域与并行数值验证

`relationFrontier` 将逐个 master 重扫完整关系池改为一次扫描每条关系的积分支撑，并建立精确邻接集合。局部缺口补点先执行，只有需要广泛中心或局部无新增行时才构建关系邻域。

实际四圈 49,688 行、181 个查询的固定输入测评：新旧结果完全相同，均为 1,034 个邻居；新实现 1.35 秒，旧实现 16.53 秒。该数字只测邻域搜索，不是整个 campaign 的加速比。

`ReduceIntegrals`、`ReduceTargetIntegrals` 和 `RunDE` 新增 `"VerificationWorkers" -> n`，默认 1。`n > 1` 时，用独立 Wolfram 内核分片检验每条选中原始方程在两个数值点上的残差，每个积分列的系数均检查。默认 `"VerificationMode" -> "Numerical"`；仅显式指定 `"Exact"` 才做解析验证。数值通过不标记为解析证明。父进程检查每个分片的源码指纹和完整行索引覆盖，任一分片失败或出现非零残差均不接受约化。幂等性、所选行空间认证及完整池目标正常形对照保持不变。

```wolfram
RunDE[family, top, "Workers" -> 26, "VerificationWorkers" -> 4]
```

`Workers` 控制 IBP 生成，`VerificationWorkers` 控制残差检查，二者分开。每个验证内核需要读取约化规则，内存占用也会增加，故没有默认直接使用全部生成 workers。已有成功约化缓存仍可跳过重复检验；返回的 `ReductionReused` 明确标记这种情况。

测试覆盖正确规则与串行约化逐项相同、全分片覆盖、错误规则产生的非零残差保留、非法 worker 数拒绝，以及无新消息。四圈规模的分片检查另用已保存、已有精确验证证书的关系作复核。

以下为改用两点验证前的历史测评，当前不再执行此解析流程：归档四圈第三轮的 5,929 条方程、8,158 条规则经 4 个内核复核，全部精确残差为零，耗时 310.81 秒；此前串行记录为 720.13 秒。两次共享负载不同，只作工程参考，不声称严格加速比。

## 并行资源建议

推荐 worker 数为逻辑处理器数的 4/5，四舍五入且至少为 1：
`RecommendedWorkerCount[]`，或指定硬件规模 `RecommendedWorkerCount[32]`（返回 26）。
这是资源配置建议，库函数默认值仍为 1，避免小任务和嵌套调用自动创建大量进程。

```wl
n = RecommendedWorkerCount[];
FiniteFlow`FFNThreads = n;
RunDE[family, inputs, "Workers" -> n, "VerificationWorkers" -> n]
```

`Workers` 控制 IBP 撒点，`VerificationWorkers` 控制逐行残差验证（默认两个数值点）；
FiniteFlow 的线程数单独设置。三个阶段通常先后执行，不把线程数相加作为常驻并发数。
多个独立计算同时运行时应共享总配额。本次四圈主计算配额为 26，剩余核心用于轻量诊断；三圈计算已停止。
全局合并、规范化等串行步骤仍由主进程完成，并非全过程都能占满 26 核。

不可约目标的恒等判断改用独立积分列的系数判断，避免对包含大量不同 G 的表达式
计算一个共同分母；不改变 ordering、IBP 行空间或约化结果。

Linux 核数从 `/proc/cpuinfo` 获取，Windows 从 `NUMBER_OF_PROCESSORS` 获取，其他平台回退到 `$ProcessorCount`；也可显式传入硬件核数。某些 Wolfram 运行环境的 `$ProcessorCount` 只报告 1，不可据此认定机器只有单核。本机已独立核验 32 个逻辑核与推荐值 26。
