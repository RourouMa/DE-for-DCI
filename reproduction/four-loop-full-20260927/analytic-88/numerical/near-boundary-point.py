"""Supplementary regular-ray evaluation; no direct reference input."""
import json,time,hashlib
from pathlib import Path
from fractions import Fraction as Q
import mpmath as mp
from dlog_taylor import DLogSystem,linear_pullback,top_value
p=Path(__file__).resolve().parent;mp.mp.dps=100;t=time.monotonic()
data=json.loads((p/'DLogNumericalData.json').read_text());b=json.loads((p/'CanonicalBoundary88.json').read_text());s=DLogSystem(data)
v0=[mp.mpf(x) for x in b['Values']];polys=[linear_pullback(l,Q(1),Q(-4),Q(1),Q(-1)) for l in data['LetterPolynomials']]
vc,rv=s.taylor(v0,polys,Q(0),144,regular=True);vals={}
for n in (112,128,144):
 v=s.evaluate(vc[:n+1],Q(1,10));vals[str(n)]=mp.nstr(top_value(data,v,mp.mpf(3)/5,mp.mpf(9)/10),95)
r={'Point':['3/5','9/10'],'CandidateSHA256':data['CandidateSHA256'],'BoundarySHA256':hashlib.sha256((p/'CanonicalBoundary88.json').read_bytes()).hexdigest(),'DirectReferenceUsed':False,'WorkingPrecision':100,'TopByTaylorOrder':vals,'Change112To128':mp.nstr(abs(mp.mpf(vals['112'])-mp.mpf(vals['128'])),20),'Change128To144':mp.nstr(abs(mp.mpf(vals['128'])-mp.mpf(vals['144'])),20),'Seconds':time.monotonic()-t}
(p/'NearBoundaryTop.json').write_text(json.dumps(r,indent=2));print(json.dumps(r),flush=True)
