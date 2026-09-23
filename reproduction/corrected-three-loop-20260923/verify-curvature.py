"""Recheck the exported full rational connections, with 24 processes by default.

This checks exact curvature; it does not regenerate the large IBP pools.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--kernel", default="WolframKernel")
parser.add_argument("--workers", type=int, default=24)
parser.add_argument("--output", type=Path)
args = parser.parse_args()
if args.workers < 1:
    parser.error("--workers must be positive")
root = Path(__file__).resolve().parent
output = args.output or Path(tempfile.mkdtemp(prefix="dci-three-loop-curvature-"))
output.mkdir(parents=True, exist_ok=True)
shards = max(1, (args.workers + 1) // 2)
jobs = [(name, i) for name in ("ladder", "tennis") for i in range(1, shards + 1)]

def run(job):
    name, worker = job
    record = output / f"{name}-{worker}.json"
    with (output / f"{name}-{worker}.log").open("w") as stream:
        proc = subprocess.run([args.kernel, "-script", str(root / "verify-curvature.wls"),
                               name, str(worker), str(shards), str(record.resolve())],
                              stdout=stream, stderr=subprocess.STDOUT)
    if proc.returncode:
        raise RuntimeError(f"{name}, worker {worker} failed; see {output}")
    return json.loads(record.read_text())

with ThreadPoolExecutor(max_workers=args.workers) as executor:
    records = list(executor.map(run, jobs))
summary = {}
for name, dimension in (("ladder", 30), ("tennis", 46)):
    selected = [r for r in records if r["Name"] == name]
    rows = sorted(row for r in selected for row in r["Rows"])
    passed = (rows == list(range(1, dimension + 1))
              and all(r["Passed"] and r["SavedDimension"] == dimension for r in selected)
              and sum(r["Entries"] for r in selected) == dimension ** 2)
    summary[name] = {"dimension": dimension, "entries": dimension ** 2, "passed": passed}
(output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
print(json.dumps(summary, indent=2))
print("Logs:", output)
raise SystemExit(0 if all(r["passed"] for r in summary.values()) else 1)
