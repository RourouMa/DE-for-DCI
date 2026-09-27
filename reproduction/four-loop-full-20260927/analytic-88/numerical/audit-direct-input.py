import sys,json,hashlib,re
from pathlib import Path
import sympy as s
p=Path(__file__).resolve().parent;root=p.parents[1];legacy=root/'four-loop-analytic-20260927';sys.path.insert(0,str(legacy));from feynman_four import make_integral
native=json.loads((root/'DE-for-DCI-publish/reproduction/four-loop-full-20260927/IntegralDefinitions88.json').read_text())[0]
old=json.loads((legacy/'IntegralDefinitions83.json').read_text())[0]
x,y=s.symbols('x y');m=[x,y,x,y];q3=-(1-x)**2
q=s.Matrix([[0,0,0,0],[0,x+y,q3/2,x+y+(1-y)**2/2],[0,q3/2,q3,q3/2],[0,x+y+(1-y)**2/2,q3/2,x+y]])
gram=s.Matrix(4,4,lambda i,j:s.expand(m[i]+m[j]-q[i,i]-q[j,j]+2*q[i,j]))
expected=s.Matrix([[2*x,0,1+x*x,0],[0,2*y,0,1+y*y],[1+x*x,0,2*x,0],[0,1+y*y,0,2*y]])
term={'loops':native['Loops'],'indices':native['Indices']};li,sgn=make_integral(term,s.Rational(1,4),s.Rational(3,4))
meta=json.loads((legacy/'TopParametricConstruction.json').read_text());nu=sum(native['Indices'][:-4]);libroot=legacy/'numerical-work/four_top_p1';pref=(libroot/'four_top_p1_integral/src/prefactor.cpp').read_text();header=(libroot/'four_top_p1_integral/four_top_p1_integral.hpp').read_text()
files=[legacy/'feynman_four.py',legacy/'generate-top-numerical.py',legacy/'TopParametricConstruction.json',libroot/'four_top_p1_pylink.so',libroot/'four_top_p1_integral/src/prefactor.cpp']
report={'CurrentFirstIntegralExactlyMatchesOriginalDirectInput':native==old,'IntegralIndex':1,'OrdinaryPropagatorCount':nu,'MeasureTail':native['Indices'][-4:],'ExternalMassSquared':['x','y','x','y'],'ExternalGramExactlyMatchesNativeKinematics':gram==expected,'ExternalGram':[[str(z) for z in row] for row in gram.tolist()],
'InternalPairOrder':[[1,2],[2,3],[3,4],[1,3],[1,4],[2,4]],'TopInternalPowers':native['Indices'][16:22],
'InputPoint':['1/4','3/4'],'FreshParameters':len(li.Feynman_parameters),'FreshUTerms':len(li.U.coeffs),'FreshFTerms':len(li.F.coeffs),'FreshGammaFactor':str(li.Gamma_factor),'SignPrefactor':sgn,'CombinedGammaAtEpsilonZero':str((sgn*li.Gamma_factor).subs(s.Symbol('eps'),0)),
'CompiledLeadingPrefactorIs24':'{{24.0}}' in pref,'CompiledSectors':int(re.search(r'number_of_sectors = (\d+)',header)[1]),'CompiledRuntimeRealParameters':int(re.search(r'number_of_real_parameters = (\d+)',header)[1]),'AllUCoefficientsNonnegative':all(z>=0 for z in li.U.coeffs),'AllFCoefficientsNonnegative':all(z>=0 for z in li.F.coeffs),'RegeneratedMetadataAgrees':len(li.U.coeffs)==meta['UTerms'] and len(li.F.coeffs)==meta['FTerms'] and str(li.Gamma_factor)==meta['GammaFactor'],
'NormalizationNote':'At eps=0, nu=13,L=4,D=4 gives Gamma(5)=24,U^3/F^5; projective measure indices are not propagators. Legacy concurrent-sector boundary QMC is excluded as evidence; B4 relies on independent radial and spectral derivations.','LegacyBoundaryQMCEligibleForValidation':False,
'FilesSHA256':{str(f):hashlib.sha256(f.read_bytes()).hexdigest() for f in files}}
(p/'DirectInputAudit.json').write_text(json.dumps(report,indent=2));print(json.dumps({k:v for k,v in report.items() if k!='FilesSHA256'},indent=2))
