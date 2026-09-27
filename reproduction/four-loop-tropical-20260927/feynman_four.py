"""Independent momentum-space construction from the user's G indices.

Last L entries implement the embedding-space measure; they are not propagators.
The remaining propagators are k_a^2-m_i^2 (shifted by q_i), and
(k_a-k_b)^2. A factor (-1)^sum(nu) converts pySecDec's Minkowski
propagator convention to the positive-propagator convention in the paper.
"""
import json
from pathlib import Path
import sympy as sp
import pySecDec as psd

ROOT = Path(__file__).resolve().parent

def make_integral(term, x=sp.Rational(1,4), y=sp.Rational(3,4)):
    loops=term['loops']; indices=term['indices']; powers=indices[:-loops]
    assert indices[-loops:]==[1]*loops
    ks=[f'k{i+1}' for i in range(loops)]
    qs=['0','q2','q3','q4']; masses=[x,y,x,y]
    props=[f'({k}-({q}))**2-({mass})' for k in ks for q,mass in zip(qs,masses)]
    # Package order: adjacent chain edges, then remaining lexicographic pairs.
    chain=[(i,i+1) for i in range(1,loops)]
    pairs=chain+[(i,j) for i in range(1,loops+1) for j in range(i+1,loops+1) if (i,j) not in chain]
    props += [f'(k{i}-k{j})**2' for i,j in pairs]
    assert len(props)==len(powers)
    qsq=-(1-x)**2
    rules=[('q2*q2',x+y),('q3*q3',qsq),('q4*q4',x+y),
           ('q2*q3',qsq/2),('q3*q4',qsq/2),('q2*q4',x+y+(1-y)**2/2)]
    rules=[(a,sp.expand(b)) for a,b in rules]
    props=[sp.expand(sp.sympify(p)) for p in props]
    li=psd.LoopIntegralFromPropagators(props,ks,external_momenta=['q2','q3','q4'],
        replacement_rules=rules,powerlist=powers,dimensionality='4-2*eps')
    return li,(-1)**sum(powers)
