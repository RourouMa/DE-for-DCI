"""Validate graph normalization and optionally run the independently known one-loop integral."""
import argparse
import copy
import json
from pathlib import Path
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "Adapters"))
from TropicalMonteCarlo import validate_input, run


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--executable", type=Path)
    args = parser.parse_args()
    fixtures = ROOT / "reproduction/four-loop-tropical-20260927"
    checks = {}
    for name, loops, pref in [("oneloop", 1, 1), ("top", 4, 24), ("boundary_merged", 4, 24)]:
        data = json.loads((fixtures / f"{name}-input.json").read_text())
        norm = validate_input(data)
        assert norm["Loops"] == loops and norm["Prefactor"] == pref
        checks[name + "Normalization"] = True
    data = json.loads((fixtures / "oneloop-input.json").read_text())
    for label, change in [("Numerator", lambda d: d["graph"][0].__setitem__(1, -1)),
                          ("MomentumViolation", lambda d: d["scalarproducts"][0].__setitem__(0, 100)),
                          ("EpsilonNormalization", lambda d: d.__setitem__("num_eps_terms", 2))]:
        invalid = copy.deepcopy(data)
        change(invalid)
        try:
            validate_input(invalid)
        except ValueError:
            checks["Reject" + label] = True
        else:
            raise AssertionError(label)
    if args.executable:
        with tempfile.TemporaryDirectory() as tmp:
            result = run(data, args.executable, Path(tmp) / "run", 1000000, 264575, threads=2)
            # Read the fixed independent analytic value only AFTER the sampling.
            reference = 1.9446834460534868153790886845374274591
            assert result["UsableSampleRun"]
            pull = abs(result["Value"] - reference) / result["ReportedError"]
            assert pull < 5 and result["ImaginaryValue"] == 0
            checks["KnownOneLoopWithinFiveReportedErrors"] = True
            checks["PrecisionFlagMatchesActualError"] = (result["PrecisionTargetReached"] ==
                (result["ReportedError"] / abs(result["Value"]) <= 0.001))
            assert checks["PrecisionFlagMatchesActualError"]
            result["PostRunReference"] = reference
            result["PostRunPull"] = pull
    else:
        result = {"ExecutableSmokeTest": "NotRequested"}
    print(json.dumps({"Passed": True, "Checks": checks, "SmokeRun": result}, indent=2))


if __name__ == "__main__":
    main()
