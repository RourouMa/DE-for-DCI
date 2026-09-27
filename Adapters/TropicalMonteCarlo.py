"""Fixed-budget feyntrop adapter for a finite, positive-power scalar graph.

The input is feyntrop's graph JSON, independently checked against the original
integral. This runner does not construct that map or certify subgraph finiteness.
Only the leading epsilon coefficient is normalized. No reference value is read.
"""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import re
import subprocess
import time


def finite_number(value):
    return (not isinstance(value, bool) and isinstance(value, (int, float))
            and math.isfinite(value))


def validate_input(data):
    graph = data.get("graph", [])
    if not isinstance(graph, list) or not graph:
        raise ValueError("graph must contain edges [[u,v],positive_power]")
    vertices, adjacency, powers = set(), {}, []
    for edge in graph:
        if (not isinstance(edge, list) or len(edge) != 2
                or not isinstance(edge[0], list) or len(edge[0]) != 2):
            raise ValueError("invalid edge")
        (u, v), power = edge
        if any(type(i) is not int or i < 0 for i in (u, v)):
            raise ValueError("vertex labels must be nonnegative integers")
        if not finite_number(power) or power <= 0:
            raise ValueError("only positive powers are supported; map numerators separately")
        vertices.update((u, v))
        adjacency.setdefault(u, set()).add(v)
        adjacency.setdefault(v, set()).add(u)
        powers.append(power)
    size = len(vertices)
    if vertices != set(range(size)):
        raise ValueError("vertices must be numbered consecutively from zero")
    reached, pending = {0}, [0]
    while pending:
        for v in adjacency[pending.pop()] - reached:
            reached.add(v)
            pending.append(v)
    if reached != vertices:
        raise ValueError("disconnected graph: integrate connected factors separately")
    loops = len(graph) - size + 1
    dimension = data.get("dimension")
    if loops < 1 or not finite_number(dimension) or dimension <= 0:
        raise ValueError("positive dimension and at least one loop are required")
    masses, momenta = data.get("masses_sqr", []), data.get("scalarproducts", [])
    if len(masses) != len(graph) or not all(map(finite_number, masses)):
        raise ValueError("one finite real mass squared is required per edge")
    if (len(momenta) != size or any(not isinstance(row, list) or len(row) != size
                                  or not all(map(finite_number, row)) for row in momenta)):
        raise ValueError("scalarproducts must be a finite real vertex matrix")
    scale = max(1., max(abs(v) for row in momenta for v in row))
    if any(abs(sum(row)) > 1.e-10 * size * scale for row in momenta):
        raise ValueError("momentum conservation: scalarproduct rows must sum to zero")
    if any(abs(momenta[i][j] - momenta[j][i]) > 1.e-12 * scale
           for i in range(size) for j in range(i)):
        raise ValueError("scalarproducts must be symmetric")
    if data.get("num_eps_terms") != 1:
        raise ValueError("only the finite leading epsilon coefficient is supported")
    if not finite_number(data.get("lambda")) or data["lambda"] < 0:
        raise ValueError("lambda must be a finite nonnegative deformation parameter")
    omega = sum(powers) - loops * dimension / 2
    if omega <= 0:
        raise ValueError("Gamma prefactor is not finite positive; use a suitable finite representation")
    prefactor = math.gamma(omega) / math.prod(math.gamma(nu) for nu in powers)
    if not math.isfinite(prefactor) or prefactor <= 0:
        raise ValueError("Gamma prefactor is outside supported numeric range")
    return {"Loops": loops, "Edges": len(graph), "Vertices": size,
            "IntegrationDimension": len(graph) - 1, "Omega": omega,
            "Prefactor": prefactor,
            "Convention": "Gamma(sum(nu)-L*D/2)/product Gamma(nu); positive-propagator convention",
            "SubgraphFinitenessCertifiedByAdapter": False,
            "NativeIntegralGraphMappingCertifiedByAdapter": False}


def run(data, executable, output, samples, seed, threads=2, timeout=600,
        relative_error=0.001):
    if (type(samples) is not int or samples < 2 or type(seed) is not int
            or not 0 <= seed < 2**64 or type(threads) is not int or threads < 1
            or not finite_number(timeout) or timeout <= 0
            or not finite_number(relative_error) or relative_error <= 0):
        raise ValueError("invalid sample count, seed, thread count, timeout or precision target")
    normalization = validate_input(data)
    executable, output = Path(executable).resolve(), Path(output).resolve()
    executable_hash = hashlib.sha256(executable.read_bytes()).hexdigest()
    data = dict(data, N=samples, seed=seed)
    payload = (json.dumps(data, sort_keys=True, allow_nan=False) + "\n").encode()
    output.mkdir(parents=True, exist_ok=False)
    (output / "input.json").write_bytes(payload)
    report = {"Status": "Running", "Samples": samples, "Seed": seed,
              "Threads": threads, "Timeout": timeout, "RelativeErrorTarget": relative_error,
              "Executable": str(executable), "ExecutableSHA256": executable_hash,
              "InputSHA256": hashlib.sha256(payload).hexdigest(),
              "Normalization": normalization, "AnalyticReferenceRead": False,
              "StoppingRule": "Fixed sample count and timeout; no reference-dependent stopping",
              "StartedUnix": time.time()}
    def save():
        (output / "Report.json").write_text(json.dumps(report, indent=2, allow_nan=False) + "\n")
    save()
    env = dict(os.environ, OMP_NUM_THREADS=str(threads), OMP_DYNAMIC="FALSE")
    try:
        proc = subprocess.run([str(executable)], input=payload, capture_output=True,
                              env=env, timeout=timeout)
        stdout, stderr = proc.stdout, proc.stderr
        report.update(Status="Computed" if proc.returncode == 0 else "Failed",
                      ExitCode=proc.returncode)
    except subprocess.TimeoutExpired as error:
        stdout, stderr = error.stdout or b"", error.stderr or b""
        report["Status"] = "TimedOut"
    except OSError as error:
        stdout, stderr = b"", str(error).encode()
        report["Status"] = "LaunchFailed"
    (output / "stdout.json").write_bytes(stdout)
    (output / "stderr.txt").write_bytes(stderr)
    messages = stderr.decode(errors="replace")
    actual_threads = re.search(r"Started integrating using (\d+) threads", messages)
    report.update(SecondsWall=time.time() - report["StartedUnix"],
                  ActualThreads=int(actual_threads[1]) if actual_threads else None,
                  DroppedSampleWarning="dropping this point" in messages.lower(),
                  KinematicRegimeLog=[s for s in messages.splitlines()
                                     if "regime:" in s or "permutahedron" in s or "Warning:" in s])
    if report["Status"] == "Computed":
        try:
            raw = json.loads(stdout)
            z = raw["integral"][0]
            if (len(raw["integral"]) != 1 or len(z) != 2
                    or any(len(pair) != 2 or not all(map(finite_number, pair)) for pair in z)
                    or z[0][1] < 0 or z[1][1] < 0):
                raise ValueError("invalid leading coefficient or errors")
            pref = normalization["Prefactor"]
            value, error = z[0][0] * pref, z[0][1] * pref
            imag, imag_error = z[1][0] * pref, z[1][1] * pref
            if not all(map(finite_number, [value, error, imag, imag_error])):
                raise ValueError("nonfinite normalized value")
            magnitude, total_error = math.hypot(value, imag), math.hypot(error, imag_error)
            report.update(Value=value, ReportedError=error, ImaginaryValue=imag,
                          ImaginaryReportedError=imag_error, RawResult=raw,
                          RelativeReportedError=total_error / magnitude if magnitude else None,
                          PrecisionTargetReached=bool(magnitude and total_error / magnitude <= relative_error
                                                      and not report["DroppedSampleWarning"]))
        except (ValueError, KeyError, TypeError, IndexError, OverflowError) as error:
            report.update(Status="InvalidOutput", ParseError=str(error))
    report["UsableSampleRun"] = report["Status"] == "Computed" and not report["DroppedSampleWarning"]
    save()
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path, help="fresh output directory (never overwritten)")
    parser.add_argument("--executable", default=os.environ.get("FEYNTROP_EXECUTABLE"),
                        help="feyntrop binary; alternatively set FEYNTROP_EXECUTABLE")
    parser.add_argument("--samples", type=int, required=True)
    parser.add_argument("--seed", type=int, required=True)
    parser.add_argument("--threads", type=int, default=2)
    parser.add_argument("--timeout", type=float, default=600)
    parser.add_argument("--relative-error", type=float, default=0.001)
    args = parser.parse_args()
    if not args.executable:
        parser.error("--executable or FEYNTROP_EXECUTABLE is required")
    try:
        report = run(json.loads(args.input.read_text()), args.executable, args.output,
                     args.samples, args.seed, args.threads, args.timeout, args.relative_error)
    except (ValueError, OSError, OverflowError) as error:
        parser.error(str(error))
    print(json.dumps(report, indent=2))
    # Computation success is distinct from reaching the stated precision target.
    return 0 if report["UsableSampleRun"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
