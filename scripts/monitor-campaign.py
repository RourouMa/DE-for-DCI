"""Read progress and preserve completed worker files; never start/stop kernels."""
import datetime as dt
import hashlib
import json
from pathlib import Path
import re
import shutil
import sys
import time

campaign = Path(sys.argv[1]).resolve()
state_path = campaign / "MonitorState.json"
state = json.loads(state_path.read_text()) if state_path.exists() else {}
log = campaign / "run-001.log"
offset = state.get("log_offset", 0)
with log.open("rb") as stream:
    if log.stat().st_size < offset:
        offset = 0
    stream.seek(offset)
    fresh = stream.read()
    state["log_offset"] = stream.tell()
lines = fresh.decode("utf-8", errors="replace").splitlines()
for line in lines:
    if "StartedAt ->" not in line and line.strip():
        print(line)

cutoff = (campaign / "RunManifest.wl").stat().st_mtime
manifest = re.sub(rb"\\\r?\n\s*", b"", (campaign / "RunManifest.wl").read_bytes())
implementation_hash = re.search(rb'"ImplementationHash"\s*->\s*(\d+)', manifest).group(1)
family_hash = re.search(rb'"FamilyHash"\s*->\s*(\d+)', manifest).group(1)
jobs = state.setdefault("jobs", {})
for job in sorted(Path("/tmp").glob("conformal-ibp-*")):
    first = job / "input1.wl"
    if not first.exists() or first.stat().st_mtime < cutoff:
        continue
    with first.open("rb") as stream:
        input_header = re.sub(rb"\\\r?\n\s*", b"", stream.read(20000))
        if family_hash not in input_header:
            continue
    # New workers carry a fingerprinted shared cache. Reject diagnostic jobs
    # from other source versions even when their family is identical.
    shared_cache = job / "SymmetryCache.wl"
    if shared_cache.exists():
        with shared_cache.open("rb") as stream:
            cache_header = re.sub(rb"\\\r?\n\s*", b"", stream.read(4096))
        cache_impl = re.search(rb'"ImplementationHash"\s*->\s*(\d+)', cache_header)
        if cache_impl is None or cache_impl.group(1) != implementation_hash:
            continue
    archive = campaign / "worker-archives" / job.name
    archive.mkdir(parents=True, exist_ok=True)
    info = jobs.setdefault(job.name, {"source": str(job), "files": {}})
    new_files = []
    for prefix in ("input", "output"):
        for source in sorted(job.glob(f"{prefix}[0-9]*.wl")):
            if not source.exists():
                continue
            stat = source.stat()
            # Put writes directly: leave very recent outputs until a later poll.
            if time.time() - stat.st_mtime < 10:
                continue
            signature = [stat.st_size, stat.st_mtime_ns]
            prior = info["files"].get(source.name)
            if prior and prior["signature"] == signature:
                continue
            target = archive / source.name
            shutil.copy2(source, target)
            info["files"][source.name] = {
                "signature": signature,
                "sha256": hashlib.sha256(target.read_bytes()).hexdigest(),
            }
            new_files.append(source.name)
    if new_files:
        (archive / "Manifest.json").write_text(json.dumps(info, indent=2))
        print(json.dumps({"job": job.name, "archived": new_files}))
state["checked_utc"] = dt.datetime.now(dt.timezone.utc).isoformat()
state_path.write_text(json.dumps(state, indent=2))
if not lines:
    print(json.dumps({"status": "no_new_log_event", "checked_utc": state["checked_utc"]}))
