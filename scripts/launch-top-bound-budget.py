"""Bounded 24-worker experiment, with a frozen package and owned-process cleanup."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import json
import os
import shutil
import signal
import subprocess
import time

root = Path(__file__).resolve().parents[1]
run = root / "runs" / "top-bound-budget-20260923"
source = run / "source"
source.mkdir(parents=True, exist_ok=True)
for part in ("Kernel", "scripts"):
    shutil.copytree(root / part, source / part, dirs_exist_ok=True)
bundle = root.parent / "three-loop-DE-results-20260923"
jobs = [("ladder", 2, 6, 180), ("ladder", 3, 8, 300), ("tennis", 3, 10, 300)]

def execute(job):
    name, loops, workers, budget = job
    output = run / f"{name}-{loops}"
    output.mkdir(exist_ok=True)
    old_log = output / "run.log"
    if old_log.exists():
        old_log.rename(output / f"previous-{time.time_ns()}.log")
    command = ["/usr/local/bin/WolframKernel", "-script",
               str(source / "scripts" / "probe-top-bound-cost.wls"),
               str(bundle), name, str(loops), str(workers), str(output)]
    start = time.monotonic()
    with (output / "run.log").open("w") as log:
        child = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        timed_out = False
        try:
            code = child.wait(timeout=budget)
        except subprocess.TimeoutExpired:
            timed_out = True
            # Kill only this explicitly owned process group, including its IBP workers.
            os.killpg(child.pid, signal.SIGKILL)
            code = child.wait()
    result = {"family": name, "loops": loops, "workers": workers,
              "budget_seconds": budget, "seconds": round(time.monotonic()-start, 3),
              "exit_code": code, "timed_out": timed_out, "log": str(output / "run.log")}
    (output / "process-result.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result), flush=True)
    return result

with ThreadPoolExecutor(max_workers=3) as executor:
    results = list(executor.map(execute, jobs))
(run / "process-results.json").write_text(json.dumps(results, indent=2) + "\n")
