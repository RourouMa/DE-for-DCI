# Optional computation adapters

- [DLogTools.wl](DLogTools.wl): exact constant-residue decomposition, rational Hermite primitive extraction and full gauge verification. Usage and limitations: [four-loop transfer workflow](../docs/FOUR_LOOP_TENNIS_WORKFLOW_20260927.zh-CN.md). Run `WolframKernel -script Tests/DLogTools.wls` from the package root; this includes exact reconstruction of the frozen 88-dimensional connection.
- [TropicalMonteCarlo.py](TropicalMonteCarlo.py): fixed-budget feyntrop graph integration with explicit Gamma normalization and provenance. See [installation and usage](TropicalMonteCarlo.zh-CN.md).
- NeatIBP/SpaSM and Kira adapters below select or solve existing physical relations. They remain optional.

## NeatIBP linear-system experiments

The main use of NeatIBP here is **selection and sparse elimination of existing
conformalIBP equations**. The DCI generators already use syzygies. Replacing
them with ordinary Feynman-integral IBPs is not required for these experiments.

`NeatIBPRowSelection.wl` implements two ideas from NeatIBP's
[`IndepedentSet` and `UsedRelations`](https://github.com/yzhphy/NeatIBP/blob/ac1c6c74e64b2a104124d8c7d37f7a9afa388f63/SyzygyRed.wl):

1. Find pivot columns of the transposed sampled coefficient matrix to select
   independent **original** equations.
2. Reduce the independent matrix augmented with an identity matrix. The right
   block records the coefficients of the original equations. Its nonzero
   entries in the target rows select the required equations (Oerlikon method).

The second step can remove dependencies whose coefficients cancel. The
existing Python selector conservatively records sets of row numbers and does
not remove such cancellations. Trying shorter equations first can further
improve which original equations are retained.

`coefficient_provenance.py` implements the second idea using a weighted
elimination dependency graph instead of explicitly storing `[M | I]`. Target
coefficients are propagated backwards with modular cancellations. Every target
identity is checked against the original matrix before row IDs are returned.
This avoids the identity block and expanded provenance for unrequested rows;
it does not guarantee that elimination itself stays sparse.

## Usage

This is an explicit optional adapter, not a registered campaign
`TargetSelector` value. It does not modify the production solver or generate
any IBP equations.

```wl
SparseRREF`SpaSMLibrary = "/usr/local/lib/libspasm.so";
Get["/path/to/NeatIBP/SparseRREF/SparseRREF.m"];
Get["/path/to/DE-for-DCI/Adapters/NeatIBPRowSelection.wl"];

(* M contains integer coefficients at a nonsingular kinematic point modulo p.
   Keep the package's column order and ALL retained boundary/source columns. *)
selection = ConformalIBPNeatSelection`SelectSparseTargetRows[
  M, targetColumnNumbers, 42013];
selectedSymbolicEquations = originalSymbolicEquations[[selection["Rows"]]];
```

After loading ConformalIBP and initializing FiniteFlow, the optional end-to-end
entry point also performs reconstruction and the mandatory full-system check:

```wl
result = ConformalIBPNeatSelection`NeatTargetSolve[
  originalSymbolicEquations, orderedIntegralColumns, targetAtoms,
  "Parameters" -> {x,y}, "NumericalPoint" -> {11,17}];
If[!FailureQ[result], targetNormalForms = result["ReducedTargets"]];
```

To use the coefficient-aware Python selector, which requires Python 3.9 or
newer but does not require SparseRREF/SpaSM:

```wl
result = ConformalIBPNeatSelection`NeatTargetSolve[
  originalSymbolicEquations, orderedIntegralColumns, targetAtoms,
  "SelectionMethod" -> "CoefficientDAG",
  "Parameters" -> {x,y}, "NumericalPoint" -> {11,17}];
```

`SelectCoefficientTargetRows[M, targetColumnNumbers, 42013]` is the standalone
numerical interface. Both entry points accept `"PythonExecutable" -> "/path/to/python3"`.
The Python CLI also accepts an input JSON with `Rows`, `Columns`, `Targets`
(one-based column IDs), and `Samples: [{Prime, Entries}]`; each entry is a
one-based `[row, column, integerCoefficient]` triple. Select one sample per call:

```sh
python3 Adapters/coefficient_provenance.py input.json selection.json
```

The result contains original row IDs, target normal forms, and their original
row certificates. `--omit-certificates` omits the certificate coefficients from
the file after checking them. Only the sampled matrix goes through Python;
the selected original symbolic equations remain the reconstruction input.

An experimental faster screening option traces two random combinations of the
targets. Auxiliary variables define these combinations without constraining
the original integral columns:

```wl
result = ConformalIBPNeatSelection`NeatTargetSolve[
  originalSymbolicEquations, orderedIntegralColumns, targetAtoms,
  "SelectionMethod" -> "AggregateCoefficientDAG",
  "AggregateCount" -> 2, "AggregateSeed" -> 260926,
  "Parameters" -> {x,y}, "NumericalPoint" -> {11,17}];
```

The standalone selector accepts the same aggregate options; the Python CLI
uses `--aggregates 2 --seed 260926`. Its certificates cover only the random
combinations. Cancellation can omit a row needed by an individual target,
so **every physical target and its free image must still pass the complete
system check**. The end-to-end adapter enforces this check. A regression test
deliberately creates such a cancellation and confirms rejection. The default
selection method is unchanged.

Its inputs must already use a consistent integral naming convention and the
desired column order. It does not canonicalize a family or choose a finite
basis. The returned certificate covers target normal forms and their free
images, not full symbolic row residuals. An intentionally incorrect row
selection is rejected by the independent full-system reference. All-free
targets and empty systems are supported.

If the input rows already have an independent-rank witness in the selection
field, pass `"InputRowsIndependent" -> True` to either entry point. This skips
the redundant transposed elimination. The augmented reduction still rejects
dependent input rows, and the full-system target check remains mandatory.
The coefficient dependency implementation always computes its own rank and
also rejects a false independence claim.

Load the compatible SpaSM version documented by NeatIBP. That implementation
requires primes at most **46337**; the adapter rejects larger primes rather
than allowing the library to silently change the field. SparseRREF/SpaSM is a
finite-field selector here. It does not itself reconstruct rational functions
of `x,y`.

Selection is a numerical heuristic. Solve the selected **original symbolic**
equations with FiniteFlow or Kira, then compare the requested targets and their
free image atoms against the complete input system at `{11,17}` before accepting
a production reduction. A sampled rank alone is not a closure certificate.
Existing constraints involving only source columns must also be retained.

## First real four-loop benchmark (2026-09-26)

The test used 3000 existing four-loop relations, 2358 columns, 760 retained
boundary-source columns, and 20 historical targets. The sampled rank was 1520.
This is a bounded subset of the 1314910-row production pool, not a complete
four-loop reduction.

| Selection | Original rows retained | Exact target agreement with full test system |
|---|---:|---|
| Existing Python dependency selector | 101 | passed |
| SpaSM, original row order | 56 | passed |
| SpaSM, shorter rows first | 51 | passed |

The `{11,17}` check used an independent FiniteFlow graph. The three symbolic
target reductions also agreed exactly with the complete test system.

Timing must distinguish overhead: Python's selection loop took 0.021 s, while
launch, JSON transfer, selection, and its selected-rank check together took
0.646 s. The SpaSM adapter took 0.147 s, or 0.137 s after row sorting (sorting
excluded). Thus this test establishes **better pruning**, not faster native
elimination. The complete SpaSM comparison process peaked at about 260 MiB.

Kira 2.3 also reduced the same existing equations through its
`reduce_user_defined_system` interface with `config: false`. Reverse integer
weights preserved the supplied column order, including source columns. Its
20 target normal forms agreed exactly with FiniteFlow. The installed Kira uses
Fermat and has no FireFly support. Its full process took 4.97 s (about 61 MiB peak
RSS); the already initialized FiniteFlow symbolic solve took 0.337 s. These
measurements do not establish a Kira speed advantage.

The coefficient dependency implementation also selects 51 rows on this small
matrix. Its numerical original-row certificates all pass. Independent dense
finite-field regression tests cover dependent rows, cancellations, free
targets, source-only constraints, and empty systems. The end-to-end adapter
also rejects an intentionally incorrect selection through its full-system
check.

## Production-sized selection test (2026-09-26)

The dependency system extracted from the complete canonical four-loop pool
contains 136204 rows, 163972 columns, and 1084 targets, including 4037 source
columns. The complete reference pool contains 1314903 nonzero canonical rows.

| Selection | Original rows retained |
|---|---:|
| Existing set-provenance selector | 104615 |
| Weighted coefficient dependency graph | 49082 |

This removes **53.08%** of the rows retained by set provenance. All 1084 target
identities were checked against original rows modulo 42013. An independent
FiniteFlow solve modulo 9223372036854775783, at `{11,17}`, then confirmed that
the selected system gives the same target normal forms as the complete
production pool. All source columns were retained. This is a numerical
selection validation, not a symbolic reduction or a closure certificate.

Coefficient-aware selection plus all original-row certificate checks took
720.82 s (135.06 s forward elimination); the whole Python process took 738.84 s
and peaked at 4.37 GiB. The existing selector's selection loop took 147.78 s.
Thus **pruning improved, but selection itself became slower**. End-to-end
symbolic reduction timing on the selected system is still required. The
experiment saved 20.37 million certificate entries; the optional Wolfram
adapter checks these identities without storing all certificate coefficients
in its returned JSON.

Two random target combinations selected exactly the same 49082 original row
IDs in 41.85 s, including 40.40 s of forward elimination; the process peaked
at about 847 MiB. No individual certificate was recomputed in this test. The
row IDs match the already independently verified selection, but this equality
is not guaranteed on other systems. The timing also includes a Python loop
refactor and different machine load, so the full speed ratio cannot be
attributed to random combinations alone. End-to-end symbolic timing remains
pending.

Direct SpaSM elimination showed substantial intermediate fill: one redundant
independence pass was stopped after exceeding 170 million nonzeros. Skipping
that pass and applying the augmented-identity method still exceeded 110
million intermediate nonzeros; that second test was stopped after 95.2 minutes
without completing a selection. These observations apply to the tested
ordering and implementation, not to every possible SpaSM configuration.
The active frozen four-loop campaign has not been switched to these adapters.

Kira is now being tested on the 49082 selected original symbolic rows, with
all 1084 targets and all source columns retained. The comparison uses two
cores and a 32 GiB process-tree memory budget. Its result will be checked
numerically against the full pool and, for the highest-loop part, exactly
against the independently reconstructed FiniteFlow coefficients. No large
Kira performance result has been accepted yet.

## Kira export and import

`KiraLinearSystem.wl` provides a separate adapter for the existing symbolic
equations. It requires a fresh output directory so that an earlier reduction
cannot be mistaken for the current input.

```wl
Get["/path/to/DE-for-DCI/Adapters/KiraLinearSystem.wl"];
job = ConformalIBPKira`ExportKiraLinearSystem[
  "/path/to/new-job", originalSymbolicEquations, orderedIntegralColumns,
  targetAtoms];
```

If `job["RunRequired"]` is true, run from that directory:

```sh
FERMATPATH=/path/to/fer64 kira --parallel=2 jobs.yaml
```

Then import with:

```wl
rules = ConformalIBPKira`ReadKiraLinearSystem["/path/to/new-job"];
```

Import checks the recorded system and target-list hashes and restores the
original integral/source names. It does not certify reduction correctness;
the complete original system remains the reference for the independent check.
The exported small four-loop test was byte-for-byte identical to the input
actually solved by Kira, and the imported rules passed the exact FiniteFlow
comparison.

## Separate generation experiment

A separate NeatIBP/Singular module-intersection test is retained. It combines
six existing DCI tangent rotations at one four-loop endpoint, at `{11,17}`.
Degree four produced one nonzero relation passing the package's complete DCI
action and contact checks after zero vectors and duplicate equations were
removed. It has not been lifted to symbolic kinematics or inserted into the
production pool. This does not establish generation completeness or an
advantage over the existing conformalIBP syzygies.

All these tests leave lower-loop IBP/DE computation deferred until verified
highest-loop closure.

## Optional smoke test

```sh
NEATIBP_ROOT=/path/to/NeatIBP SPASM_LIBRARY=/usr/local/lib/libspasm.so \
  WolframKernel -script Tests/NeatIBPRowSelection.wls

NEATIBP_ROOT=/path/to/NeatIBP FINITEFLOW_ROOT=/path/to/finiteflow \
  SPASM_LIBRARY=/usr/local/lib/libspasm.so \
  WolframKernel -script Tests/NeatIBPTargetSolver.wls

python3 Tests/CoefficientProvenance.py
FINITEFLOW_ROOT=/path/to/finiteflow \
  WolframKernel -script Tests/CoefficientTargetSolver.wls
```

NeatIBP and SpaSM remain external dependencies. Their source and binaries are
not vendored into this package. `CoefficientDAG` uses only Python's standard
library; FiniteFlow is still needed for symbolic reconstruction and checking.
