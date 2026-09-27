"""Assess the two predeclared refined complete-sum Vegas runs, retaining all stages."""
from pathlib import Path
import hashlib,json
import mpmath as mp
p=Path(__file__).resolve().parent;mp.mp.dps=80
ref=mp.mpf(json.loads((p/'TopTaylor80Ray5.json').read_text())['TopValue']);rows=[]
for seed in (141421,17320508):
 f=p/f'TotalSum-refined-vegas-{seed}.json';z=json.loads(f.read_text());a={'Seed':seed,'File':str(f),'Status':z.get('Status','Running'),'Plan':z['PredeclaredPlan']}
 if 'Result' in z:
  r=z['Result'];v=mp.mpf(str(r['Value']));e=mp.mpf(str(r['Error']));a.update(r);a.update(AbsoluteDifference=mp.nstr(abs(v-ref),20),DifferenceOverReportedError=mp.nstr(abs(v-ref)/e,15),RelativeReportedError=mp.nstr(e/abs(v),15),RequestedRelativePrecisionReached=bool(e/abs(v)<=mp.mpf('.001')),WithinThreeReportedErrors=bool(abs(v-ref)<=3*e));a['CheckPassedAtRequestedPrecision']=a['CubaFail']==0 and a['RequestedRelativePrecisionReached'] and a['WithinThreeReportedErrors']
 rows.append(a)
report={'Point':['1/4','3/4'],'DEReference40Digits':mp.nstr(ref,40),'NoDEReferenceUsedForIntegration':True,'AssessmentPlan':'Use both predetermined 1M complete-sector-sum Vegas seeds. Require CubaFail=0, reported relative error<=0.1%, and analytic value within 3 reported errors separately. Do not discard or extend runs based on matching.','RefinedChecks':rows,'BothComputed':all(r['Status']=='Computed' for r in rows),'BothPassedAtRequestedPrecision':all(r.get('CheckPassedAtRequestedPrecision',False) for r in rows),'DirectErrorBarsAreRigorousBounds':False,'AllEarlierMethodsAndTimeoutsRetainedIn':'TopNumericalComparison.json','EarlierLimitations':'Legacy concurrent sectors unsafe; serial Cuba cross-sector covariance unquantified; low-budget QMC missed requested accuracy; coarse total-sector QMC has large variance; all kept in audit.'}
for row in rows:
 if 'Value' in row:
  row['RelativeDifferenceFromAnalytic']=mp.nstr(abs(mp.mpf(str(row['Value']))-ref)/abs(ref),20)
if all('Value' in r for r in rows):
 a,b=rows;sep=abs(mp.mpf(str(a['Value']))-mp.mpf(str(b['Value'])))/mp.sqrt(mp.mpf(str(a['Error']))**2+mp.mpf(str(b['Error']))**2);report['IndependentSeedDifferenceOverCombinedReportedError']=mp.nstr(sep,15)
(p/'FinalDirectValidation.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
