"""Fixed-budget independent total-sector quadrature, no analytic input."""
import argparse,hashlib,json,os,subprocess,time
from pathlib import Path
p=Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('method',choices=['qmc','vegas']);ap.add_argument('seed',type=int);a=ap.parse_args()
plan={'Method':a.method,'Seed':a.seed,'MaxTotalIntegrandEvaluations':100000,'TimeLimit':600,'EpsRel':1e-3,'Sectors':1492,'SectorValuesSummedBeforeQuadrature':True,'ReferenceRead':False,'StoppingRule':'Error target, fixed evaluation budget or fixed time; no estimate-dependent stopping'}
bin=p/'direct-total-sum';r={'PredeclaredPlan':plan,'ExecutableSHA256':hashlib.sha256(bin.read_bytes()).hexdigest(),'SourceSHA256':hashlib.sha256((p/'direct-total-sum.cpp').read_bytes()).hexdigest(),'StartedUnix':time.time(),'PID':os.getpid()};f=p/f'TotalSum-{a.method}-{a.seed}.json';f.write_text(json.dumps(r,indent=2))
cmd=[str(bin),a.method,str(a.seed),str(plan['MaxTotalIntegrandEvaluations'])];r['Command']=cmd
with (p/f'total-sum-{a.method}-{a.seed}.stdout').open('w') as out,(p/f'total-sum-{a.method}-{a.seed}.stderr').open('w') as err:
 try:
  v=subprocess.run(cmd,stdout=out,stderr=err,timeout=plan['TimeLimit']);r['ExitCode']=v.returncode;r['Status']='Computed' if v.returncode==0 else 'Failed'
 except subprocess.TimeoutExpired:r['Status']='TimedOut'
r['Seconds']=time.time()-r['StartedUnix'];raw=(p/f'total-sum-{a.method}-{a.seed}.stdout').read_text();r['RawOutput']=raw
try:r['Result']=json.loads(raw)
except Exception:pass
f.write_text(json.dumps(r,indent=2));print(json.dumps(r),flush=True)
