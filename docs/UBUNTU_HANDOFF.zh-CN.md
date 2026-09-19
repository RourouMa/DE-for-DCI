# 四圈 ladder 闭合计算：Ubuntu 迁移与工作交接

核对日期：2026-09-20。本说明依据本机文件、仓库源码和已保存的审计记录整理；本次没有重新求解百万规模矩阵。

## 1. 新会话首先做什么

**请使用私有 GitHub 仓库 [RourouMa/DE-for-DCI](https://github.com/RourouMa/DE-for-DCI) 中的 ConformalIBP package 作为后续开发和迭代的入口。** 不要重新写一套固定四圈的临时程序，也不要把旧对话中的某个 MI 数字直接当成当前闭合基底。

已发布计算代码的基准提交为 `15513175ffc68505af537c898ee7e7ddd1e06a2e`，版本为 `0.1.0`。本交接文档是后续文档补充。先阅读仓库的 `README.md`、`docs/ALGORITHM.md`、`docs/VALIDATION.md` 和本文件，并记录实际 checkout 的提交号。

最终任务是：对四圈 ladder 的 Top 积分建立经过验证的有限积分微分方程系统。优先检查同圈 G4 块的闭合，但必须保留、单独报告 G3 等低圈源项。**G4 商空间闭合不等于包括低圈项的完整物理系统闭合。**

目前四圈闭合尚未确认。不要预设最终 MI 个数，也不要因为计数稳定或没有裸发散项就宣布闭合。

## 2. 两套计算状态必须分开

### A. GitHub 上的新 package

这是从既有经验提炼出的可变圈数实现，不是旧大型计算目录的完整镜像。

- 支持四维 embedding-space scalar-product conformal families、整数指标和单位 delta 指标。
- 接口：`CreateFamily`、`LadderFamily`、`GenerateOperators`、`GenerateSeeds`、`GenerateSystem`、`RunReduction`、`RunDE`、`ResumeRun`。
- 自动执行 degree 配对、IBP 和 symmetry、历史重约化、完整组合求导、常系数有限组合构造及输入空间闭合检查。
- 可选 FiniteFlow；IBP 生成支持四个独立 Wolfram kernel，不使用内置 `Parallel*`。
- 已记录通过：29 项核心测试、四 kernel 与串行一致性、FiniteFlow 与精确消元一致性、42 项原四圈算符作用对照。
- 一圈 box 已自动闭合到 4 个有限积分，并通过精确 flatness 检查。
- 不导入现成约化规则，即可自动得到

```wolfram
G[-2,2,4,0,1] -> (1+x^2+x^4)/(3*x^2) G[0,0,2,2,1]
```

新 package 的额外四圈开发测试只完成了第一批 496 条关系的扩充，随后较重的扩充在发布准备时被停止。**496 不是旧四圈系统的规模，更不是完整关系集。** 新 package 尚未完成三圈、四圈整体闭合回归。

尚未实现：低圈源项的自动递归闭合、一般 protected-propagator syzygy 求解、重叠/更大碰撞簇的通用有限性证明、旧原生大矩阵流水线的完整移植。现有 Mathematica 枚举和精确验证在大规模时可能成为瓶颈，大电脑上的内存与耗时需要实测。

### B. Mac 上旧的生产计算档案

本次核对的续算基线是 `closure_campaign/ordering01`，其后有 `ordering01/query01` 的规则补导出。旧记录主要在 **G4 quotient** 中计算。

`ordering01/RESULTS.md` 记录的矩阵为 2,833,280 行、2,850,483 列；88 个历史 target 文件、2,045 个不同 target 已重约化；7,789 个旧规则残差检查为零。这些数量不是 MI 个数。

从 Top 重跑的已记录结果如下。第一轮指对 Top 求导并约化，后一轮的输入来自前一轮有限化结果。

| 轮次 | 输入数 | 实际 DE targets | 约化后 raw G4 | 单独有限 | 常系数组合 | 下一轮输入 | factorized 单独有限 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 1 | 11 | 5 | 3 | 1 | 4 | 0 |
| 2 | 4 | 48 | 19 | 7 | 5 | 12 | 0 |
| 3 | 12 | 129 | 50 | 13 | 13 | 26 | 0 |
| 4 | 26 | 255 | 130 | 34 | 32 | 66 | 5 |

即 `1 -> 4 -> 12 -> 26 -> 66`。第四轮 32 个组合均通过所实现的孤立 double-pole residue admission 检查；记录明确说这不是所有收敛区域的完整证明。该分支前四轮的有限化没有裸发散输入。66 个元素仍不是已确认闭合的 MI。

对这 66 个元素的下一步求导已经保存：132 条导数表达式、682 个实际 targets；输入展开含 98 个 raw G4，targets 最小指标为 -2。**98 是展开支持数，不是 66 之外新增的主积分数。**

#### 必须更新旧报告中的停点

`ordering01/RESULTS.md` 仍写第五轮缺 85 条 requested rules，但时间更后的 `ordering01/query01/CompositionChecks.wl` 记录：

```text
OldRawRulesPreserved = True
NewRawRules = 85
TotalRawRules = 8080
RemainingUnexportedRequired = 0
CurrentComplexIdentities = 18
```

`query01/SolveSummary.wl` 另记录求解了 81 个 canonical queries。85 个 raw 导出与 81 个 canonical queries 不是矛盾。**不要重新把这 85 个导出缺口当成待撒点问题。** 应先核验最新规则与全部 682 个 targets 的覆盖、旧规则一致性及实际 RHS，再继续有限化和下一轮闭合检查。本次核对未发现该 `from_top/round5` 中已完成的新有限基底；该目录只有缺规则旧记录和导数文件。

`query01` 尚有 18 个复杂自约化候选：在矩阵内不代表真正约掉，需结合实际 DE 支持逐项检查。不要把 `IBP4TempMI.txt` 的整套全局代表元全部塞入下一轮输入。

另一个 `expanded14` 分支的候选数为 65，但有一个组合未通过 admission，不能为了个数较小选它继续求导。旧冻结 116 个元素的秩为 90，也不是新一轮有限基底个数。

## 3. Family 和微分约定

外点位置：X1 左，X2 上，X3 右，X4 下。不得再差一个循环置换。

完整指标顺序为：

- 1–4：`SP[X1,Y1]` 到 `SP[X4,Y1]`。
- 5–8、9–12、13–16：同样顺序分别对应 Y2、Y3、Y4。
- 17–22：`SP[Y1,Y2]`、`SP[Y2,Y3]`、`SP[Y3,Y4]`、`SP[Y1,Y3]`、`SP[Y1,Y4]`、`SP[Y2,Y4]`。
- 23–26：四个 `SP[Yi,Yi]` delta 槽，指标均为 1。

Top 为：

```wolfram
G[1,1,0,1, 0,1,0,1, 0,1,0,1, 0,1,1,1,
  1,1,1,0,0,0, 1,1,1,1]
```

这是 **13 个分母传播子 + 4 个 delta**，不是完整 26 个槽都在分母。ISP 槽保留，分子用负指标表示。默认禁止 ISP 正指标；增加 supersector 时只允许明确声明的分母范围，不得隐式把 loop-loop ISP 升为分母。保留 `n17,n18,n19 <= 2`，不得自行扩大到 3。

外部 Gram 数据在 `Examples/kinematics.wl`：

```text
X1² = X3² = 2x; X2² = X4² = 2y
X1.X3 = 1+x²; X2.X4 = 1+y²
相邻外点点积为 0
```

微分包括两部分：G 的外向量形变，以及系数函数的普通导数。package 使用 `C_z = (d Gram/dz).Inverse[Gram]/2`；对 `c(x,y) G` 必须计算 `(d c/dz) G + c D_z G`。对有限组合先整体求导、合并化简，再收集不为零的实际 targets。

## 4. 不得改变的计算规则

1. **算符和 seed 严格配对。** 四圈 delta-tangent rotations 为 84 个、11 类 degree；外线型 `SP[Xi,Yj]` 也参与 Yj 缩放。单项 seeding 使用所有 degree 类，满足 seed 权重加 operator degree 为 `{4,4,4,4}`。对整个 conformal 有限组合做额外 IBP 时，只用全零 degree。
2. **针对实际 targets 及 surviving representatives 撒点。** 包括已在矩阵内但 `G -> G` 的复杂积分。检查幂次转移链，不能只检查矩阵外积分。
3. **局部轴向 +/-1。** 每个因子块分别做轴向邻域；独立块之间取笛卡尔积。degree 类没有可用 seed 时报告原因，不能悄悄改为同一块中任意多轴偏移或全局大矩形范围。package 还会从涉及残留代表元的已有关系中选更简单的中心，再对这些中心执行同样的邻域规则。
4. **有结构地补 supersector。** `3+1` 补为三圈 ladder × 一圈完整 box；`2+2` 补为两个 double box；`2+1+1` 同理。不能保留 triangle 缺边后就认定对应因子不可约。记录补入的具体传播子 ID。
5. **完整 symmetry。** Y 可任意置换；当前 Gram 下包含 X1↔X3、X2↔X4 及组合。factorized 不同块独立做外线对称性，不能固定其中一块。整个生成支持都必须覆盖；旧原生系统还需保留传递闭包及旧列之间的新单位关系。
6. **factorized 优先是高斯自由列选择，不是 target 处理顺序。** 只因 H 有限或 factorized，不能额外把 H 加进 MI。先以真正约化后支持确定 raw MI，再保留单独有限项、构造所需有限组合。
7. **有限组合不含 x、y。** 从实际 DE 系数提取相反系数或更一般零和常系数块，优先两项、小支撑、少组合。不能任意猜 `Hi-H1`；零和本身不证明发散抵消。要检查实际 DE 覆盖及适用的 residue 证书。
8. **已知短组合应参与后续化简。** 后一轮发现的两项组合可回头简化前一轮多项组合；但若组合定义改变，必须从原始输入重跑受影响链条。单独有限积分不应藏在多项组合里。
9. **每次扩充后重约化所有历史 targets 和旧 RHS 代表元。** 不只约新目标；不得复用已过期的 finite basis / derivative targets。
10. **避免错误复杂度判断。** -2 分子幂在已闭合三圈结果中也出现，不能仅凭 -2 断言错误；孤立单传播子 tadpole 的四次幂不应成为无休止扩充的理由。
11. **contact 只作用于碰撞端点导数。** 旧程序曾错误地让 spectator loop 的导数携带其他块的碰撞 contact，导致本来已有的局部 IBP 被 `SP[_,infinity]` 检查拒绝。这一点已修复并有对照测试。不能把剩余 infinity 点积硬映射为普通 ISP。
12. **闭合必须检验同一组输入。** 对本轮每一个有限输入做两个微分，约化后在同一输入张成的空间里精确重构。没有裸发散、计数稳定、FiniteFlow 求解成功、`ReductionFixedPoint` 都不足以说明闭合。

低圈因子已知闭合，是优先 factorized 代表元的物理依据。但具体约化关系仍需在当前 family、规范和 kinematics 下证明。低圈参考公式可作检查基准，不应未经验证手工注入生产系统来掩盖自动 IBP 的缺口。

## 5. 需要另行迁移的数据

**GitHub 只有源码、示例、文档和小测试，没有原始资料或大型缓存。** 下列是当前 Mac 路径，不是 Ubuntu 路径：

| 数据 | Mac 路径 | 本次实测磁盘占用 |
| --- | --- | ---: |
| 当前旧生产脚本及计算档案 | `/Users/april/Documents/Dual conformal finite integral/outputs/` | 约 250 GB（du -sh 显示值） |
| 更早原始四圈脚本、母矩阵及依赖 | `/Users/april/Documents/Codex/2026-08-31/qi/outputs/` | 约 63 GB（同上） |
| 用户已闭合三圈 ladder 参考 | `/Users/april/Downloads/result/` | 约 468 KB |
| 新 package 开发测试输出 | `/Users/april/Documents/Dual conformal finite integral/runs/` | 约 600 KB |

两套大型目录合计约 313 GB；增量系统及中间对称性文件还会增长。这不是 RAM 需求估计，也不是未来磁盘空间上限。迁移前核对远端剩余空间。可以先传关键小文件，但复用原矩阵必须沿 `SystemManifest.wl`、`ArchiveChain.wl` 递归收齐依赖，不能只复制 `ordering01` 单目录。

优先核对的旧产物，以当前 `outputs/four_loop_ladder/closure_campaign/` 为基准：

```text
ordering01/RESULTS.md
ordering01/SystemManifest.wl
ordering01/ArchiveChain.wl
ordering01/FiniteOutputsFromTop.wl
ordering01/from_top/FinalQA.wl
ordering01/from_top/round4/NextInput.wl
ordering01/from_top/round4/OutputAdmission.wl
ordering01/from_top/round5/derivatives/
ordering01/query01/CompositionChecks.wl
ordering01/query01/reduction/IBP4ReductionRules.txt
ordering01/query01/reduction/Projection.wl
ordering01/query01/ComplexIdentityFocus.wl
```

其中最新规则文件约 58 MB。`Projection.wl` 明确标记 G4 quotient，不能把该规则表当作保留完整 G3 源项的物理等式。

三圈参考目录含 `DEladder.wl`、`MIladderAll.txt`、`ladderDEx.txt`、`ladderDEy.txt`、一/两/三圈约化相关文本。另保留可用的原始 `IBP3loop.wl`、`DEtennis.wl` 和 `lowerloop.pdf`。早前提到的 `FFIBPReductiond3loop.wl` 在本次核查的 Downloads 精确路径下不存在，需另行定位，不能在迁移脚本中假定它存在。

可在 Mac 上使用下列模板分开传输大数据，不上传到 GitHub。先设置真实 SSH 目标；这些命令未在本次交接中执行：

```sh
SSH_TARGET='your-user@your-ubuntu-host'
ssh "$SSH_TARGET" 'mkdir -p ~/dci-data/current ~/dci-data/legacy ~/dci-data/lowerloop-result'
rsync -a --partial --progress \
  '/Users/april/Documents/Dual conformal finite integral/outputs/' \
  "$SSH_TARGET:~/dci-data/current/outputs/"
rsync -a --partial --progress \
  '/Users/april/Documents/Codex/2026-08-31/qi/outputs/' \
  "$SSH_TARGET:~/dci-data/legacy/outputs/"
rsync -a --partial --progress '/Users/april/Downloads/result/' \
  "$SSH_TARGET:~/dci-data/lowerloop-result/"
```

完成后对关键数据生成并比较 SHA-256 清单；至少验证矩阵、列顺序、规则、unit maps、finite definitions 和 targets 的文件哈希。不要删除 Mac 原件。旧绝对路径需用明确的根目录映射调整，不能全局替换二进制或巨大数据文件。

## 6. Ubuntu 的启动顺序

1. 克隆私有仓库并记录提交号。需要 GitHub 授权，不要在聊天或仓库中保存 token。
2. 安装并激活 Linux Wolfram，确认独立 kernel 数量符合许可证；为 Linux 构建 FiniteFlow，不能复制 macOS 动态库。旧流水线若需要 Singular / SingularInterface、原生 C++ 辅助程序，也必须在 Linux 验证或重编译。新 package 的解析 rotation backend 本身不依赖 Singular。
3. 先做小测试，不立即扩大四圈范围。检查 `WolframKernel` 是否在 PATH；否则用安装后的完整可执行路径。

```sh
git clone https://github.com/RourouMa/DE-for-DCI.git
cd DE-for-DCI
git rev-parse HEAD
WolframKernel -script Tests/RunTests.wls
WolframKernel -script Tests/Workers.wls
WolframKernel -script Tests/FiniteFlow.wls /path/to/finiteflow/install /path/to/finiteflow/mathlink
WolframKernel -script Examples/one-loop.wls
```

4. 对照用户三圈结果。先核对 family、外点循环、归一化和低圈映射，再检查已知 DE 的重构与闭合。不能因为 package 的一圈测试通过，就声称三圈回归也已通过。
5. 选择下节的续算路线。在新路径写所有新增结果，旧档案只读保留。给运行记录源码 commit、family hash、输入定义 hash、系统/列顺序版本、投影约定和资源使用。

## 7. 推荐的续算路线

### 优先：接入旧系统，但先完成兼容性审计

目标是以 DE-for-DCI 为入口，复用已有百万级关系，而不是用 496 条开发关系替代旧系统。

先迁移并核验 `ordering01/query01` 及其矩阵依赖，补上 package 与旧系统之间的适配层。核对 ``Global`G`` / ``ConformalIBP`G``、`sp` / `SP`、旧 G3 与 `BoundaryIntegral`、propagator 顺序、conformal 权重、symmetry 代表元及 delta/contact 规范。

**当前 package 没有“一键导入旧 checkpoint/原生矩阵”的接口。** `InitialEquations` 接受已经兼容、经过验证的线性关系，不是随便载入一个旧规则文件。尤其不可把旧 G4 quotient 规则作为完整含低圈源项的关系传给默认物理计算。大矩阵可通过经过验证的 solver adapter 接入；不能为了复用数据把所有变量直接当成主积分。

适配完成后：先用最新 8,080 条 raw 导出规则复核 66 个输入的 682 个 targets，检查 18 个复杂 identity survivors，构造下一组可验证的有限输入并做真正 closure test。每当规则或 finite construction 有变化，从 Top 回放前几轮。缺关系才按实际残留扩大 seeding / symmetry；单纯缺导出时先导出。

### 备选：用 package 从 Top 全新计算

若旧数据尚未迁移或暂时无法可靠适配，可以从 Top 开始独立新链。这条链与旧的 `1 -> 4 -> 12 -> 26 -> 66` 分开命名，不预设其计数必须相等。

```wolfram
Get[FileNameJoin[{repo, "Kernel", "ConformalIBP.wl"}]];
Get[FileNameJoin[{repo, "Examples", "kinematics.wl"}]];
InitializeFiniteFlow[ffInstall, ffMathlink];
family = LadderFamily[4, kinematics, {x,y}];
top = G @@ Join[family["TopSector"], ConstantArray[1,4]];
result = RunDE[family, {top},
  "Solver" -> "FiniteFlow", "Workers" -> 4,
  "MaxRounds" -> 6, "MaxSystemExpansions" -> 12,
  "OutputDirectory" -> runDirectory];
```

这是配置模板，不是已经在 Ubuntu 完成的运行。`repo`、依赖目录和输出目录应设为该机器的真实路径。先用更小上限测量一次阶段成本，再决定资源预算。`Examples/four-loop.wls` 目前只有一轮/一次扩充的演示上限，不是长期生产设置。

相同源代码、family 与兼容环境下可使用 `ResumeRun[runDirectory]`。Mac 开发四圈 checkpoint 的 implementation fingerprint 已与发布代码不同，**不能绕过检查强行续跑**。跨机器还要更新运行输出路径、kernel 路径和依赖初始化；若须改变 checkpoint 配置，应实现有审计的迁移方法或新建 campaign，不能直接修改内容后伪造 hash。

## 8. 下一位计算代理的工作验收

- 每轮报告：实际输入数、DE 行数、targets、raw G4、单独有限、常系数组合、裸发散残留、factorized 数、未覆盖/自约化 targets、未闭合导数行数。
- 清楚区分 raw 支持、有限基底元素数、旧固定集合秩和真正输入空间闭合；不同分支的 58/60/65/66/71/94/103/116/166 等数字不能混用。
- 发现幂次不断升降或因子块继续扩张时，定位具体块、degree 缺口、supersector 缺边、局部算符是否被错误过滤，以及 symmetry / query export 是否完整。不要只增大通用范围。
- finite admission 失败时，保存完整失败行及 residue，不把裸发散元素放进下一轮有限输入。若涉及低圈 IBP 才能验证的 residue，要明确降到相应低圈系统处理。
- 确认闭合时，交付相同输入 basis 上两个方向的精确 DE 重构、全部低圈源项、常系数有限定义、独立检查和可复现日志。无源系统另检验 flatness；含源系统须处理完整三角系统的一致性。
- 不预报四圈必定在几轮或多少个 MI 闭合。大电脑解决的是计算资源，不会自动补上数学上遗漏的关系或程序错误。

## 9. 可直接发给新会话的提示

> 请继续四圈 conformal ladder 的微分方程闭合计算，使用私有仓库 https://github.com/RourouMa/DE-for-DCI 的程序，不要重新另写一套四圈脚本。先读 docs/UBUNTU_HANDOFF.zh-CN.md、README.md、docs/ALGORITHM.md 和 docs/VALIDATION.md，核验 Ubuntu 环境并运行测试。四圈尚未确认闭合。请区分新 package 与旧 ordering01/query01 大矩阵档案；后者第四轮有 34 个单独有限 + 32 个常系数组合，下一步有 682 个 targets，旧报告中的 85 条缺失导出实际上已在 query01 补齐。先审计迁移数据与适配，优先复用已验证关系；若无法可靠接入，再用 package 从 Top 新开独立计算链。严格遵守 degree 配对、轴向 +/-1、因子块完整 supersector、独立 factorized symmetry、常系数有限组合及每次扩充后历史重约化。真正闭合必须让两个方向的导数回到同一输入空间，并明确保留低圈源项。先报告识别到的代码版本、数据版本和下一步具体任务，然后开始计算。
