"""Enumerate every finite Chen coefficient of all 88 canonical components."""
from fractions import Fraction as Q
from pathlib import Path
from functools import lru_cache
import json,gzip,time
root=Path(__file__).resolve().parent;D=json.loads((root/'ChenResidues.json').read_text());n=D['Dimension'];maxlen=D['MaximumWordLengthBound']
def matrix(ts):
 a={}
 for i,j,c in ts:a.setdefault(i,[]).append((j,Q(c)))
 return a
X=list(map(matrix,D['Rx']));Y=list(map(matrix,D['Ry']))
def mul(v,a):
 out={}
 for i,c in v:
  for j,d in a.get(i,()):out[j]=out.get(j,Q(0))+c*d
 return tuple(sorted((j,c) for j,c in out.items() if c))
@lru_cache(maxsize=300000)
def succ(v,which):return tuple((j,vv) for j,a in enumerate(X if which=='x' else Y) if (vv:=mul(v,a)))
def encode(v):return [[i,str(c)] for i,c in v]
start=time.time();total=0;reps=[]
with gzip.open(root/'All88FormalChen.jsonl.gz','wt') as f:
 for target in range(n):
  ylevel=[((),((target,Q(1)),))];counts={};count=0
  for ly in range(maxlen+2):
   if not ylevel:break
   assert ly<=maxlen
   ynext=[]
   for wy,v in ylevel:
    xlevel=[((),v)]
    for lx in range(maxlen-ly+2):
     if not xlevel:break
     assert lx+ly<=maxlen
     xnext=[]
     for wx,c in xlevel:
      f.write(json.dumps({'i':target+1,'x':wx,'y':wy,'c':encode(c)},separators=(',',':'))+'\n');count+=1;total+=1;counts[lx+ly]=counts.get(lx+ly,0)+1
      xnext.extend((wx+(j,),vv) for j,vv in succ(c,'x'))
     xlevel=xnext
    ynext.extend((wy+(j,),vv) for j,vv in succ(v,'y'))
   ylevel=ynext
  rec={'Index':target+1,'Triples':count,'MaximumWordLength':max(counts),'ByWordLength':counts};reps.append(rec)
  print(rec,flush=True)
rep={'BoundarySubstituted':False,'CandidateSHA256':D['CandidateSHA256'],'CanonicalComponents':n,'Triples':total,'MaximumWordLength':max(r['MaximumWordLength'] for r in reps),'AllHigherLayersExactlyZero':True,'Components':reps,'Seconds':time.time()-start}
(root/'All88FormalIterationReport.json').write_text(json.dumps(rep,indent=2));print('ALL',total,'seconds',time.time()-start,flush=True)
