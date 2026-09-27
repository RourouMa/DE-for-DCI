from pathlib import Path
import json
import os
import signal
import subprocess
import time
root = Path(__file__).resolve().parents[1]
run = root / "runs" / "top-bound-budget-20260923"
out = run / "ladder-2"
start = time.monotonic()
with (out / "targeted-extension.log").open("w") as log:
    child = subprocess.Popen(["/usr/local/bin/WolframKernel", "-script",
        str(root / "scripts" / "extend-top-bound-probe.wls"), str(run / "source"), str(out)],
        stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    timed_out = False
    try:
        code = child.wait(timeout=70)
    except subprocess.TimeoutExpired:
        timed_out = True
        os.killpg(child.pid, signal.SIGKILL)
        code = child.wait()
result = {"exit_code": code, "timed_out": timed_out, "seconds": time.monotonic()-start, "budget_seconds": 70}
(out / "extension-process-result.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps(result), flush=True)
