"""Evaluate a candidate S^4 spectral formula for the coalesced ladder.

This is a new derivation under validation, not an accepted boundary input.
The two parity sums have an exact generalized-hypergeometric form.
Gamma-ratio asymptotics and Hurwitz zeta accelerate their common tail.
"""
import json,math
from pathlib import Path
from fractions import Fraction as Q
import sympy as sp
import mpmath as mp
ROOT=Path(__file__).resolve().parent

def fraction(x):
    x=sp.Rational(x);return Q(int(x.p),int(x.q))

def mul(a,b,K):
    return [sum((a[j]*b[n-j] for j in range(n+1)),Q(0)) for n in range(K+1)]

def exp_series(a,K):
    e=[Q(1)]+[Q(0)]*K
    for n in range(1,K+1):e[n]=sum((j*a[j]*e[n-j] for j in range(1,n+1)),Q(0))/n
    return e

def parity_tail_coefficients(L,K,a,b,linear,den1,den2):
    log=[Q(0)]+[2*Q((-1)**(k+1),k*(k+1))*fraction(sp.bernoulli(k+1,a)-sp.bernoulli(k+1,b)) for k in range(1,K+1)]
    e=exp_series(log,K)
    for d in [den1,den2]:e=mul(e,[Q((-1)**j*math.comb(L+j-1,j))*d**j for j in range(K+1)],K)
    return [e[n]+(linear*e[n-1] if n else 0) for n in range(K+1)]

def spectral_boundary(L,N=100,K=50,dps=80):
    mp.mp.dps=dps
    def term(m):
        h=mp.mpf(m)
        even=mp.pi**2/8*(2*h+mp.mpf('1.5'))*(mp.rf(mp.mpf('1.5'),m)/mp.factorial(m))**2/((2*h+1)*(2*h+2))**L
        odd=-2*(2*h+mp.mpf('2.5'))*(mp.rf(2,m)/mp.rf(mp.mpf('1.5'),m))**2/((2*h+2)*(2*h+3))**L
        return even+odd
    a=parity_tail_coefficients(L,K,sp.Rational(3,2),1,Q(3,4),Q(1,2),Q(1))
    b=parity_tail_coefficients(L,K,2,sp.Rational(3,2),Q(5,4),Q(1),Q(3,2))
    tail=mp.pi/4**L*mp.fsum(mp.mpf((u-v).numerator)/(u-v).denominator*mp.zeta(2*L-2+k,N) for k,(u,v) in enumerate(zip(a,b)) if u!=v)
    return mp.fsum(term(m) for m in range(N))+tail

if __name__=='__main__':
    rows=[]
    for L in [2,3,4]:
        a=spectral_boundary(L,80,40,75);b=spectral_boundary(L,120,56,90)
        row={'Loops':L,'Value':str(b),'TruncationSettingDifference':str(abs(a-b)),
             'Settings':[[80,40,75],[120,56,90]],'IndependentParametricValidationPending':True}
        rows.append(row);print(row,flush=True)
    (ROOT/'SpecialPointSpectralCandidate.json').write_text(json.dumps({'Status':'derived_candidate_under_validation','Point':[1,1],'Rows':rows},indent=2)+'\n')
