"""Compare the independent 4x4 Schur integrand with original Symanzik polynomials.
This is a numerical algebra audit, not a proof of integration convergence.
"""
import ctypes,json,sys
from pathlib import Path
import numpy as np
import sympy as sp

p=Path(__file__).resolve().parent
legacy=p.parents[1]/'four-loop-analytic-20260927'
if not legacy.exists():
    legacy=p
sys.path.insert(0,str(legacy))
from feynman_four import make_integral

definitions=legacy/'IntegralDefinitions83.json'
if not definitions.exists():
    definitions=legacy/'OriginalTopDefinition.json'
top=json.loads(definitions.read_text())[0]
li,sign=make_integral({'loops':4,'indices':top['Indices']})
U=sp.sympify(str(li.U));F=sp.sympify(str(li.F))
symbols=sorted(U.free_symbols|F.free_symbols,key=str)
u=sp.lambdify(symbols,U,'numpy');f=sp.lambdify(symbols,F,'numpy')
lib=ctypes.CDLL(str(p/'direct.so'))
pointer=ctypes.POINTER(ctypes.c_double)
lib.parametric.argtypes=[pointer,pointer];lib.parametric.restype=ctypes.c_double
rng=np.random.default_rng(412879);reports=[]
for i in range(20):
    a=np.exp(rng.uniform(-2,2,13))
    assignment=dict(zip(map(str,li.Feynman_parameters),a))
    vals=[assignment[str(s)] for s in symbols]
    result=np.zeros(2)
    value=lib.parametric(a.ctypes.data_as(pointer),result.ctypes.data_as(pointer))
    ue=float(u(*vals));fe=float(f(*vals))
    reports.append({'U_relative':float(abs(result[0]/ue-1)),
                    'F_relative':float(abs(result[1]/fe-1)),
                    'IntegrandRelative':abs(value/(24*ue**3/fe**5)-1)})
maximum=max(max(r.values()) for r in reports)
assert maximum<1e-11
(p/'InputPolynomialAudit.json').write_text(json.dumps({
    'All20UAndFChecksPassed':True,'MaxRelativeDifference':maximum,
    'Point':['1/4','3/4'],'Integrand':'24 U^3/F^5',
    'ProjectiveGauge':'last active internal parameter=1',
    'DEOrBoundaryUsed':False,'Checks':reports},indent=2))
