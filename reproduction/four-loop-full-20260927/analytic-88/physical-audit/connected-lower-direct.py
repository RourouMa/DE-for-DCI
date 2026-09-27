import json,time,sys,hashlib
from pathlib import Path
from pySecDec.integral_interface import IntegralLibrary,series_to_sympy
out=Path(__file__).resolve().parent
name=sys.argv[1] if len(sys.argv)>1 else 'ladder1t0';seed=int(sys.argv[2]) if len(sys.argv)>2 else 2026092702
work=Path('/home/april/Documents/Codex/2026-09-10/new-chat/work/numerical');library=work/name/(name+'_pylink.so')
lib=IntegralLibrary(str(library));lib.use_Qmc(transform='korobov3',epsrel=1e-6,epsabs=1e-9,minn=100000,minm=64,maxeval=300000000,cputhreads=2,seed=seed)
t=time.time();v=lib(epsrel=1e-6,epsabs=1e-9,number_of_threads=2,wall_clock_limit=1800)
r={'Library':str(library),'LibrarySHA256':hashlib.sha256(library.read_bytes()).hexdigest(),'Name':name,'Seed':seed,'Point':['1/4','3/4'],'Method':'Direct original compiled pySecDec momentum-space integral, QMC korobov3','DEOrAnalyticBoundaryUsed':False,'Seconds':time.time()-t,'Raw':list(v),'Sympy':list(series_to_sympy(v[-1]))}
(out/f'ConnectedLowerDirect-{name}-{seed}.json').write_text(json.dumps(r,indent=2));print(json.dumps(r),flush=True)
