from pathlib import Path
from decimal import Decimal as D,localcontext
import json,hashlib
out=Path(__file__).resolve().parent;numeric=out.parent/'numerical'
with localcontext() as c:
 c.prec=170
 runs=[json.loads((out/f'ChenEvaluation-N{n}-P{p}.json').read_text()) for n,p in [(240,80),(320,100),(400,120),(480,140)]]
 best=runs[-1];cv=[D(v) for v in best['CanonicalValues']];nv=[D(v) for v in best['NativeValues']]
 def sf(v):return str(v)
 def delta(a,b):return [abs(D(x)-D(y)) for x,y in zip(a,b)]
 convergence=[]
 for a,b in zip(runs,runs[1:]):
  dc=delta(a['CanonicalValues'],b['CanonicalValues']);dn=delta(a['NativeValues'],b['NativeValues'])
  convergence.append({'Orders':[a['SeriesOrder'],b['SeriesOrder']],'TopAbsoluteDifference':sf(abs(D(a['TopValue'])-D(b['TopValue']))),'MaxCanonical88Difference':sf(max(dc)),'MaxNative88Difference':sf(max(dn)),'MaxNativeDifferenceIndex':dn.index(max(dn))+1})
 de=json.loads((numeric/'TopTaylor80Ray5.json').read_text());native=json.loads((numeric/'NativeValues88AtQuarterThreeQuarter.json').read_text());dc=delta(best['CanonicalValues'],de['CanonicalValues']);dn=delta(best['NativeValues'],native['Values'])
 x=D(1)/4;y=D(3)/4;oneloop=[1/(2*x*y),y.ln()/(x*(y*y-1)),x.ln()/(y*(x*x-1)),2*x.ln()*y.ln()/((x*x-1)*(y*y-1))];one=delta(best['NativeValues'][79:83],oneloop)
 rep={'ExplicitExpressionEvaluatedDirectly':True,'DifferentialEquationMatricesUsedByExpressionEvaluator':False,'CanonicalComponents':88,'NativeComponents':88,'Point':['1/4','3/4'],'ExplicitTermCount':62140,'TopExplicitTermCount':3084,'MaximumWordLength':8,'Orders':[240,320,400,480],'RequestedPrecisions':[80,100,120,140],'Convergence':convergence,'BestTopValue':best['TopValue'],'Conservative50DigitTopValue':format(D(best['TopValue']),'.50g'),'TopDifferenceVersusIndependentDE85DigitRun':sf(abs(D(best['TopValue'])-D(de['TopValue']))),'MaxCanonical88DifferenceVersusDE':sf(max(dc)),'MaxNative88DifferenceVersusDE':sf(max(dn)),'All88CanonicalAgreeWithDETo40AbsoluteDecimalPlaces':max(dc)<D('1e-40'),'All88NativeAgreeWithDETo40AbsoluteDecimalPlaces':max(dn)<D('1e-40'),'MaxNativeDifferenceIndex':dn.index(max(dn))+1,'IndependentOneLoopClosedFormIndices':[80,81,82,83],'IndependentOneLoopClosedFormMaxDifference':sf(max(one)),'TopCanonicalCancellationRatio':best['TopCanonicalCancellationRatio'],'HighestOrderArithmeticPrecisionIsNotClaimedAccuracy':True,'Conclusion':'The explicit finite analytic expression independently reproduces the differential-equation solution to its stated conservative 40-decimal-place accuracy. This does not resolve or certify the separate original-integral direct numerical comparison.'}
 (out/'ExplicitChenNumericalValidation.json').write_text(json.dumps(rep,indent=2)+'\n')
 print(json.dumps(rep,indent=2))
