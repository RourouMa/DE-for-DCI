import json,time,sys,hashlib,threading,os
from pathlib import Path
from pySecDec.integral_interface import IntegralLibrary,series_to_sympy
out=Path(__file__).resolve().parent;seed=2026092724
library=Path('/home/april/Documents/Codex/2026-09-10/new-chat/work/numerical/ladder1t0/ladder1t0_pylink.so')
f=out/f'ConnectedLowerDirect-ladder1t0-{seed}.json'
r={'Library':str(library),'LibrarySHA256':hashlib.sha256(library.read_bytes()).hexdigest(),'Name':'ladder1t0','Seed':seed,'Point':['1/4','3/4'],'Method':'Direct original compiled pySecDec momentum-space integral, QMC korobov3','DEOrAnalyticBoundaryUsed':False,'NumberOfAmplitudeThreads':1,'QMCInternalThreads':2,'MinM':16,'MinN':1000,'MaxEval':20000000,'RequestedRelativeError':2e-5,'WallClockLimit':240,'ShutdownGraceSeconds':60,'AcceptanceEligible':True,'Status':'Running','StartedUnix':time.time(),'PID':os.getpid()};f.write_text(json.dumps(r,indent=2));t=time.time()
def timeout():
 r.update(Status='TimedOut',Seconds=time.time()-t,Reason='Fixed 240s +60s grace; no estimate-based stopping');f.write_text(json.dumps(r,indent=2));os._exit(124)
timer=threading.Timer(300,timeout);timer.start()
try:
 lib=IntegralLibrary(str(library));lib.use_Qmc(transform='korobov3',epsrel=2e-5,epsabs=1e-8,minn=1000,minm=16,maxeval=20000000,cputhreads=2,seed=seed)
 v=lib(epsrel=2e-5,epsabs=1e-8,number_of_threads=1,wall_clock_limit=240)
 r.update(Status='Computed',Seconds=time.time()-t,Raw=list(v),Sympy=list(series_to_sympy(v[-1])))
finally:
 timer.cancel();f.write_text(json.dumps(r,indent=2));print(json.dumps(r),flush=True)
