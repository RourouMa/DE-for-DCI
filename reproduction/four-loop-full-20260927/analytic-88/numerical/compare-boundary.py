"""Compare completed serial boundary controls to an independent analytic source."""
import hashlib,json,re
from pathlib import Path
import mpmath as mp
p=Path(__file__).resolve().parent;root=p.parents[1];mp.mp.dps=100
src=root/'four-loop-analytic-20260927/B4RadialCheck.json';ref=mp.mpf(json.loads(src.read_text())['RadialValue']);checks=[]
for f in sorted(p.glob('BoundaryDirectSerial-*.json')):
 d=json.loads(f.read_text());row={'File':str(f),'Status':d.get('Status','Running'),'AnalyticReferenceReadDuringIntegration':d['DEOrAnalyticReferenceRead'],'PredeclaredPlan':d['PredeclaredPlan']}
 if 'SympyResult' in d:
  v,e=[mp.mpf(re.search(r'\(?([+-]?(?:\d+\.\d*|\d*\.\d+|\d+)(?:[eE][+-]?\d+)?)',q)[1]) for q in d['SympyResult']]
  row.update(Value=mp.nstr(v,20),ReportedError=mp.nstr(e,20),AnalyticMinusDirect=mp.nstr(ref-v,25),DifferenceOverReportedError=mp.nstr(abs(ref-v)/e,15),WithinOneReportedError=bool(abs(ref-v)<=e),RequestedRelativePrecisionReached=bool(e/abs(v)<=mp.mpf('1e-5')),Seconds=d['Seconds'])
 checks.append(row)
r={'Point':[1,1],'AnalyticReference':mp.nstr(ref,95),'AnalyticSource':str(src),'AnalyticSourceSHA256':hashlib.sha256(src.read_bytes()).hexdigest(),'NewSerialSectorChecks':checks,'BothNewChecksWithinOneReportedError':len(checks)==2 and all(c.get('WithinOneReportedError',False) for c in checks),'RequestedRelativePrecisionReachedByBoth':all(c.get('RequestedRelativePrecisionReached',False) for c in checks),'LegacyConcurrentBoundaryQMCExcluded':True,'Interpretation':'The two new serial-sector controls support the analytic boundary within their reported errors; neither reaches the requested 1e-5 relative precision. Exact B4 and canonical boundary derivation remain independent of these direct estimates.','AffinityNote':'Seed 20260927 initially shared CPUs26/31 with the other run and was later moved to CPUs24/25; seed and stopping rules were unchanged.'}
(p/'BoundaryDirectSerialComparison.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2))
