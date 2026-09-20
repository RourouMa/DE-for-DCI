# 四圈 ladder：第四轮 66 维结果的固定复现包

本目录复现的是旧生产计算 **ordering01**，不是仓库通用 package 的 `Examples/four-loop.wls`。二者不能混用 checkpoint、计数或约化规则。这里的“第四轮”指对第三轮 26 个输入求导并约化，输出 66 个有限元素。

## 先在 Ubuntu 复现第四轮

在已克隆仓库的根目录执行。私有仓库需要当前 Ubuntu 用户自己的 GitHub 凭据，不要复制或提交 Mac 的 token。

```bash
gh auth login
git pull --ff-only
python3 reproduction/ordering01/fetch.py --all
WolframKernel -script reproduction/ordering01/replay.wls
WolframKernel -script reproduction/ordering01/verify.wls
```

若命令名是 `wolfram`，将 `WolframKernel` 替换为实际内核路径。前两步已完成时不必重复。只复现第四轮可以不加 `--all`，只下载约化规则及参考输出；完整矩阵和撒点信息需要 `--all`。下载程序核对压缩包及每个解压文件的 SHA-256。

此重跑**不需要 Singular 或 FiniteFlow**：它读取已解出的固定规则，从 Top 开始重新对每一轮有限输入求导、约化、构造常系数组合并检查 collision residues。它不是把保存的 `NextInput.wl` 当作计算结果直接复制。`verify.wls` 逐轮核对基底定义、target 集合、约化 DE 和代数检查。

输出默认在本目录 `work/replay/`。为避免读取旧缓存，已有该目录时程序拒绝运行；第二次测试可设置新的路径：

```bash
export DCI_REPLAY_OUT="$PWD/reproduction/ordering01/work/replay2"
```

数据位置可用 `DCI_SNAPSHOT_DATA` 指定。不要运行 `data/provenance/scripts/` 内的历史脚本，它们保留原始绝对路径，仅供溯源；可移植入口是本目录的 `.wls` 文件。

## 固定结果与有限性边界

| 求导约化轮次 | 输入数 | DE targets | raw G4 | 单独有限 | 常系数组合 | 输出数 | factorized 单独有限 | 裸发散 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 1 | 11 | 5 | 3 | 1 | 4 | 0 | 0 |
| 2 | 4 | 48 | 19 | 7 | 5 | 12 | 0 | 0 |
| 3 | 12 | 129 | 50 | 13 | 13 | 26 | 0 | 0 |
| 4 | 26 | 255 | 130 | 34 | 32 | 66 | 5 | 0 |

第四轮 32 个组合中，28 个为二项、4 个为四项；全部为常系数，不含 x、y。每轮的完整积分和组合在 `finite/roundN.wl`，下载后的逐轮证书和 DE 在 `data/reference/roundN/`。

“有限”在此对应保存的判据：实际输入和 DE 可完全覆盖，且单个二次 loop-loop 极点的 collision residues 在允许的对称性下抵消；**不等于已经证明所有重叠奇点的全局收敛性**。保存的 `OutputAdmission.wl` 明确标记 `NotAFullConvergenceProof -> True`。

四轮均未闭合。第四轮还有 28 条导数行不属于其原输入的张成空间，不能将 66 当作已证明的最终 MI 数。整个快照只处理 **G4 quotient**；忽略 G3 是投影，不是令低圈源项在物理上等于零。

## 完整 IBP 系统重新求解

矩阵包含所有已经并入 ordering01 的 IBP / symmetry 关系，保存原有列顺序，优先留下 factorized 自由代表元。装配方式必须保持：

```wolfram
DeleteCases[DeleteDuplicates[Join[
  baseEquations /. _G3 -> 0, canonicalAddedEquations]], 0]
```

预期为 **2,833,280 行、2,850,483 列**。`QueryMap.wl` 把 raw 请求映射到此系统的 canonical 列；不能用另一个 canonicalization 或排序替代它。

在 Ubuntu 编译、安装 FiniteFlow 后：

```bash
export FINITEFLOW_LIBRARY_PATH=/your/finiteflow/install
export FINITEFLOW_MATHLINK_PATH=/your/finiteflow/mathlink
WolframKernel -script reproduction/ordering01/solve.wls
```

`solve.wls` 从完整方程重新做 FiniteFlow 消元，与发布的 canonical rules 逐项作精确差值检查，并输出 raw rules。这一步与前面的“固定规则重放”不同，内存和时间开销明显更大。不要把成功读取矩阵或已有规则当作新求解成功。输出在 `work/solve/`，不覆盖固定规则。

若 `work/solve/Verification.wl` 为 `ExactCanonicalRulesMatch -> True`，可进一步用**新求出的规则**重跑：

```bash
export DCI_REDUCTION_DIR="$PWD/reproduction/ordering01/work/solve"
export DCI_REPLAY_OUT="$PWD/reproduction/ordering01/work/replay-from-fresh-solve"
WolframKernel -script reproduction/ordering01/replay.wls
WolframKernel -script reproduction/ordering01/verify.wls
```

回到默认规则重放前，先 `unset DCI_REDUCTION_DIR DCI_REPLAY_OUT`。不会隐式混用 query01 或其它分支。

## 第五轮衔接

`data/reference/round5/derivatives/` 保存 66 个输入产生的 132 条导数行及 682 个 target。`data/query01/reduction/IBP4ReductionRules.txt` 是同一矩阵的查询扩展，共 8080 条 raw rules；旧第四轮复现仍固定使用 `data/reduction/`。query01 补出了此前缺少的 85 条 raw 请求，**不是增加了 85 条独立 IBP**。本快照未宣称第五轮有限基底已经计算完成或 DE 已经闭合。

## 数据版本

GitHub Release 固定标签：`ordering01-repro-2026-09-21`。`snapshot.json` 列出所有文件及哈希。大数据放在同一私有仓库的 Release assets，不在普通 git 历史中；**仅 git pull 不会下载它们**。

- `ordering01-runtime.tar.gz`：两版明确分开的约化规则、四轮有限组合和证书、第五轮已有导数。
- `ordering01-matrix.tar.gz`：原始矩阵、累计增量、精确列顺序、canonical/raw 映射及已解 canonical rules。
- `ordering01-seeds.tar.gz`：实际 seeds/operator 配对、各轮 degree/domain 审计、增量系统溯源、历史生成和 symmetry 源码。

冻结算法在 `legacy/`，保持源文件原样以便核对 fingerprint；其中未被本次重放调用的历史辅助分支仍可能包含 Mac 路径。实际重放不依赖这些路径。算符另有可移植文本 `Operators.wl`，不用在 Ubuntu 读取 Mac 的 `.mx`。

撒点规则、已纳入与实验记录的区分见 `SEEDING.zh-CN.md`。不要把 provenance 中所有探索性文件再次无条件拼进矩阵。
