# Collaborator handoff: conformal ladder and tennis-court DEs

Snapshot: 25 September 2026, package 0.5.0. Start here for the current computation;
the older Ubuntu and ordering01 notes describe separate historical campaigns.
Repository: <https://github.com/RourouMa/DE-for-DCI>.

This is the Wolfram Language package developed with Codex assistance, together
with Python launchers and audit scripts. It can be inspected or developed using
Claude Code or another coding tool; there is no Codex runtime dependency.

## Verified three-loop results

| Family | Three-loop basis | Two-loop basis | One-loop basis | Full system |
|---|---:|---:|---:|---:|
| Ladder | 19 | 7 | 4 | 30 |
| Tennis court | 31 | 11 | 4 | 46 |

These are independent finite basis counts in the verified relation pools, not a
proof of the globally minimal number of master integrals. All final elements are
individually finite; no combination basis is hidden in these counts. Tennis had
47 candidates before one dependent two-loop element was removed. The three-loop
count remained 31.

The corrected generator independently regenerated the relations and reconstructed
both full DEs. Checks include finite-basis and original-top coverage, an independent
generic-point full-pool check of the reconstructed queries, and exact full
curvature: 900/900 zero entries for ladder and 2116/2116 for tennis. Numerical
full-pool agreement is not described as a symbolic proof of every IBP residual.
The corrected results reuse previously discovered candidate bases, rather than
claiming an unattended fresh basis search reproduced every historical step.
Matrices, verification reports and a portable curvature checker are in
[`reproduction/corrected-three-loop-20260923`](../reproduction/corrected-three-loop-20260923/README.zh-CN.md).

## Reduction strategy

1. Differentiate complete physical inputs in both kinematic variables, including
   coefficient derivatives for combinations. Reduce them using finite-field
   reconstruction with FiniteFlow; retain every lower-loop contact source.
2. Use actual unresolved derivative expressions to select inverse seeds. For each
   selected seed, complete all compatible operator actions and the corresponding
   symmetries in the allowed family/supersector domain. Deduplicate applications
   globally and retain the completed application ledger.
3. Prefer simple finite representatives. The adaptive three-loop work selected
   representatives inside the actual rational input/DE span when finite support
   alone was insufficient. Ladder used TierReference ordering; tennis used an
   explicit O7 ordering and topology-derived horizontal/vertical ladder
   supersectors. A historical tennis variable-coefficient intermediate cover was
   eventually replaced by the final 31 individually finite integrals.
4. After expanding a relation pool, replay from the original top and recheck old
   identities. Report input rank, joint input-and-DE rank, and finite basis count
   separately. For example, first-round joint rank 3 was covered by 4 finite
   ladder atoms or 6 tennis atoms; these quantities need not be equal.
5. Close the highest-loop block first, with lower sources retained symbolically.
   Only after that closure is independently verified, collect the final sources,
   reduce the lower-loop families, assemble the full triangular DE and test its
   complete curvature. Zero highest-loop curvature alone is insufficient.

For detailed seeding evidence and qualifications, see
[`THREE_LOOP_POSTERIOR_SEEDING.zh-CN.md`](THREE_LOOP_POSTERIOR_SEEDING.zh-CN.md).

## Why the four-loop system is still open

The current accepted relation pool (epoch 3) contains 210,881 raw relations from
602,136 completed operator/seed applications. The same-loop replay has:

| Round | Input rank | Input + both DE directions: rank | Accepted finite output count |
|---|---:|---:|---:|
| 1 | 1 | 3 | 4 |
| 2 | 4 | 9 | 13 |
| 3 | 13 | 28 | 37 |
| 4 | 37 | 64 | 68 |
| 5 | 68 | 100 | 100 |
| 6 | 100 | 166 | Not accepted; relation repair triggered |

Thus a finite 100-element representation has been obtained, but its derivatives
still introduce 66 additional independent directions under the present finite
relation pool. This is the concrete failure of the same-input closure test.
The working threshold of 100 is the researcher's estimate for the entire
four-loop component, including its same-loop subsectors and factorized elements.
It is **not** a proved critical-point upper bound. Exceeding it triggers additional
relations and a replay; it does not justify dropping directions or asserting
that the true MI count is 166.

Earlier targeted expansions did remove spurious directions and complicated
survivors: round 3 fell from 31 to 28, and a later expansion removed five
high-complexity surviving atoms. This motivates searching for missing relations,
but it does not prove that the current seed/operator/symmetry coverage is
complete or that the estimate 100 is correct. The collision/contact admission
rules also have explicit unsupported cases. A bounded search that adds no rows
is not a completeness theorem. The next work is therefore to improve valid
relation coverage and finite representatives, not to solve lower-loop DEs early.

Large symbolic expressions, symmetry canonicalization, seed planning and rational
reconstruction make this expensive. More RAM/cores help throughput, but do not
resolve a missing-identity or unsupported-mathematics problem by themselves.
No four-loop closure or completion-time guarantee is claimed.

## Run the current program

Dependencies: Python 3.9+, Wolfram Language 13+ and a host-compatible
[FiniteFlow build with its Mathematica interface](https://github.com/peraro/finiteflow/blob/master/README.md).
The current four-loop route does not require Singular; geometric counting is an
optional experimental facility and is not used for the threshold 100.

```sh
git clone https://github.com/RourouMa/DE-for-DCI.git
cd DE-for-DCI
export FINITEFLOW_ROOT=/path/to/finiteflow
python3 scripts/run-tests.py --kernel /path/to/WolframKernel

# A dependency/configuration check without generating any IBP or DE:
python3 scripts/run-four-loop.py --kernel /path/to/WolframKernel \
  --finiteflow "$FINITEFLOW_ROOT" --workers 8 --ff-threads 16 \
  --output runs/g4-configuration-check --configure-only

# A fresh highest-loop campaign; choose a DIFFERENT, empty output directory:
python3 scripts/run-four-loop.py --kernel /path/to/WolframKernel \
  --finiteflow "$FINITEFLOW_ROOT" --workers 8 --ff-threads 16 \
  --output runs/g4-fresh
```

Use `--mathlink /path/to/interface` if the interface is not in the installation's
`mathlink` directory. The launcher freezes its source and writes progress to
`run.log`, `Events.wl` and `loop4/`. It includes the production threshold,
full-pool target verification, complete inverse actions, same-loop finite-cover
policy, and targeted complexity repair. `--max-rounds`, `--max-expansions`, and
`--max-complexity-repairs` bound the work; a limit or failure is unfinished work.

The optional [epoch-3 release snapshot](../reproduction/four-loop-20260925/README.md)
contains a portable relation pool and application ledgers. Add
`--pool /path/to/PortablePool.wl` to replay that pool from the original top.
It does not import old reduction rules. Source/family/pool/ledger compatibility
checks must pass; use the matching release checkout. It is not a completed DE.

The engine stops with an explicit status if finite-cover or complexity repair
needs further research. Before starting any lower-loop computation, independently
verify highest-loop original-input coverage, finite basis, derivative closure and
homogeneous curvature, while preserving all source rows. The current launcher
never starts a lower-loop campaign. `ClosedModuloBoundary` remains distinct from
a complete closed system. Native MX checkpoints are local-runtime snapshots,
not portable interchange files; do not edit their hashes to force compatibility.

## Computing resources

The current Linux host has **128 GB installed RAM, 24 physical CPU cores and 32
logical threads**, with 26 independent Wolfram workers in the production run.
These are observed configuration details, not a benchmark proving a minimum.

| Purpose | RAM | CPU capacity | Initial worker setting |
|---|---|---|---|
| Small tests and code exploration | 16–32 GB | 4–8 physical cores | 1–4 |
| Smaller four-loop experiments | 64 GB | 8–16 physical cores | 4–8 |
| Recommended main four-loop workstation | **128 GB** | **16–32 physical cores** | **8–16**, increase after measuring memory |
| Broader pools / several experiments | 256 GB or more | 32–64 physical cores | Measure before increasing concurrency |

The last three rows are planning estimates based on this workflow, not completed
four-loop scaling benchmarks. Budget at least 100 GB of free fast local SSD for
a fresh campaign and more for many immutable checkpoints/pool versions. Historical
archives can occupy several hundred GB; disk use is not a RAM estimate. Single-core
speed also matters because some Wolfram stages are serial. There is no GPU backend.

The number of FiniteFlow threads and the number of independent Wolfram processes
are separate settings. This package launches independent kernels, so confirm that
the license permits that many simultaneous processes; a nominal subkernel limit
alone is not sufficient. See Wolfram's
[controlling versus computing process explanation](https://support.wolfram.com/36293).

## Useful entry points for complementary work

Read `Kernel/Iteration.wl`, `SeedPlanning.wl`, `TargetReduction.wl`,
`SpanPreservingFiniteBasis.wl` and `Complexity.wl`, together with the seeding guide.
Promising bounded comparisons are complete operator coverage near the round-6
residuals, simpler constant finite representatives within the actual span, and
symmetry/domain coverage. Preserve admitted full source rows and compare replays
on the same inputs. Keep the older ordering01 and tennis exploratory snapshots
separate from the corrected results; their historical certificates do not validate
relations under the current admission rules.
