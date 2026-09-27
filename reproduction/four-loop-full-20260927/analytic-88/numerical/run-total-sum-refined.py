"""Two independent fixed one-million sample complete-sum Vegas checks."""
import argparse,hashlib,json,os,signal,subprocess,time
from pathlib import Path
p=Path(__file__).resolve().parent;ap=argparse.ArgumentParser();ap.add_argument('seed',type=int);a=ap.parse_args()
plan={'Method':'Vegas-single-total-sum','Seed':a.seed,'MinEval':1000000,'MaxEval':1000000,'TimeLimit':900,'EpsRel':1e-3,'NStart':10000,'NIncrease':10000,'CubaWorkerProcesses':2,'AmplitudeThreads':1,'Sectors':1492,'SectorValuesSummedBeforeQuadrature':True,'ReferenceRead':False,'StoppingRule':'Fixed one-million minimum and maximum budget, or fixed time limit. Cuba may finish its final iteration beyond maxeval. No estimate-dependent stopping.'}
bin=p/'direct-total-sum-vegas-v2';r={'PredeclaredPlan':plan,'ExecutableSHA256':hashlib.sha256(bin.read_bytes()).hexdigest(),'SourceSHA256':hashlib.sha256((p/'direct-total-sum-vegas-v2.cpp').read_bytes()).hexdigest(),'StartedUnix':time.time(),'PID':os.getpid()};f=p/f'TotalSum-refined-vegas-{a.seed}.json';f.write_text(json.dumps(r,indent=2));cmd=[str(bin),str(a.seed),str(plan['MaxEval'])];r['Command']=cmd
with (p/f'total-sum-refined-vegas-{a.seed}.stdout').open('w') as out,(p/f'total-sum-refined-vegas-{a.seed}.stderr').open('w') as err:
 proc=subprocess.Popen(cmd,stdout=out,stderr=err,start_new_session=True)
 try:code=proc.wait(timeout=plan['TimeLimit']);r.update(ExitCode=code,Status='Computed' if code==0 else 'Failed')
 except subprocess.TimeoutExpired:os.killpg(proc.pid,signal.SIGTERM);proc.wait();r['Status']='TimedOut'
r['Seconds']=time.time()-r['StartedUnix'];raw=(p/f'total-sum-refined-vegas-{a.seed}.stdout').read_text();r['RawOutput']=raw
try:r['Result']=json.loads(raw)
except Exception:pass
f.write_text(json.dumps(r,indent=2));print(json.dumps(r),flush=True)
