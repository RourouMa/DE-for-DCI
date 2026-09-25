"""Start a fresh, source-frozen highest-loop ladder campaign (no lower-loop DE)."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys


def positive(value):
    value = int(value)
    if value < 1:
        raise argparse.ArgumentTypeError('must be positive')
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--kernel', default='WolframKernel')
    parser.add_argument('--finiteflow', type=Path, required=True)
    parser.add_argument('--mathlink', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--pool', type=Path, help='optional verified PortablePool.wl from the current release snapshot')
    parser.add_argument('--workers', type=positive, default=8)
    parser.add_argument('--ff-threads', type=positive, default=8)
    parser.add_argument('--max-rounds', type=positive, default=101)
    parser.add_argument('--max-expansions', type=positive, default=32)
    parser.add_argument('--max-complexity-repairs', type=positive, default=8)
    parser.add_argument('--configure-only', action='store_true', help='check dependencies and write configuration; do not generate relations')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    kernel = shutil.which(args.kernel)
    if kernel is None:
        parser.error('WolframKernel executable not found')
    ff = args.finiteflow.expanduser().resolve()
    mathlink = (args.mathlink or ff / 'mathlink').expanduser().resolve()
    if not ff.is_dir() or not mathlink.is_dir():
        parser.error('FiniteFlow and MathLink directories must exist')
    pool = args.pool.expanduser().resolve() if args.pool else None
    if pool is not None and not pool.is_file():
        parser.error('pool file does not exist')
    output = args.output.expanduser().resolve()
    if output.exists() and any(output.iterdir()):
        parser.error('output must be new or empty; existing campaigns are never overwritten')
    output.mkdir(parents=True, exist_ok=True)
    source = output / 'source'
    for directory in ('Kernel', 'Extensions', 'Examples', 'scripts'):
        shutil.copytree(root / directory, source / directory,
                        ignore=shutil.ignore_patterns('__pycache__', '*.pyc', '*.log'))
    shutil.copy2(root / 'PacletInfo.wl', source / 'PacletInfo.wl')
    manifest = {str(p.relative_to(source)): hashlib.sha256(p.read_bytes()).hexdigest()
                for p in sorted(source.rglob('*')) if p.is_file()}
    (output / 'SourceManifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    config = dict(kernel=kernel, finiteflow=str(ff), mathlink=str(mathlink),
                  output=str(output), workers=args.workers, ff_threads=args.ff_threads,
                  max_rounds=args.max_rounds, max_expansions=args.max_expansions,
                  max_complexity_repairs=args.max_complexity_repairs,
                  configure_only=args.configure_only, estimated_master_threshold=100)
    if pool is not None:
        config['pool'] = str(pool)
    (output / 'LaunchConfiguration.json').write_text(json.dumps(config, indent=2) + '\n')
    env = os.environ.copy()
    env['DCI_LAUNCH_CONFIGURATION'] = str(output / 'LaunchConfiguration.json')
    command = [kernel, '-script', str(source / 'scripts' / 'four-loop-campaign.wls')]
    print('Frozen source and configuration:', output, flush=True)
    print('Running; progress is in', output / 'run.log', flush=True)
    with (output / 'run.log').open('w') as stream:
        result = subprocess.run(command, cwd=source, env=env, stdout=stream, stderr=subprocess.STDOUT)
    print('Kernel exit code:', result.returncode, flush=True)
    return result.returncode


if __name__ == '__main__':
    sys.exit(main())
