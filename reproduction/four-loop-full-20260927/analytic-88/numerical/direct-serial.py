"""Serial-sector controls for the shared mutable integrator in pySecDec 1.6.3.
No DE result or target reference is read. Parallelism is only inside one QMC call.
"""
import argparse,hashlib,json,os,time,threading
from pathlib import Path
from pySecDec.integral_interface import IntegralLibrary,series_to_sympy
p=Path(__file__).resolve().parent;root=p.parents[1];legacy=root/'four-loop-analytic-20260927';name='four_top_p1';so=legacy/'numerical-work'/name/(name+'_pylink.so')
plans={
 'vegas':{'Integrator':'Vegas','Seed':271828,'MaxEval':1000000000,'WallClockLimit':900,'AmplitudeThreads':1,'EpsRel':5e-5,'EpsAbs':1e-8,'NStart':1000000,'NIncrease':500000},
 'qmc-default':{'Integrator':'Qmc','Seed':314159,'MaxEval':4000000000,'WallClockLimit':900,'AmplitudeThreads':1,'IntegratorThreads':4,'EpsRel':5e-5,'EpsAbs':1e-8,'Transform':'korobov3','FitFunction':'default','MinM':128,'MinN':100000},
 'qmc-polysingular':{'Integrator':'Qmc','Seed':161803,'MaxEval':4000000000,'WallClockLimit':900,'AmplitudeThreads':1,'IntegratorThreads':4,'EpsRel':5e-5,'EpsAbs':1e-8,'Transform':'korobov3','FitFunction':'polysingular','MinM':128,'MinN':10000}}
ap=argparse.ArgumentParser();ap.add_argument('mode',choices=plans);a=ap.parse_args();cfg=plans[a.mode]
rep={'PredeclaredPlan':cfg,'Point':['1/4','3/4'],'IntegralIndex':1,'Loops':4,'Library':str(so),'LibrarySHA256':hashlib.sha256(so.read_bytes()).hexdigest(),'PID':os.getpid(),'StartedUnix':time.time(),'DEOrAnalyticReferenceRead':False,'Reason':'Avoid concurrent sector calls sharing one mutable integrator object. Retain all earlier results as audit data.','StoppingRule':'Requested error, fixed maxeval, or fixed wall clock; no reference comparison'}
f=p/f'DirectSerial-{a.mode}.json';f.write_text(json.dumps(rep,indent=2));print(json.dumps(rep),flush=True)
lib=IntegralLibrary(str(so))
if a.mode=='vegas':lib.use_Vegas(epsrel=cfg['EpsRel'],epsabs=cfg['EpsAbs'],seed=cfg['Seed'],maxeval=cfg['MaxEval'],mineval=1000000,nstart=cfg['NStart'],nincrease=cfg['NIncrease'],nbatch=10000,flags=0)
else:lib.use_Qmc(transform=cfg['Transform'],fitfunction=cfg['FitFunction'],epsrel=cfg['EpsRel'],epsabs=cfg['EpsAbs'],minn=cfg['MinN'],minm=cfg['MinM'],maxeval=cfg['MaxEval'],cputhreads=cfg['IntegratorThreads'],seed=cfg['Seed'])
start=time.monotonic()
def timeout_now():
 rep.update(Status='TimedOut',Seconds=time.monotonic()-start,ReasonForTermination='Fixed wall clock plus 60-second grace exceeded; no estimate-based stopping')
 f.write_text(json.dumps(rep,indent=2));print(json.dumps(rep),flush=True);os._exit(124)
timer=threading.Timer(cfg['WallClockLimit']+60,timeout_now);timer.start()
try:
 v=lib(epsrel=cfg['EpsRel'],epsabs=cfg['EpsAbs'],number_of_threads=1,wall_clock_limit=cfg['WallClockLimit'])
 rep.update(Status='Computed',Seconds=time.monotonic()-start,SympyResult=list(series_to_sympy(v[-1])),RawResult=list(v))
except Exception as e:rep.update(Status='Failed',Seconds=time.monotonic()-start,Error=repr(e));raise
finally:timer.cancel();f.write_text(json.dumps(rep,indent=2));print(json.dumps(rep),flush=True)
