from dlog_taylor import *
mp.mp.dps=60
start=time.time();data=json.loads((BASE/'DLogNumericalData.json').read_text());spec=json.loads((BASE/'OneLoopValidation.json').read_text())
sys=DLogSystem(data,spec['Indices']);v0=[mp.mpf(0),mp.mpf(0),mp.mpf(0),mp.mpf(1)/2]
x=mp.mpf(1)/4;y=mp.mpf(3)/4;exact=[2*mp.log(x)*mp.log(y),-mp.log(y),-mp.log(x),mp.mpf(1)/2];results=[]
for slope,degree,step in [(4,40,Q(1,10)),(5,56,Q(1,20))]:
 v,audit=sys.from_regular_corner(v0,slope,Q(1,20),degree,step=step)
 err=max(abs(z-w) for z,w in zip(v,exact));print('slope',slope,'degree',degree,'error',mp.nstr(err,12),flush=True)
 results.append({'Slope':slope,'Degree':degree,'Step':str(step),'MaxError':mp.nstr(err,40),'Values':[mp.nstr(z,50) for z in v],'Audit':audit})
report={'Test':'Four exact one-loop functions embedded as a closed subsystem of full88 canonical DE','CanonicalZeroBasedIndices':spec['Indices'],'WorkingPrecision':60,'Results':results,'Seconds':time.time()-start,'Passed':all(mp.mpf(z['MaxError'])<mp.mpf('1e-25') for z in results)}
(BASE/'OneLoopNumericalValidation.json').write_text(json.dumps(report,indent=2));print('PASS',report['Passed'],'seconds',report['Seconds'],flush=True)
