"""Post-computation audit only; these comparisons never feed any integrator."""
import json,re
from pathlib import Path
import mpmath as mp
p=Path(__file__).resolve().parent;root=p.parents[1];mp.mp.dps=100
parse=lambda s:mp.mpf(re.sub(r'`[0-9.]*','',s).replace('*^','e'))
a=json.loads((p/'TopTaylor64.json').read_text());b=json.loads((p/'TopTaylor80Ray5.json').read_text());c=json.loads((p/'TopNDSolve.json').read_text());vals=[parse(z['TopValue']) for z in [a,b,c]]
maxdiff=max(abs(v-w) for v in vals for w in vals);cdiff=max(abs(parse(v)-parse(w)) for v,w in zip(a['CanonicalValues'],b['CanonicalValues']));ref=vals[2]
direct=[];pending=[]
files=sorted((root/'four-loop-analytic-20260927').glob('TopDirectNumerical*.json'))+sorted(p.glob('DirectStrong-*.json'))+sorted(p.glob('DirectSerial-*.json'))+sorted(p.glob('TopDirectSerialCoarse-*.json'))+sorted(p.glob('TotalSum-*.json'))
for f in files:
 z=json.loads(f.read_text());total=f.name.startswith('TotalSum-');serial=f.name.startswith(('DirectSerial-','TopDirectSerialCoarse-'));plan=z.get('PredeclaredPlan',{})
 if total and 'Result' in z:
  v,e=mp.mpf(str(z['Result']['Value'])),mp.mpf(str(z['Result']['Error']))
 elif 'SympyResult' in z:
  v,e=[mp.mpf(re.search(r'\(?([+-]?(?:\d+\.\d*|\d*\.\d+|\d+)(?:[eE][+-]?\d+)?)',q)[1]) for q in z['SympyResult']]
 else:
  pending.append({'File':str(f),'Status':z.get('Status','Running'),'Seconds':z.get('Seconds'),'PredeclaredPlan':plan});continue
 delta=ref-v;sigma=abs(delta)/e;vegasSeparate=serial and plan.get('Integrator')=='Vegas';racefree=serial or total
 audit='Single pointwise total-sector integrand; sector covariance included in direct total error estimate' if total else ('Serial sectors; no concurrent integrator calls. Vegas cross-sector repeated-seed error correlations remain unquantified' if vegasSeparate else 'Serial sectors; QMC RNG advances across sequential calls') if serial else 'Concurrent sectors share a mutable integrator: Vegas error reproduced; QMC risk not independently quantified'
 direct.append({'File':str(f),'Value':str(v),'ReportedError':str(e),'DEMinusDirect':mp.nstr(delta,30),'DifferenceOverReportedError':mp.nstr(sigma,20),'WithinThreeReportedErrors':bool(sigma<=3),'RaceFreeConfiguration':racefree,'EligibleForErrorBarBasedAcceptance':racefree and not vegasSeparate,'ConfigurationAudit':audit,'RequestedRelativeAccuracyReached':bool(e/abs(v)<=mp.mpf(str(z.get('RequestedRelativeError',plan.get('EpsRel',1e-4)))))})
accepted=[z for z in direct if z['EligibleForErrorBarBasedAcceptance']]
report={'Point':['1/4','3/4'],'DETopValueConservative40Digits':mp.nstr(ref,40),'DETopValueNDSolve':mp.nstr(ref,70),'MaximumDifferenceAcrossThreeAlgorithmsAndPaths':mp.nstr(maxdiff,30),'MaxCanonical88DifferenceAcrossTwoTaylorPaths':mp.nstr(cdiff,30),'DECrossCheckAgreesAt40DecimalPlaces':bool(maxdiff<mp.mpf('1e-40') and cdiff<mp.mpf('1e-40')),'NoDirectEstimateUsedForBoundary':True,'NDSolveWarning':None,'NDSolveSettings':'80-digit initial Taylor arithmetic, 70-digit NDSolve with 50-digit error goals; rerun completed without warnings. Precision claim additionally requires cross-method agreement.','DirectComparisons':direct,'DirectRunsWithoutFinalEstimate':pending,'OriginalRefinedDirectValidationPassed':False,'OriginalRefinedEligibleForValidation':False,'RaceFreeDirectChecksCompleted':sum(z['RaceFreeConfiguration'] for z in direct),'ErrorBarEligibleChecksCompleted':len(accepted),'ErrorBarEligibleChecksAllWithinThreeReportedErrors':all(z['WithinThreeReportedErrors'] for z in accepted) if accepted else None,'Interpretation':'Concurrent-sector direct calls are excluded. Serial Vegas avoids concurrency but its same-seed sector covariance is unquantified, so its reported sigma cannot justify an acceptance claim. Serial QMC and pointwise total-sector integrations are evaluated with their convergence evidence. Statistical error bars are not rigorous bounds; all results and timeouts are retained.'}
(p/'TopNumericalComparison.json').write_text(json.dumps(report,indent=2));print(json.dumps({k:v for k,v in report.items() if k not in ['DirectComparisons','DirectRunsWithoutFinalEstimate']},indent=2))
