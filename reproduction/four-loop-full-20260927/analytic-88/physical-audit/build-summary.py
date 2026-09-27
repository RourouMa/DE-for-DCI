import json,shutil,time,re
from decimal import Decimal
from pathlib import Path
p=Path(__file__).resolve().parent
read=lambda n:json.loads((p/n).read_text())
legacy=read('LegacyPhysicalMappingAudit.json');low=read('LowerPoolContactAudit.json');whole=read('NonAtomicContactAudit.json');cp=read('CheckpointContactAudit.json');joint=read('JointPoolMembershipAudit.json')
jobs=[]
reference=json.loads((p.parent/'numerical/NativeValues88AtQuarterThreeQuarter.json').read_text())['Values'][55]
for f in sorted(p.glob('ConnectedLowerDirect-*.json')):
 a=read(f.name)
 if a.get('Sympy'):
  a.setdefault('Status','Computed');val=Decimal(re.match(r'\(([^+]+)\+',a['Sympy'][0]).group(1));err=Decimal(re.match(r'\(([^+]+)\+',a['Sympy'][1]).group(1));a.update(CurrentNativeIndex=56,CurrentAnalyticReference=reference,DirectValue=str(val),DirectReportedError=str(err),PullVsCurrentAnalytic=float(abs(val-Decimal(reference))/err));f.write_text(json.dumps(a,indent=2))
 jobs.append({'File':f.name,**{k:a[k] for k in ['Seed','Status','NumberOfAmplitudeThreads','QMCInternalThreads','AcceptanceEligible','Seconds','Sympy','WallClockLimit','ShutdownGraceSeconds','Reason','CurrentAnalyticReference','DirectValue','DirectReportedError','PullVsCurrentAnalytic'] if k in a}})
report={'Status':'Physical normalization and specified contact-risk audit completed; independent four-loop top numerical discrepancy unresolved','FrozenExpressionsModified':False,'ConstantsFittedToNumerics':False,'Original83MappingPreserved':legacy['Original83PreservedModuloIndependentLoopAndExternalGroupPermutations'],'LegacyDirectMatches':legacy['DirectLegacySymmetryMatches'],'LegacyConnectedThreeLoopMatches':len(legacy['ConnectedThreeLoopMatches']),'LegacyConnectedMaximumReportedPull':max(a['PullVsCurrentAnalytic'] for a in legacy['ConnectedThreeLoopMatches']),'LegacyAmplitudeSectorThreads':2,'LegacyThreadSafetyCaveat':True,'MainCheckpoint':{'Relations':cp['Rows'],'TotalApplications':cp['CompletedApplications'],'AtomicApplications':cp['CompletedApplications']-whole['NonAtomicApplications'],'WholeApplications':whole['NonAtomicApplications'],'WholeSeedAtoms':whole['UniqueSeedAtoms'],'WholeMaxInternalPower':whole['MaximumInternalPowerAmongAtoms'],'WholeApplicationsWithDoublePole':whole['NonAtomicApplicationsWithAnyInternalDoublePole'],'CoupledGroups':cp['CompletedCoupledGroups']},'NewLowerSourcePool':low['Source'],'NewLowerGapPool':low['Gap'],'HistoricalJointCandidateMembership':joint['Records'],'PairContactConcernApplicableToAuditedWholeApplications':not whole['AllNonAtomicSeedsFreeOfPairContact'],'PairContactNeighborNormalizationProved':True,'IndependentTwoLoopEndpointNormalizationProved':True,'GeneralArbitraryJointContactFormulaClaimed':False,'DirectConnectedThreeLoopAttempts':jobs,'BudgetAuditFile':'ConnectedLowerBudgetAudit.json','FourLoopTopDirectValidationPassed':False,'Limitations':['This audits the specified nonvanishing-vector isolated pair-contact concern and normalization, not every possible multi-cluster extension of the distribution formula.','No arbitrary coupled/contact formula is certified by cancellation of infinity symbols alone.','The current four-loop direct numerical discrepancy remains unresolved; no four-loop numerical success is inferred from algebraic DE/Chen agreement.']}
(p/'PhysicalAuditSummary.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
md='''# 物理侧独立审计结果

83→88 的原积分定义、低圈直接积分映射以及 measure/contact 归一化检查通过。四圈 top 的直接数值与解析 DE 的差异仍未解决；本审计没有修改冻结表达式或拟合常数。

独立指标置换确认原 83 项全部保持，另有 16 项匹配历史直接低圈定义。7 个连通三圈积分的历史直接结果在当前解析值的 2.09 个所报误差内。历史运行采用 amplitude sector threads=2，保留线程共享风险说明；它们不能替代新的串行 sector 复核。

正式四圈主 checkpoint 的 4,387,468 条 completed applications 中，4,387,108 条为单个 G，360 条为 whole seed。后者只有 63 个不同原子，所有内部传播子幂次最高为 1；没有含双极点的 whole application。coupled options/ledger 均为空。因此本次发现的“一般 nonvanishing-vector joint 双極点通量可能含梯度项”的特定风险，不适用于这个正式 ledger 中的 whole actions。

单个 G 的接受情形也已区分：operator 不含碰撞邻点时，双极点 contact 带未消除的 infinity 标量积，会被拒绝；包含邻点时向量在碰撞点为零，独立小球通量严格给出 -2 的系数。完整一般通量的梯度项及其适用范围见 `ContactFluxDerivation.zh-CN.md`；两圈端点卷积的独立解析证明见 `NormalizationAudit.zh-CN.md`。

新增低圈 source/gap 两池分别含 77,412 / 15,798 条关系，192,288 / 36,810 条 applications 全部是单个 G，无 coupled group 或 search。历史额外 coupled-chain 228 条、whole-constant 212 条在目前高圈池及 epoch3 选中 183,728 条中均无逐项相同关系；whole-finite 888 条仅 11 条与既有高圈池重合，选中行中为 0。这些试验自己的报告也记录未改动正式池。源于既有有限物理关系的运动学求导增加行，不引入新 contact 公式。

新的直接三圈尝试按固定预算记录在 `ConnectedLowerBudgetAudit.json` 和 `ConnectedLowerDirect-*.json`。首两次的初始 QMC 批次过大，因此显式设置了原先 1800 秒预算加 60 秒结束宽限的 watchdog；第三次使用较小初始批次、串行 sectors 和独立 240+60 秒固定预算。所有成功、超时和不供验收的 amp2 尝试均保留。

以上只处理明确列出的物理映射、归一化与 isolated pair-contact 疑点，不把任意 joint action 的 infinity 抵消当作分布公式证明，也不宣称四圈数值验证已经成功。
'''
(p/'PhysicalAuditSummary.zh-CN.md').write_text(md)
dst=p.parents[1]/'DE-for-DCI-publish/reproduction/four-loop-full-20260927/analytic-88/physical-audit';dst.mkdir(parents=True,exist_ok=True)
include=['PhysicalAuditSummary.json','PhysicalAuditSummary.zh-CN.md','LegacyPhysicalMappingAudit.json','NormalizationAudit.zh-CN.md','ContactFluxDerivation.zh-CN.md','ContactFluxLocalCertificate.json','LowContactWitness.wl','CheckpointContactAudit.json','NonAtomicContactAudit.json','NonAtomicContactAudit.wl','LowerPoolContactAudit.json','JointPoolMembershipAudit.json','ConnectedLowerBudgetAudit.json','audit-legacy-physical.py','contact-low-witness.wls','checkpoint-contact-audit.wls','non-atomic-contact-audit.wls','lower-pool-contact-audit.wls','joint-pool-membership.wls','connected-lower-direct.py','connected-lower-serial.py','connected-lower-bounded.py','connected-lower-watchdog.py','build-summary.py']
include += [f.name for f in p.glob('ConnectedLowerDirect-*.json')]
for n in include:
 if (p/n).exists():shutil.copy2(p/n,dst/n)
print(json.dumps({'PackageAuditDirectory':str(dst),'FilesSynced':len(include),'DirectAttemptsRecorded':len(jobs)}))
