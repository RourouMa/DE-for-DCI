import json,os,signal,time,psutil
from pathlib import Path
p=Path(__file__).resolve().parent
jobs=[(657472,2026092702,2,300000000),(661812,2026092713,1,100000000)]
records=[]
for pid,seed,amp,neval in jobs:
 try:
  proc=psutil.Process(pid);created=proc.create_time()
  if 'connected-lower-' not in ' '.join(proc.cmdline()):raise RuntimeError('PID mismatch')
 except psutil.NoSuchProcess:continue
 records.append(dict(PID=pid,Seed=seed,StartedUnix=created,Status='Running',AmplitudeSectorThreads=amp,QMCInternalThreads=2,WallClockLimit=1800,ShutdownGraceSeconds=60,MaxEval=neval,AcceptanceEligible=amp==1,PlanBasis='Requested wall_clock_limit=1800 set before integration started; enforce 60-second shutdown grace independent of estimate'))
while any(j['Status']=='Running' for j in records):
 for j in records:
  if j['Status']!='Running':continue
  out=p/f"ConnectedLowerDirect-ladder1t0-{j['Seed']}.json"
  if out.exists():
   a=json.loads(out.read_text());a.update(NumberOfAmplitudeThreads=j['AmplitudeSectorThreads'],QMCInternalThreads=2,MaxEval=j['MaxEval'],AcceptanceEligible=j['AcceptanceEligible']);out.write_text(json.dumps(a,indent=2));j['Status']='Computed';continue
  if not psutil.pid_exists(j['PID']):j['Status']='ExitedWithoutEstimate';continue
  if time.time()>=j['StartedUnix']+1860:
   proc=psutil.Process(j['PID'])
   if abs(proc.create_time()-j['StartedUnix'])<1 and 'connected-lower-' in ' '.join(proc.cmdline()):proc.terminate()
   j.update(Status='TimedOut',Reason='Pre-set 1800 seconds plus fixed 60-second grace exceeded; no estimate-based stopping')
 (p/'ConnectedLowerBudgetAudit.json').write_text(json.dumps({'Jobs':records,'UpdatedUnix':time.time()},indent=2))
 if any(j['Status']=='Running' for j in records):time.sleep(5)
print(json.dumps(records),flush=True)
