"""Predeclared serial-sector coarse top controls; analytic constants never read."""
import argparse,hashlib,json,os,time,threading
from pathlib import Path
from pySecDec.integral_interface import IntegralLibrary,series_to_sympy
p=Path(__file__).resolve().parent;root=p.parents[1]
so=root/'four-loop-analytic-20260927/numerical-work/four_top_p1/four_top_p1_pylink.so'
ap=argparse.ArgumentParser();ap.add_argument('seed',type=int);a=ap.parse_args()
cfg={'Integrator':'Qmc','Seed':a.seed,'MaxEval':100000000,'WallClockLimit':300,'AmplitudeThreads':1,'IntegratorThreads':2,'EpsRel':1e-3,'EpsAbs':1e-8,'Transform':'korobov3','MinM':16,'MinN':1000}
rep={'PredeclaredPlan':cfg,'Point':['1/4','3/4'],'IntegralIndex':1,'Loops':4,'Library':str(so),'LibrarySHA256':hashlib.sha256(so.read_bytes()).hexdigest(),'PID':os.getpid(),'StartedUnix':time.time(),'DEOrAnalyticReferenceRead':False,'Reason':'Serial sector controls for shared mutable integrator; independent seeds and fixed budgets.','StoppingRule':'Requested error, fixed maxeval, or fixed wall clock; no reference comparison'}
f=p/f'TopDirectSerialCoarse-{a.seed}.json';f.write_text(json.dumps(rep,indent=2));print(json.dumps(rep),flush=True)
lib=IntegralLibrary(str(so));lib.use_Qmc(transform=cfg['Transform'],epsrel=cfg['EpsRel'],epsabs=cfg['EpsAbs'],minn=cfg['MinN'],minm=cfg['MinM'],maxeval=cfg['MaxEval'],cputhreads=cfg['IntegratorThreads'],seed=cfg['Seed'])
start=time.monotonic()
def timeout_now():
 rep.update(Status='TimedOut',Seconds=time.monotonic()-start,ReasonForTermination='Fixed wall clock plus 60-second grace exceeded; no estimate-based stopping');f.write_text(json.dumps(rep,indent=2));print(json.dumps(rep),flush=True);os._exit(124)
timer=threading.Timer(cfg['WallClockLimit']+60,timeout_now);timer.start()
try:
 v=lib(epsrel=cfg['EpsRel'],epsabs=cfg['EpsAbs'],number_of_threads=1,wall_clock_limit=cfg['WallClockLimit']);rep.update(Status='Computed',Seconds=time.monotonic()-start,SympyResult=list(series_to_sympy(v[-1])),RawResult=list(v))
except Exception as e:rep.update(Status='Failed',Seconds=time.monotonic()-start,Error=repr(e));raise
finally:timer.cancel();f.write_text(json.dumps(rep,indent=2));print(json.dumps(rep),flush=True)
