from pathlib import Path
from itertools import permutations,product
from fractions import Fraction as Q
import json,hashlib
root=Path(__file__).resolve().parents[2];out=Path(__file__).resolve().parent
old=Path('/home/april/Documents/Codex/2026-09-10/new-chat/outputs/numerical-verification')
new=json.loads((root/'DE-for-DCI-publish/reproduction/four-loop-full-20260927/IntegralDefinitions88.json').read_text());orig=json.loads((root/'four-loop-analytic-20260927/IntegralDefinitions83.json').read_text());masters=json.loads((old/'masters.json').read_text())['ladder'];checks=json.loads((old/'comparison.json').read_text());checks={a['index']:a for a in checks if a['family']=='ladder'}
vals=json.loads((root/'four-loop-analytic-20260927/Lower30AnalyticValues.json').read_text())[0];values={i:float(v) for i,v in zip(vals['Indices'],vals['Values'])}
def canon(a,L):
 chain=[(i,i+1) for i in range(L-1)];pairs=chain+[(i,j) for i in range(L) for j in range(i+1,L) if (i,j) not in chain];pos={ij:k for k,ij in enumerate(pairs)}
 assert a[-L:]==[1]*L
 out=[]
 for lp in permutations(range(L)):
  for sa,sb in product((False,True),repeat=2):
   ep=[0,1,2,3]
   if sa:ep[0],ep[2]=ep[2],ep[0]
   if sb:ep[1],ep[3]=ep[3],ep[1]
   b=[a[4*lp[i]+ep[j]] for i in range(L) for j in range(4)]
   b += [a[4*L+pos[tuple(sorted((lp[i],lp[j])))]] for i,j in pairs]
   out.append(tuple(b+[1]*L))
 return min(out)
def legacy_terms(m):
 d={}
 for t in m['terms']:
  key=(t['loops'],canon(t['indices'],t['loops']));d[key]=d.get(key,Q(0))+Q(str(t['coefficient']))
 return {k:v for k,v in d.items() if v}
matches=[]
for m in new[53:83]:
 key=(m['Loops'],canon(m['Indices'],m['Loops']))
 hit=[z['index'] for z in masters if legacy_terms(z)=={key:Q(1)}]
 if not hit:continue
 oldi=hit[0];c=checks.get(oldi,{})
 # Number of connected components of internal graph.
 L=m['Loops'];a=m['Indices'];pairs=[(i,i+1) for i in range(L-1)]+[(i,j) for i in range(L) for j in range(i+1,L) if j!=i+1];adj=[set() for _ in range(L)]
 for (i,j),p in zip(pairs,a[4*L:]):
  if p>0:adj[i].add(j);adj[j].add(i)
 seen=set();stack=[0]
 while stack:
  v=stack.pop()
  if v in seen:continue
  seen.add(v);stack.extend(adj[v]-seen)
 row={'CurrentIndex':m['Index'],'OldPhysicalIndex':oldi,'Loops':L,'ConnectedInternalGraph':len(seen)==L,'ExactIndependentSymmetryMatch':True,'CurrentAnalyticValue':values[m['Index']]}
 if 'value' in c and 'sdev' in c:
  row.update({'DirectNumericalValue':c['value'],'DirectReportedError':c['sdev'],'PullVsCurrentAnalytic':(abs(c['value']-values[m['Index']])/c['sdev'] if c['sdev'] else None),'LegacyNumericalSource':str(old/c['source'])})
 matches.append(row)
origchecks=[canon(a['Indices'],a['Loops'])==canon(b['Indices'],b['Loops']) and a['Loops']==b['Loops'] for a,b in zip(orig,new)]
rep={'Original83PreservedModuloIndependentLoopAndExternalGroupPermutations':all(origchecks),'Original83MappingFailures':[i+1 for i,v in enumerate(origchecks) if not v],'DirectLegacySymmetryMatches':len(matches),'ConnectedThreeLoopMatches':[r for r in matches if r['Loops']==3 and r['ConnectedInternalGraph']],'AllMatches':matches,'Method':'Independent Python graph relabeling; no native CanonicalIntegral or DE used','ExternalPermutations':'Independent (1 3) and (2 4), preserving x/y groups','NoScaleFactorsNeeded':True,'FreshConnectedThreeLoopQMC':'Running separately, not claimed passed'}
(out/'LegacyPhysicalMappingAudit.json').write_text(json.dumps(rep,indent=2));print(json.dumps(rep,indent=2))
