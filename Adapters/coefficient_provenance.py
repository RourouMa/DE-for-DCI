"""Select original rows with coefficient-aware modular target provenance.

This implements the target-provenance idea used by NeatIBP's Oerlikon method
without materializing an augmented identity matrix. It is a numerical row
selector, not a symbolic reduction or closure certificate. Column order and
source columns must be preserved by the caller.
"""

import argparse
import heapq
import json
from math import isqrt
from pathlib import Path
import random
import time


def select_rows(data, *, keep_certificates=True, progress=None):
    """Return one-based ORIGINAL row IDs; verify every target certificate."""
    nr, nc = data["Rows"], data["Columns"]
    if any(type(n) is not int or n < 0 for n in (nr, nc)):
        raise ValueError("Rows and Columns must be nonnegative integers")
    if len(data["Samples"]) != 1:
        raise ValueError("Select one finite-field sample at a time")
    sample = data["Samples"][0]
    prime = sample["Prime"]
    if (type(prime) is not int or not 2 <= prime <= 2147483647
            or any(prime % d == 0 for d in range(2, isqrt(prime) + 1))):
        raise ValueError("Prime must be a prime integer at most 2147483647")
    targets = data["Targets"]
    if any(type(q) is not int or not 1 <= q <= nc for q in targets):
        raise ValueError("Target column out of range")
    original = [{} for _ in range(nr)]
    for r, c, value in sample["Entries"]:
        if (any(type(v) is not int for v in (r, c, value))
                or not 1 <= r <= nr or not 1 <= c <= nc):
            raise ValueError("Invalid integer matrix entry")
        value = (original[r-1].get(c-1, 0) + value) % prime
        if value:
            original[r-1][c-1] = value
        else:
            original[r-1].pop(c-1, None)

    started = time.monotonic()
    pivots = {}
    origins, scales, dependencies = [], [], []
    order = (sorted(range(nr), key=lambda i: (len(original[i]), i))
             if data.get("ShortRowsFirst", True) else range(nr))
    for counter, index in enumerate(order, 1):
        row = original[index].copy()
        edges = []
        while row:
            column = min(row)
            factor = row[column]
            if column not in pivots:
                inverse = pow(factor, -1, prime)
                pivot_id = len(origins)
                origins.append(index)
                scales.append(inverse)
                dependencies.append(edges)
                pivots[column] = (
                    {c: v*inverse % prime for c, v in row.items()}, pivot_id)
                break
            other, parent = pivots[column]
            edges.append((parent, factor))
            for c, value in other.items():
                updated = (row.get(c, 0)-factor*value) % prime
                if updated:
                    row[c] = updated
                else:
                    row.pop(c, None)
        if progress and counter % 20000 == 0:
            progress(dict(stage="forward", processed=counter, rank=len(origins),
                          seconds=time.monotonic()-started))
    forward_seconds = time.monotonic()-started

    needed, certificates, normal_forms = set(), [], []
    for ordinal, query in enumerate(targets, 1):
        target = query-1
        row, mass = {target: 1}, {}
        queue = [target] if target in pivots else []
        queued = set(queue)
        while queue:
            column = heapq.heappop(queue)
            queued.remove(column)
            factor = row.pop(column, 0)
            if not factor:
                continue
            other, pivot_id = pivots[column]
            mass[pivot_id] = (mass.get(pivot_id, 0)+factor) % prime
            for c, value in other.items():
                if c == column:
                    continue
                updated = (row.get(c, 0)-factor*value) % prime
                if updated:
                    row[c] = updated
                    if c in pivots and c not in queued:
                        heapq.heappush(queue, c)
                        queued.add(c)
                else:
                    row.pop(c, None)
        # Echelon rows form a DAG in creation order, even when their pivot
        # columns are out of order. Back-propagate coefficients, not row sets.
        queue = [-i for i, v in mass.items() if v]
        heapq.heapify(queue)
        queued = set(queue)
        coefficient = {}
        while queue:
            negative = heapq.heappop(queue)
            queued.remove(negative)
            pivot_id = -negative
            value = mass.pop(pivot_id, 0)
            if not value:
                continue
            scaled = value*scales[pivot_id] % prime
            origin = origins[pivot_id]
            coefficient[origin] = (coefficient.get(origin, 0)+scaled) % prime
            for parent, factor in dependencies[pivot_id]:
                updated = (mass.get(parent, 0)-scaled*factor) % prime
                mass[parent] = updated
                if updated and -parent not in queued:
                    heapq.heappush(queue, -parent)
                    queued.add(-parent)
        coefficient = {r: v for r, v in coefficient.items() if v}
        # Independent identity check against ORIGINAL input rows:
        # target - free normal form = sum_i coefficient_i * original_row_i.
        residual = {target: 1}
        for c, value in row.items():
            residual[c] = (residual.get(c, 0)-value) % prime
        for r, factor in coefficient.items():
            for c, value in original[r].items():
                residual[c] = (residual.get(c, 0)-factor*value) % prime
        if any(residual.values()):
            raise RuntimeError(f"Invalid original-row certificate for target {query}")
        needed.update(coefficient)
        if keep_certificates:
            certificates.append([[r+1, v] for r, v in sorted(coefficient.items())])
        normal_forms.append([[c+1, v] for c, v in sorted(row.items()) if v])
        if progress and ordinal % 100 == 0:
            progress(dict(stage="target_certificates", targets=ordinal,
                          selected_rows=len(needed), seconds=time.monotonic()-started))

    result = dict(Rows=[r+1 for r in sorted(needed)], Prime=prime, Rank=len(origins),
                  Targets=targets, TargetNormalForms=normal_forms,
                  PivotColumns=sorted(c+1 for c in pivots),
                  FreeColumns=[c+1 for c in range(nc) if c not in pivots],
                  AllOriginalRowCertificatesChecked=True,
                  ForwardSeconds=forward_seconds, Seconds=time.monotonic()-started,
                  SymbolicallyCertified=False, InputColumnsPreserved=True,
                  Method="CoefficientDAG")
    if keep_certificates:
        result["TargetCertificates"] = certificates
    return result


def select_aggregate_rows(data, *, trials=2, seed=260926,
                          keep_certificates=False, progress=None):
    """Screen with auxiliary random target combinations; check ALL targets later.

    Aggregate cancellation can miss required rows. A successful aggregate
    certificate alone is never sufficient to accept a physical reduction.
    """
    started = time.monotonic()
    nr, nc = data["Rows"], data["Columns"]
    if (any(type(n) is not int or n < 0 for n in (nr, nc))
            or type(trials) is not int or not 1 <= trials <= 32
            or type(seed) is not int or len(data["Samples"]) != 1):
        raise ValueError("Invalid aggregate selection shape or options")
    targets = data["Targets"]
    if any(type(q) is not int or not 1 <= q <= nc for q in targets):
        raise ValueError("Target column out of range")
    sample = data["Samples"][0]
    prime = sample["Prime"]
    if type(prime) is not int or prime < 2:
        raise ValueError("Invalid selection prime")
    entries = []
    for r, c, value in sample["Entries"]:
        if (any(type(v) is not int for v in (r, c, value))
                or not 1 <= r <= nr or not 1 <= c <= nc):
            raise ValueError("Invalid original matrix entry")
        entries.append([r, c+trials, value])
    rng = random.Random(seed)
    for trial in range(trials):
        entries.append([nr+trial+1, trial+1, 1])
        entries.extend([nr+trial+1, q+trials, -rng.randrange(1, prime)] for q in targets)
    augmented = dict(Rows=nr+trials, Columns=nc+trials,
                     Targets=list(range(1, trials+1)),
                     ShortRowsFirst=data.get("ShortRowsFirst", True),
                     Samples=[dict(Prime=prime, Entries=entries)])
    selected = select_rows(augmented, keep_certificates=keep_certificates, progress=progress)
    result = dict(Rows=[r for r in selected["Rows"] if r <= nr],
                  Rank=selected["Rank"]-trials, Prime=prime,
                  Targets=targets, Method="AggregateCoefficientDAG",
                  AggregateCount=trials, AggregateSeed=seed,
                  AggregateIdentitiesChecked=selected["AllOriginalRowCertificatesChecked"],
                  AllOriginalRowCertificatesChecked=False,
                  FullPhysicalTargetVerificationRequired=True,
                  AuxiliaryDefinitionsDoNotConstrainOriginalColumns=True,
                  InputColumnsPreserved=True, SymbolicallyCertified=False,
                  ForwardSeconds=selected["ForwardSeconds"], Seconds=time.monotonic()-started)
    if keep_certificates:
        result["AggregateCertificates"] = selected["TargetCertificates"]
        result["AggregateNormalFormsInAugmentedColumns"] = selected["TargetNormalForms"]
        result["AugmentedColumnShift"] = trials
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--omit-certificates", action="store_true",
                        help="Still check every identity, but omit its coefficients from JSON")
    parser.add_argument("--aggregates", type=int, default=0,
                        help="Experimental screening with this many target combinations; 0 checks individual targets")
    parser.add_argument("--seed", type=int, default=260926)
    args = parser.parse_args()
    options = dict(keep_certificates=not args.omit_certificates,
                   progress=lambda event: print(json.dumps(event), flush=True))
    data = json.loads(args.input.read_text())
    result = (select_aggregate_rows(data, trials=args.aggregates, seed=args.seed, **options)
              if args.aggregates else select_rows(data, **options))
    temporary = args.output.with_name(args.output.name + ".tmp")
    temporary.write_text(json.dumps(result) + "\n")
    temporary.replace(args.output)
    print(json.dumps({k: result[k] for k in
                      ("Rank", "Prime", "ForwardSeconds", "Seconds",
                       "AllOriginalRowCertificatesChecked", "SymbolicallyCertified")}
                     | dict(SelectedRows=len(result["Rows"]),
                            TargetCount=len(result["Targets"]))), flush=True)


if __name__ == "__main__":
    main()
