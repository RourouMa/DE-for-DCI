# 四圈源项所需的 35 项低圈闭合系统

组成：24 项三圈、7 项二圈、4 项一圈，全部为单个有限积分。相对于原来的 30 项低圈系统，加入 FiveGapDetails.zh-CN.md 中的 5 个三圈原子。

两张 35×35 有理微分方程矩阵位于 DifferentialEquations.wl 的 Matrices 字段；Basis 字段给出对应次序。分子与分母最高总次数均为 18。已通过完整原生物理方程池的独立检查，全部 1,225 个符号曲率元素精确为零。

Report.json、independent-verification/Report.json 和 ExactCurvatureReport.json 分别记录重构、独立检查和精确曲率检查。物理方程池与构建来源的绝对路径保留在原始审计记录中；本目录提供结果和证书，不包含大型原生方程缓存。

这里完成的是所需低圈系统；完整 88 项四圈系统另行重构和验证。
