"""Fresh single-process deterministic check, with no Monte Carlo input."""
import hashlib,importlib.util,json,time
from pathlib import Path
import mpmath as mp

out=Path(__file__).resolve().parent
legacy=out.parents[1]/'four-loop-analytic-20260927'
source=legacy/'special-point-spectral.py'
if not source.exists():
    source=out/'b4-spectral-series.py'
spec=importlib.util.spec_from_file_location('boundary_spectral',source)
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
start=time.monotonic();s=module.spectral_boundary(4,120,56,100)
mp.mp.dps=100
L=mp.log(2)
closed=mp.polylog(4,mp.mpf('.5'))+L**4/24-mp.pi**4/720+mp.pi**2*(3-6*L+2*L**2)/24+7*mp.zeta(3)/8-mp.mpf(5)/4
d=lambda t:mp.pi**2/8-1-mp.polylog(2,1-t*t)/4
radial=mp.pi**2*(1-L)**2/8-mp.quad(lambda t:d(t)**2,[0,mp.mpf('.25'),mp.mpf('.5'),mp.mpf('.75'),1])/4
report={'SingleProcess':True,'ParallelIntegratorUsed':False,'MonteCarloInputRead':False,
        'DEInputRead':False,'Precision':100,'B4Classical':str(closed),
        'B4Spectral':str(s),'B4Radial':str(radial),
        'ClassicalVsSpectral':str(abs(closed-s)),
        'ClassicalVsRadial':str(abs(closed-radial)),
        'AllAgreeTo80AbsoluteDecimalPlaces':max(abs(closed-s),abs(closed-radial))<mp.mpf('1e-80'),
        'Seconds':time.monotonic()-start,
        'SpectralScriptSHA256':hashlib.sha256(source.read_bytes()).hexdigest(),
        'Scope':'Checks independent derived representations; original boundary Feynman parameter integration is separately revalidated.'}
(out/'B4DeterministicSerialRecheck.json').write_text(json.dumps(report,indent=2)+'\n')
assert report['AllAgreeTo80AbsoluteDecimalPlaces']
print(json.dumps(report),flush=True)
