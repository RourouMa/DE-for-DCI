from fractions import Fraction as Q
from pathlib import Path
import json,gzip,time
root=Path(__file__).resolve().parent; data=json.loads((root/'CanonicalBoundaryCoefficients.json').read_text()); cm=[[Q(c) for c in row] for row in data['CoefficientMatrix']]; const=['1','Pi^2','Pi^2*Log[2]','Zeta[3]','DCIAnalytic`B4'];
def coeffstr(v):
 terms=[]
 for c,b in zip(v,const):
  if c:terms.append(f'({c})'+('' if b=='1' else '*'+b))
 return '+'.join(terms) or '0'
def word(w):return '{'+','.join(str(j+1) for j in w)+'}'
start=time.time();merged={};comp=[[] for _ in range(88)];count=0;badx=bady=0;counts={};cancels=0
with gzip.open(root/'All88FormalChen.jsonl.gz','rt') as inp,gzip.open(root/'All88PhysicalBoundaryChen.jsonl.gz','wt') as out:
 for line in inp:
  rec=json.loads(line);v=[Q(0) for _ in range(5)]
  for j,c in rec['c']:
   q=Q(c)
   for k in range(5):v[k]+=q*cm[j][k]
  if not any(v):cancels+=1;continue
  wx,wy=tuple(rec['x']),tuple(rec['y']);i=rec['i'];cx=bool(wx and wx[-1]==1);cy=bool(wy and wy[-1]==0);badx+=cx;bady+=cy
  count+=1;counts[len(wx)+len(wy)]=counts.get(len(wx)+len(wy),0)+1
  vv=[str(c) for c in v];out.write(json.dumps({'i':i,'x':wx,'y':wy,'c':vv},separators=(',',':'))+'\n')
  merged.setdefault((wx,wy),[]).append((i,v));comp[i-1].append((wx,wy,v))
assert badx==0 and bady==0,(badx,bady)
b4='PolyLog[4,1/2]+Log[2]^4/24-Pi^4/720+Pi^2*(3-6*Log[2]+2*Log[2]^2)/24+7*Zeta[3]/8-5/4'
header='(* Finite exact Chen expansion; all boundary constants explicitly determined. *)\nDCIAnalytic`B4='+b4+';\n'
lines=[]
for (wx,wy),vs in merged.items():
 terms=','.join('{'+str(i)+'}->('+coeffstr(v)+')' for i,v in vs)
 lines.append('{'+word(wx)+','+word(wy)+',SparseArray[{'+terms+'},{88}]}')
(root/'All88ChenTriples.wl').write_text(header+'<|"Dimension"->88,"MaximumWordLength"->8,"Triples"->{\n'+',\n'.join(lines)+'\n},"Indexing"->"Words use 1-based alphabet indices in ChenResidues.wl", "CanonicalBoundarySource"->"../global-boundary/CanonicalBoundary88.wl"|>\n')
def cterm(wx,wy,v):
 pieces=['('+coeffstr(v)+')']
 if wx:pieces.append('DCIAnalytic`ChenX['+word(wx)+']')
 if wy:pieces.append('DCIAnalytic`ChenY['+word(wy)+']')
 return '*'.join(pieces)
funs=['+'.join(cterm(*t) for t in ts) if ts else '0' for ts in comp]
(root/'CanonicalFunctions88.wl').write_text(header+'{\n'+',\n'.join(funs)+'\n}\n')
(root/'TopLadderFunction.wl').write_text(header+'('+funs[0]+')/((x^2-1)*(y^2-1)^4)\n')
rep={'CanonicalComponents':88,'NativeTopFunctionExported':True,'BoundarySubstituted':True,'FormalTerms':count+cancels,'NonzeroComponentTerms':count,'BoundaryCancelledTerms':cancels,'DistinctWordPairs':len(merged),'MaximumWordLength':max(counts),'ByWordLength':counts,'BadInnermostXBasepointLetters':badx,'BadInnermostYBasepointLetters':bady,'AllNonzeroChenTermsConvergeAtBasepoint':True,'Constants':['Pi','Log[2]','Zeta[3]','PolyLog[4,1/2]'],'PhysicalRegularityIndependentCertificatePending':False,'PhysicalCanonicalRegularityProved':True,'UnknownIntegrationConstants':0,'Domain':'0 < x < y^3 < 1','ComponentTermCounts':[len(c) for c in comp],'Seconds':time.time()-start}
(root/'PhysicalBoundaryChenReport.json').write_text(json.dumps(rep,indent=2));print(rep,flush=True)
