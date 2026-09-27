"""Direct evaluation of the exported finite Chen sum; no DE matrices are used.

For a nonzero-basepoint polynomial P and word w=(a,suffix):
 P F_w' = P' F_suffix, F_w(0)=0.
 [u^n]F_w = sum_{k=1..deg P} (p_k/p_0)
                    *(k*g[n-k]-(n-k)*f[n-k])/n.
For P=u, f[n]=g[n]/n. All innermost singular letters have been
removed in the physical-boundary expression and are rejected here.
"""
from pathlib import Path
from fractions import Fraction
from decimal import Decimal,localcontext
import gzip,json,sys,time,hashlib
import mpmath as mp
import sympy as sp

out=Path(__file__).resolve().parent; sol=out.parent/'solution'
N=int(sys.argv[1]); precision=int(sys.argv[2]); start=time.time()
mp.mp.dps=precision+20
D=Decimal

def decimal_q(q):
 q=Fraction(q)
 return D(q.numerator)/D(q.denominator)

def ds(v):return format(v,'.'+str(precision)+'g')

with localcontext() as ctx:
 ctx.prec=precision+15
 data=json.loads((out/'ScalarChenAlphabet.json').read_text())
 assert data['ContainsDifferentialEquationMatrices'] is False
 assert not any(k in data for k in ('Rx','Ry','Bx','By','A_x','A_y','Matrices','ResidueMatrices'))
 # This scalar-only input file contains no differential-equation matrix entries.
 xletters=data['XLetters'];yletters=data['YPolynomialLetters'];del data
 records=[]
 with gzip.open(sol/'All88PhysicalBoundaryChen.jsonl.gz','rt') as inp:
  for line in inp:
   if line.strip():records.append(json.loads(line))
 x,y,u=sp.symbols('x y u'); xp=sp.Rational(1,4);yp=sp.Rational(3,4)
 def polys(ls,sub):
  result=[]
  for s in ls:
   p=sp.Poly(sp.sympify(s.replace('^','**'),locals={'x':x,'y':y}).subs(sub),u)
   result.append([Fraction(p.nth(k)) for k in range(p.degree()+1)])
  return result
 px=polys(xletters,{x:1-u});py=polys(yletters,{x:xp,y:1-u})
 zeros=[D(0)]*(N+1)
 exact_pi=D(mp.nstr(mp.pi,precision+15));logtwo=D(mp.nstr(mp.log(2),precision+15));zeta3=D(mp.nstr(mp.zeta(3),precision+15));li4=D(mp.nstr(mp.polylog(4,mp.mpf('0.5')),precision+15))
 b4=li4+logtwo**4/24-exact_pi**4/720+exact_pi**2*(3-6*logtwo+2*logtwo**2)/24+7*zeta3/8-D(5)/4
 constants=[D(1),exact_pi**2,exact_pi**2*logtwo,zeta3,b4]
 all_stats={}; all_values={}
 def evaluate_direction(name,polynomials,target):
  requested={tuple(r[name]) for r in records}
  words={w[k:] for w in requested for k in range(len(w)+1)}
  # Suffix order is a property of the explicit iterated integral definition.
  ordered=sorted(words,key=lambda w:(len(w),w));series={():[D(1)]+[D(0)]*N};values={():D(1)}
  polyd=[[decimal_q(q) for q in p] for p in polynomials]
  normalized=[[decimal_q(q/p[0]) for q in p] if p[0] else None for p in polynomials]
  singularwords=0
  for number,w in enumerate(ordered):
   if not w:continue
   suffix=series[w[1:]];p=polyd[w[0]];f=zeros.copy();degree=len(p)-1
   if p[0]==0:
    assert degree==1 and p[1]!=0,(w,p)
    assert suffix[0]==0,('Divergent basepoint word',name,w)
    singularwords+=1
    for n in range(1,N+1):f[n]=suffix[n]/n
   else:
    q=normalized[w[0]]
    if degree==1:
     q1=q[1]
     for n in range(1,N+1):f[n]=q1*(suffix[n-1]-(n-1)*f[n-1])/n
    elif degree==2:
     q1,q2=q[1:]
     f[1]=q1*suffix[0]
     for n in range(2,N+1):f[n]=(q1*(suffix[n-1]-(n-1)*f[n-1])+q2*(2*suffix[n-2]-(n-2)*f[n-2]))/n
    elif degree==3:
     q1,q2,q3=q[1:]
     f[1]=q1*suffix[0]
     f[2]=(q1*(suffix[1]-f[1])+q2*2*suffix[0])/2
     for n in range(3,N+1):f[n]=(q1*(suffix[n-1]-(n-1)*f[n-1])+q2*(2*suffix[n-2]-(n-2)*f[n-2])+q3*(3*suffix[n-3]-(n-3)*f[n-3]))/n
    else:raise ValueError((name,w,p))
   v=f[-1]
   for c in reversed(f[:-1]):v=v*target+c
   series[w]=f;values[w]=v
   if number%1000==0:print(name,'words',number,'/',len(ordered),'seconds',round(time.time()-start,2),flush=True)
  single=[]
  for w in words:
   if len(w)!=1:continue
   p=polyd[w[0]];pval=sum(c*target**k for k,c in enumerate(p));ref=(pval/p[0]).ln()
   single.append({'LetterIndexZeroBased':w[0],'Value':ds(values[w]),'ExactLogReference':ds(ref),'Difference':ds(values[w]-ref)})
  # Keep values, release millions of expansion coefficients before the other work.
  all_stats[name]={'DistinctWordsIncludingSuffixes':len(words),'RequestedWords':len(requested),'MaximumWordLength':max(map(len,words)),'SingularOuterLettersHandled':singularwords,'WeightOneAnalyticLogChecks':single}
  all_values[name]=values
  return values
 vx=evaluate_direction('x',px,D(3)/4)
 vy=evaluate_direction('y',py,D(1)/4)
 print('Summing',len(records),'explicit terms',flush=True)
 rational_cache={}
 def cq(s):
  if s not in rational_cache:rational_cache[s]=decimal_q(s)
  return rational_cache[s]
 canonical=[D(0)]*88;abssums=[D(0)]*88;counts=[0]*88
 for r in records:
  q=sum(cq(c)*k for c,k in zip(r['c'],constants));value=q*vx[tuple(r['x'])]*vy[tuple(r['y'])]
  canonical[r['i']-1]+=value;abssums[r['i']-1]+=abs(value);counts[r['i']-1]+=1
 inv=json.loads((out/'NativeInverseAtPoint.json').read_text());native=[sum(cq(c)*v for c,v in zip(row,canonical)) for row in inv]
 topdirect=canonical[0]/((D(1)/16-1)*(D(9)/16-1)**4)
 assert abs(native[0]-topdirect)<D(10)**(-precision-8)
 report={'Method':'Explicit finite Chen-word sum with polynomial coefficient recurrence; no differential-equation matrices used','Point':['1/4','3/4'],'SeriesOrder':N,'RequestedDecimalPrecision':precision,'WorkingDecimalPrecision':precision+15,'InputWordFileSHA256':hashlib.sha256((sol/'All88PhysicalBoundaryChen.jsonl.gz').read_bytes()).hexdigest(),'ScalarAlphabetSHA256':hashlib.sha256((out/'ScalarChenAlphabet.json').read_bytes()).hexdigest(),'DifferentialEquationMatricesRead':False,'RuntimeDataInputs':['../solution/All88PhysicalBoundaryChen.jsonl.gz','ScalarChenAlphabet.json','NativeInverseAtPoint.json'],'InverseRationalMatrixAtPointSHA256':hashlib.sha256((out/'NativeInverseAtPoint.json').read_bytes()).hexdigest(),'TopTerms':counts[0],'AllComponentTerms':len(records),'BasisConstantMonomials':['1','Pi^2','Pi^2*Log[2]','Zeta[3]','B4'],'ExactBoundaryB4Numerical':ds(b4),'WordStatistics':all_stats,'CanonicalValues':[ds(v) for v in canonical],'NativeValues':[ds(v) for v in native],'TopValue':ds(topdirect),'TopCanonicalAbsoluteTermSum':ds(abssums[0]),'TopCanonicalCancellationRatio':ds(abssums[0]/abs(canonical[0])),'Seconds':time.time()-start,'PrecisionQualification':'Arithmetic precision is not a convergence claim; compare independent truncation orders.'}
 (out/f'ChenEvaluation-N{N}-P{precision}.json').write_text(json.dumps(report,indent=2)+'\n')
 with gzip.open(out/f'WordValues-N{N}-P{precision}.jsonl.gz','wt') as handle:
  for axis,values in all_values.items():
   for w,v in values.items():handle.write(json.dumps({'axis':axis,'word':w,'value':ds(v)},separators=(',',':'))+'\n')
 print('TOP',ds(topdirect),'SECONDS',round(time.time()-start,2),flush=True)
