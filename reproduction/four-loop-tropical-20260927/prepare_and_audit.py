"""Prepare inputs and verify exact U/F against the established momentum construction."""
import hashlib,json,sys
from pathlib import Path
from fractions import Fraction as Q
import sympy as sp
from ladder_input import ladder,symanzik_from_forests,merged_boundary
import pySecDec as psd

out=Path(__file__).resolve().parent;root=out.parent
# Local momentum constructor; no external workspace dependency.
native_file=root/'four-loop-full-20260927/IntegralDefinitions88.json'
native=json.loads(native_file.read_text())
from feynman_four import make_integral
plans=[('top',4,'1/4','3/4'),('boundary',4,'1','1'),('oneloop',1,'1/4','3/4'),('boundary_merged',4,'1','1')]
reports=[]
for name,L,x,y in plans:
    inp,exact=merged_boundary(100000,20260927) if name=='boundary_merged' else ladder(L,x,y,100000,20260927)
    native_match=None
    if name in ('top','boundary','oneloop'):
        native_index=83 if name=='oneloop' else 1
        assert exact['NativeIndices']==native[native_index-1]['Indices']
        native_match=native_index
    U,F=symanzik_from_forests(exact)
    if name=='boundary_merged':
        ks=[f'k{i}' for i in range(1,5)]
        props=[p for k in ks for p in [f'{k}**2-1',f'({k}-q)**2-1']]
        props += [f'(k{i}-k{i+1})**2' for i in range(1,4)]
        powers=[1,2,0,2,0,2,1,2,1,1,1]
        li=psd.LoopIntegralFromPropagators([sp.expand(sp.sympify(p)) for p in props],ks,external_momenta=['q'],replacement_rules=[('q*q',2)],powerlist=powers,dimensionality='4-2*eps')
        sign=(-1)**sum(powers)
    else:
        li,sign=make_integral({'loops':L,'indices':exact['NativeIndices']},sp.Rational(x),sp.Rational(y))
    variables=list(map(sp.sympify,li.Feynman_parameters))
    def poly(e):
        return {tuple(m):Q(int(c.p),int(c.q)) for m,c in sp.Poly(sp.sympify(str(e)),*variables).terms()}
    pu,pf=poly(li.U),poly(li.F)
    assert U==pu,(name,'U mismatch')
    assert F==pf,(name,'F mismatch')
    assert all(c>0 for c in F.values()),(name,'F not coefficientwise positive')
    gamma=sp.simplify(sign*li.Gamma_factor.subs({'eps':0}))
    assert gamma==exact['Prefactor'],(name,gamma,exact['Prefactor'])
    (out/f'{name}-input.json').write_text(json.dumps(inp,indent=2)+'\n')
    (out/f'{name}-exact-definition.json').write_text(json.dumps(exact,indent=2)+'\n')
    reports.append({'Name':name,'Point':[x,y],'Loops':L,'Edges':len(inp['graph']),
        'Vertices':len(inp['scalarproducts']),'UTerms':len(U),'FTerms':len(F),
        'ExactUPolynomialMatchesOriginal':True,'ExactFPolynomialMatchesOriginal':True,
        'AllFCoefficientsPositive':True,'NormalizationMatchesOriginal':True,'Prefactor':int(gamma),
        'NativeBasisIndex':native_match,'NativeIndicesExactlyMatch':True if native_match else None,
        'AnalyticReferenceRead':False,'InputSHA256':hashlib.sha256((out/f'{name}-input.json').read_bytes()).hexdigest()})
report={'AllPassed':True,'Method':'Exact spanning-tree/two-forest polynomial comparison with independent LoopIntegralFromPropagators','Rows':reports,'NativeDefinitionsSHA256':hashlib.sha256(native_file.read_bytes()).hexdigest()}
(out/'InputAudit.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
