"""Enforce predeclared integration budgets plus 60s shutdown grace."""
import json,os,signal,time
from pathlib import Path
p=Path(__file__).resolve().parent
names=['DirectStrong-qmc-default.json','DirectStrong-qmc-polysingular.json','DirectSerial-qmc-default.json','DirectSerial-vegas.json']
pending=set(names);actions=[]
while pending:
 for name in list(pending):
  f=p/name;a=json.loads(f.read_text())
  if a.get('Status') in ('Computed','Failed','TimedOut'):
   pending.remove(name);continue
  deadline=a['StartedUnix']+a['PredeclaredPlan']['WallClockLimit']+60
  if time.time()>=deadline:
   try:
    cmd=Path(f"/proc/{a['PID']}/cmdline").read_bytes()
    if b'direct-strong.py' not in cmd and b'direct-serial.py' not in cmd:raise RuntimeError('PID identity changed')
    os.kill(a['PID'],signal.SIGTERM)
   except FileNotFoundError:pass
   a.update(Status='TimedOut',Seconds=time.time()-a['StartedUnix'],HardDeadlineGraceSeconds=60,ReasonForTermination='Fixed wall clock budget plus 60-second shutdown grace exceeded; no estimate-based stopping.')
   f.write_text(json.dumps(a,indent=2));actions.append({'File':name,'PID':a['PID'],'Seconds':a['Seconds']});pending.remove(name);print(actions[-1],flush=True)
 (p/'DirectDeadlineAudit.json').write_text(json.dumps({'Policy':'Fixed configured wall clock plus 60s grace; only registered task PIDs','Pending':sorted(pending),'Actions':actions},indent=2))
 if pending:time.sleep(5)
print('all registered direct jobs completed or timed out',flush=True)
