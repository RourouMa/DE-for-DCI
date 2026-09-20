"""Run portable regressions; optionally include FiniteFlow via FINITEFLOW_ROOT."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--kernel', default='WolframKernel')
parser.add_argument('--output', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
output = args.output or Path(tempfile.mkdtemp(prefix='conformal-ibp-tests-'))
output.mkdir(parents=True, exist_ok=True)
tests = ['RunTests', 'SeedPolicies', 'GapCampaign', 'RelationFrontier', 'ParallelResiduals', 'CoefficientParameters', 'SelfReducedTargets', 'LinearNormalization', 'BoundaryReduction',
         'ReductionReuse', 'TargetReduction', 'SymmetryReuse', 'RelabelCache',
         'OnDemandDE', 'Workers']
if os.environ.get('FINITEFLOW_ROOT'):
    tests.append('FiniteFlowTargetSelection')
results = []
for name in tests:
    started = time.monotonic()
    with (output / (name + '.log')).open('w') as stream:
        result = subprocess.run([args.kernel, '-script', str(root / 'Tests' / (name + '.wls'))],
                                cwd=root, stdout=stream, stderr=subprocess.STDOUT)
    record = dict(test=name, exit_code=result.returncode, seconds=round(time.monotonic()-started, 3))
    results.append(record)
    (output / 'results.json').write_text(json.dumps(results, indent=2) + '\n')
    print(json.dumps(record), flush=True)
    if result.returncode:
        print('See logs in', output)
        raise SystemExit(result.returncode)
print('All tests passed. Logs:', output)
