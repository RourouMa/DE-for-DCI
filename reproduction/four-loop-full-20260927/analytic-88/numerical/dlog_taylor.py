#!/usr/bin/env python3
"""Arbitrary-precision Taylor continuation of the verified rational dlog system.
The solver never reads sector-decomposition estimates or fits boundary data.
"""
from __future__ import annotations
from fractions import Fraction as Q
from math import comb
from pathlib import Path
import argparse, hashlib, json, time
import mpmath as mp
BASE = Path(__file__).resolve().parent

def frac(z): return Q(int(z[0]), int(z[1]))
def mnum(q): return mp.mpf(q.numerator)/q.denominator

def mul(a,b):
    c=[Q(0)]*(len(a)+len(b)-1)
    for i,x in enumerate(a):
        for j,y in enumerate(b): c[i+j]+=x*y
    return c

def power(a,n):
    out=[Q(1)]
    for _ in range(n): out=mul(out,a)
    return out

def linear_pullback(poly,x0,dx,y0,dy):
    out=[Q(0)]
    for (px,py),r in poly:
        term=mul(power([x0,dx],px),power([y0,dy],py));q=frac(r)
        if len(out)<len(term):out += [Q(0)]*(len(term)-len(out))
        for i,v in enumerate(term):out[i]+=q*v
    while len(out)>1 and out[-1]==0:out.pop()
    return out

def shift(poly,c):
    return [sum((a*comb(j,i)*c**(j-i) for j,a in enumerate(poly) if j>=i),Q(0)) for i in range(len(poly))]

def log_kernel(poly,center,n):
    p=shift(poly,center);valuation=0
    while p and p[0]==0:valuation+=1;p.pop(0)
    if not p:raise ValueError('Path lies identically on an alphabet divisor')
    f=[]
    for k in range(n):
        z=(k+1)*p[k+1] if k+1<len(p) else Q(0)
        z-=sum((p[j]*f[k-j] for j in range(1,min(k,len(p)-1)+1)),Q(0))
        f.append(z/p[0])
    return valuation,[mnum(z) for z in f]

class DLogSystem:
    def __init__(self,data,indices=None):
        self.data=data;self.ids=indices if indices is not None else list(range(data['Dimension']))
        self.n=len(self.ids);loc={v:i for i,v in enumerate(self.ids)};self.edges=[]
        for cm in data['ResidueMatrices']:
            e=[]
            for i,j,c in cm:
                if i not in loc:continue
                if j not in loc:raise ValueError(f'Subsystem is not closed: {i} -> {j}')
                e.append((loc[i],loc[j],frac(c)))
            self.edges.append(e)
        deps=[set() for _ in self.ids]
        for e in self.edges:
            for i,j,c in e:
                if c:deps[i].add(j)
        todo=set(range(self.n));self.order=[]
        while todo:
            ready=sorted(i for i in todo if not(deps[i]&todo))
            if not ready:raise ValueError('Residue dependency graph is not acyclic')
            self.order+=ready;todo-=set(ready)
        self.me=[[(i,j,mnum(c)) for i,j,c in e] for e in self.edges]
    def action(self,v):
        out=[]
        for e in self.me:
            w=[mp.mpf(0)]*self.n
            for i,j,c in e:
                if v[j]:w[i]+=c*v[j]
            out.append(w)
        return out
    def taylor(self,v0,polys,center,degree,regular=False):
        kernels=[log_kernel(p,center,degree) for p in polys]
        r=[{} for _ in self.ids]
        for (val,f),edges in zip(kernels,self.edges):
            if val:
                if not regular:raise ValueError('Unexpected singular expansion center')
                for i,j,c in edges:r[i][j]=r[i].get(j,Q(0))+val*c
        mr=[[(j,mnum(c)) for j,c in z.items() if c] for z in r]
        rv=[mp.fsum(c*v0[j] for j,c in z) for z in mr]
        if max(map(abs,rv),default=0)>mp.mpf(10)**(-mp.mp.dps+12):
            raise ValueError('Boundary vector violates R v0 = 0: '+mp.nstr(max(map(abs,rv)),12))
        vc=[list(v0)];cv=[self.action(v0)]
        for n in range(1,degree+1):
            rhs=[mp.mpf(0)]*self.n
            for k,(valuation,f) in enumerate(kernels):
                for a in range(n):
                    z=f[n-1-a]
                    if not z:continue
                    q=cv[a][k]
                    for i,val in enumerate(q):
                        if val:rhs[i]+=z*val
            vn=[mp.mpf(0)]*self.n
            for i in self.order:
                vn[i]=(rhs[i]+mp.fsum(c*vn[j] for j,c in mr[i]))/n
            vc.append(vn);cv.append(self.action(vn))
        return vc,max(map(abs,rv),default=mp.mpf(0))
    @staticmethod
    def evaluate(vc,h):
        h=mnum(h);out=list(vc[-1])
        for v in reversed(vc[:-1]):out=[a*h+b for a,b in zip(out,v)]
        return out
    def segment(self,v0,start,end,degree=56,step=Q(1,10)):
        x0,y0=map(Q,start);x1,y1=map(Q,end)
        polys=[linear_pullback(p,x0,x1-x0,y0,y1-y0) for p in self.data['LetterPolynomials']]
        center=Q(0);v=list(v0);audit=[]
        while center<1:
            h=min(step,Q(1)-center)
            vc,_=self.taylor(v,polys,center,degree)
            v=self.evaluate(vc,h)
            tail=max((abs(vc[-1][i]*mnum(h)**degree) for i in range(self.n)),default=mp.mpf(0))
            audit.append({'center':str(center),'step':str(h),'last_term_max':mp.nstr(tail,12)})
            center+=h
        return v,audit
    def from_regular_corner(self,v0,slope=4,s0=Q(1,20),degree=64,target=(Q(1,4),Q(3,4)),step=Q(1,20)):
        pol=[linear_pullback(p,Q(1),Q(-slope),Q(1),Q(-1)) for p in self.data['LetterPolynomials']]
        vc,rv=self.taylor(v0,pol,Q(0),degree,regular=True)
        start=(Q(1)-slope*s0,Q(1)-s0);vstart=self.evaluate(vc,s0)
        v,segments=self.segment(vstart,start,target,degree,step)
        return v,{'slope':slope,'initial_s':str(s0),'start':list(map(str,start)),
                  'boundary_residue_residual':mp.nstr(rv,12),'segments':segments,
                  'initial_taylor_last_term_max':mp.nstr(max(abs(z)*mnum(s0)**degree for z in vc[-1]),12)}

def poly_value(p,x,y):return mp.fsum(mnum(frac(c))*x**a*y**b for (a,b),c in p)
def top_value(data,v,x,y):
    return mp.fsum(v[z['Index']]*poly_value(z['Numerator'],x,y)/poly_value(z['Denominator'],x,y) for z in data['TopCoefficients'])

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--boundary',required=True);ap.add_argument('--output',required=True)
    ap.add_argument('--dps',type=int,default=60);ap.add_argument('--degree',type=int,default=64);ap.add_argument('--slope',type=int,default=4)
    ap.add_argument('--step',default='1/20');ap.add_argument('--initial-s',default='1/20');a=ap.parse_args()
    mp.mp.dps=a.dps;t=time.time();data=json.loads((BASE/'DLogNumericalData.json').read_text());bd=json.loads(Path(a.boundary).read_text())
    vals=bd.get('Values',bd.get('values'))
    if len(vals)!=88:raise ValueError('Expected all 88 canonical regular boundary values')
    v0=[mp.mpf(z) for z in vals];sys=DLogSystem(data);v,au=sys.from_regular_corner(v0,a.slope,Q(a.initial_s),a.degree,step=Q(a.step));x=mp.mpf(1)/4;y=mp.mpf(3)/4
    result={'CandidateSHA256':data['CandidateSHA256'],'BoundaryFile':str(Path(a.boundary).resolve()),
            'BoundarySHA256':hashlib.sha256(Path(a.boundary).read_bytes()).hexdigest(),'Point':['1/4','3/4'],
            'WorkingPrecision':a.dps,'TaylorDegree':a.degree,'TopValue':mp.nstr(top_value(data,v,x,y),a.dps-5),
            'CanonicalValues':[mp.nstr(z,a.dps-5) for z in v],'PathAudit':au,'Seconds':time.time()-t,
            'DirectNumericalEstimateUsedForBoundary':False,'PrecisionStatus':'Requires independent order/precision/path comparison'}
    Path(a.output).write_text(json.dumps(result,indent=2));print(json.dumps({k:result[k] for k in ['TopValue','Seconds','PrecisionStatus']}),flush=True)
if __name__=='__main__':main()
