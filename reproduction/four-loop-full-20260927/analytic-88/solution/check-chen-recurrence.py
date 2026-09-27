"""Exact coefficient-level checks, independent of enumeration traversal order."""
from fractions import Fraction as Q
from pathlib import Path
from functools import lru_cache
import gzip,json,time
root=Path(__file__).resolve().parent;D=json.loads((root/'ChenResidues.json').read_text());cb=json.loads((root/'CanonicalBoundaryCoefficients.json').read_text());cm=[[Q(v) for v in row] for row in cb['CoefficientMatrix']]
def mat(t):
 a={}
 for i,j,c in t:a.setdefault(j,[]).append((i,Q(c)))
 return a
M=list(map(mat,D['Ry']+D['Rx'])); data={};start=time.time()
with gzip.open(root/'All88PhysicalBoundaryChen.jsonl.gz','rt') as f:
 for line in f:
  r=json.loads(line);data.setdefault((tuple(r['x']),tuple(r['y'])),[]).append((r['i']-1,tuple(Q(c) for c in r['c'])))
data={k:tuple(sorted(v)) for k,v in data.items()}
@lru_cache(maxsize=200000)
def mul(k,v):
 out={}
 for j,vc in v:
  for i,q in M[k].get(j,()):
   vv=out.setdefault(i,[Q(0)]*5)
   for z,c in enumerate(vc):
    if c:vv[z]+=q*c
 return tuple((i,tuple(v)) for i,v in sorted(out.items()) if any(v))
checks=0;fail=[]
for (wx,wy),v in data.items():
 for k in range(len(D['Ry'])):
  rhs=mul(k,v); lhs=data.get((wx,(k,)+wy),())
  if rhs!=lhs:fail.append(('y',wx,wy,k))
  checks+=1
 if not wy:
  for k in range(len(D['Rx'])):
   rhs=mul(len(D['Ry'])+k,v);lhs=data.get(((k,)+wx,()),())
   if rhs!=lhs:fail.append(('x-initial',wx,k))
   checks+=1
boundary=tuple((i,tuple(v)) for i,v in enumerate(cm) if any(v));base=(data.get(((),()),())==boundary)
rep={'CoefficientRecurrencesChecked':checks,'AllYRecurrencesExactlyZero':not any(f[0]=='y' for f in fail),'AllInitialXRecurrencesExactlyZero':not any(f[0]=='x-initial' for f in fail),'CanonicalBoundaryExactlyMatched':base,'FailureCount':len(fail),'TerminatingHigherWeightRecurrencesIncluded':True,'Arithmetic':'fractions.Fraction, five independent boundary monomials','CandidateSHA256':D['CandidateSHA256'],'Seconds':time.time()-start}
(root/'ChenRecurrenceCertificate.json').write_text(json.dumps(rep,indent=2)); print(rep,flush=True)
assert not fail and base,fail[:10]
