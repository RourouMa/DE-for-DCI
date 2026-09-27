"""Postprocess fixed-budget pilot outputs. References are never passed to the sampler."""
import hashlib
import json
from pathlib import Path
import re
import mpmath as mp

ROOT = Path(__file__).resolve().parent
mp.mp.dps = 65
top = mp.mpf("1.2949774454346312026756864422914142929288329003803")
one = mp.mpf("1.9446834460534868153790886845374274591091007862172296255308")
log2 = mp.log(2)
boundary = (mp.polylog(4, mp.mpf(1)/2) + log2**4/24 - mp.pi**4/720
            + mp.pi**2*(3-6*log2+2*log2**2)/24 + 7*mp.zeta(3)/8 - mp.mpf(5)/4)
references = {"top": top, "oneloop": one, "boundary": boundary, "boundary_merged": boundary}
rows = []
for path in sorted(ROOT.glob("*-N*-seed*.json")):
    if path.name.endswith((".input.json", ".stdout.json")):
        continue
    result = json.loads(path.read_text())
    assert result["Status"] == "Computed" and not result["DroppedSampleWarning"]
    prefix = path.with_suffix("")
    payload = prefix.with_suffix(".input.json").read_bytes()
    assert hashlib.sha256(payload).hexdigest() == result["InputSHA256"]
    raw = json.loads(prefix.with_suffix(".stdout.json").read_text())
    assert raw == result["RawResult"]
    text = prefix.with_suffix(".stderr.txt").read_text()
    actual_threads = re.search(r"Started integrating using (\d+) threads", text)
    reference = references[result["Name"]]
    value, error = mp.mpf(result["Value"]), mp.mpf(result["ReportedError"])
    rows.append({"File": path.name, "Name": result["Name"], "Samples": result["Samples"],
                 "Seed": result["Seed"], "RequestedThreads": result["Threads"],
                 "ActualThreads": int(actual_threads[1]) if actual_threads else None,
                 "Value": float(value), "ReportedError": float(error),
                 "Reference": str(reference), "AbsoluteDifference": float(abs(value-reference)),
                 "Pull": float(abs(value-reference)/error),
                 "RelativeReportedError": float(error/abs(value)),
                 "Meets0p1PercentPrecision": bool(error/abs(value) <= mp.mpf("0.001")),
                 "SecondsWall": result["SecondsWall"], "RawHashesVerified": True})
raw = json.loads((ROOT / "upstream-smoke.stdout.json").read_text())
wheel_value, wheel_error = raw["integral"][0][0]
report = {"Purpose": "Backend and input-mapping pilot; not a replacement for accepted complete-sum Vegas validation",
          "PrecisionComparisonThreshold": 0.001, "AnalyticReferenceReadOnlyAfterSampling": True,
          "Rows": rows, "AllPilotsWithinThreeReportedErrors": all(r["Pull"] < 3 for r in rows),
          "TopTropicalReached0p1Percent": all(r["Meets0p1PercentPrecision"] for r in rows if r["Name"] == "top"),
          "UpstreamWheelSmoke": {"Reference": str(6*mp.zeta(3)), "Value": wheel_value,
                                 "ReportedError": wheel_error, "Pull": float(abs(wheel_value-6*mp.zeta(3))/wheel_error)},
          "Warning": "Feyntrop logs exceptional Minkowski kinematics; exact fixture F has positive coefficients. No sample-dropping warning occurred.",
          "ThreadNote": "Historical Threads means requested maximum. ActualThreads is parsed from raw stderr; the new adapter sets OMP_DYNAMIC=FALSE."}
(ROOT / "PilotComparison.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps({"PilotCount": len(rows), "AllWithinThreeErrors": report["AllPilotsWithinThreeReportedErrors"],
                  "TopReached0p1Percent": report["TopTropicalReached0p1Percent"]}, indent=2))
