"""Predeclared independent direct-integration checks; never imports DE outputs."""
import argparse,hashlib,json,os,time
from pathlib import Path
from pySecDec.integral_interface import IntegralLibrary,series_to_sympy
p=Path(__file__).resolve().parent;root=p.parents[1];legacy=root/'four-loop-analytic-20260927';name='four_top_p1';so=legacy/'numerical-work'/name/(name+'_pylink.so')
plans={
 'vegas':{'Integrator':'Vegas','Seed':271828,'MaxEval':1000000000,'WallClockLimit':600,'Threads':4,'EpsRel':5e-5,'EpsAbs':1e-8,'NStart':1000000,'NIncrease':500000},
 'qmc-default':{'Integrator':'Qmc','Seed':314159,'MaxEval':4000000000,'WallClockLimit':900,'Threads':4,'EpsRel':5e-5,'EpsAbs':1e-8,'Transform':'korobov3','FitFunction':'default','MinM':128},
 'qmc-polysingular':{'Integrator':'Qmc','Seed':161803,'MaxEval':4000000000,'WallClockLimit':900,'Threads':4,'EpsRel':5e-5,'EpsAbs':1e-8,'Transform':'korobov3','FitFunction':'polysingular','MinM':128}}
a=argparse.ArgumentParser();a.add_argument('mode',choices=plans);v=a.parse_args();cfg=plans[v.mode]
rep={'PredeclaredPlan':cfg,'Point':['1/4','3/4'],'IntegralIndex':1,'Loops':4,'Library':str(so),'LibrarySHA256':hashlib.sha256(so.read_bytes()).hexdigest(),'PID':os.getpid(),'StartedUnix':time.time(),'DirectEstimateUsedForBoundary':False,'DEOrAnalyticReferenceRead':False,'StoppingRule':'Requested error or fixed maxeval or fixed wall clock only; no reference-value stopping'}
report=p/f'DirectStrong-{v.mode}.json';report.write_text(json.dumps(rep,indent=2));print(json.dumps(rep),flush=True)
lib=IntegralLibrary(str(so))
if v.mode=='vegas':lib.use_Vegas(epsrel=cfg['EpsRel'],epsabs=cfg['EpsAbs'],seed=cfg['Seed'],maxeval=cfg['MaxEval'],mineval=1000000,nstart=cfg['NStart'],nincrease=cfg['NIncrease'],nbatch=10000,flags=0)
else:lib.use_Qmc(transform=cfg['Transform'],fitfunction=cfg['FitFunction'],epsrel=cfg['EpsRel'],epsabs=cfg['EpsAbs'],minn=100000,minm=cfg['MinM'],maxeval=cfg['MaxEval'],cputhreads=cfg['Threads'],seed=cfg['Seed'])
start=time.monotonic()
try:
 val=lib(epsrel=cfg['EpsRel'],epsabs=cfg['EpsAbs'],number_of_threads=cfg['Threads'],wall_clock_limit=cfg['WallClockLimit'])
 rep.update(Status='Computed',Seconds=time.monotonic()-start,SympyResult=list(series_to_sympy(val[-1])),RawResult=list(val))
except Exception as e:rep.update(Status='Failed',Seconds=time.monotonic()-start,Error=repr(e));raise
finally:report.write_text(json.dumps(rep,indent=2));print(json.dumps(rep),flush=True)
