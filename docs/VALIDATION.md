## 0.2.7: two-point verification by default

Finite-basis construction now checks the necessary zero-sum condition by substitution before extracting the coefficient matrix. This preserves multi-term candidates and boundary-source rows. `FiniteZeroSumPrefilter` passes for a certified three-term combination, nonzero-sum rejection, and source-only input. On the saved 84-row fourth-round example, the earlier direct-prefilter benchmark took 0.52 s versus 10.94 s for coefficient extraction plus summation; this is a prefilter benchmark, not an end-to-end speedup.

Reduction residuals, normal-form checks, full-pool target comparisons, and historical-rule replay now use exactly two numerical points by default. Integral and boundary-source coefficients are checked individually modulo primes 1000003 and 1000033. Symbolic verification requires explicit `"VerificationMode" -> "Exact"`; numerical results do not claim exact certification. Physical finite-integral checks are unchanged. Verification mode and requested points participate in the reduction cache key.

`NumericalVerification`, `ParallelResiduals`, `ReductionReuse`, `TargetReduction`, and `FiniteFlowTargetSelection` pass: good/bad rules, singular-point rejection, two-point count, explicit exact-mode cache separation, parallel row coverage, and boundary-source constraints. Live four-loop jobs retain their frozen 0.2.6 implementation and the independent two-point full-pool verifier.

# Validation Record

## 0.2.6 shared worker options

Parallel generation writes common options (including completed application and symmetry ledgers) once to `WorkerOptions.wl`; each worker input contains only its operator override and seed plan. Worker loading merges the shared association with local overrides; legacy inline-option jobs remain readable. A missing or malformed shared options file fails the worker.

`Workers`, `SeedDeduplication`, and `FailurePropagation` pass, including serial/parallel equation and application equivalence, completed-application exclusion, and finite-combination deduplication. On a real four-loop payload, exact reconstructed options and seed-plan equality pass: the old input was 161,628,958 bytes, the new per-worker input is 205,999 bytes, and shared options are 158,611,640 bytes written once. This measures serialization, not end-to-end speedup. See `VALIDATION_0.2.6.json`. Active four-loop runs remain on their frozen 0.2.5 sources; implementation hashes still prevent unverified checkpoint migration.

## 0.2.5 correctness correction

A reproduced Wolfram control-flow error allowed `Return` inside `Do` to exit the loop without returning failure from the enclosing function. This affected rejection of overlapping contact boundaries and unsupported multiple collision clusters. The correction explicitly propagates those failures. Similar error paths in coefficient extraction, differentiation, worker cache import, symmetry generation, and optional Gram candidates are also corrected.

The new `Tests/FailurePropagation.wls` passes 13 assertions, including actual four-loop overlapping/disjoint collision examples and injected nested failures. Core, linear normalization, boundary reduction, gap campaign, workers, and seed deduplication suites also pass; see `VALIDATION_0.2.5.json`.

**Earlier finite-basis claims involving multiple collision clusters require revalidation.** On a saved four-loop 61-integral support, 11 formerly accepted bare integrals lose finite certification; two of 14 saved inputs are affected. Failure of this conservative validator is not itself proof of divergence. Do not resume old implementation checkpoints or treat earlier exact matrix residual checks as proof of physical validity of all relations. Four-loop closure remains unverified.

Local development validation, 2026-09-20. These checks validate the package interfaces and selected algebra, not the completeness of the four-loop IBP system.

| Check | Result |
| --- | --- |
| Core regression suite | 29 assertions passed; no unexpected Wolfram messages |
| One-loop box DE | Automatic closure on four finite integrals; exact source-free flatness |
| High-power box | Automatically recovered `(1+x^2+x^4)/(3*x^2) G[0,0,2,2,1]` from `G[-2,2,4,0,1]` |
| Independent workers | Four kernel shards agree with serial equations and application IDs |
| FiniteFlow | Reconstructed one-loop reductions agree exactly with rational Gaussian elimination |
| Original four-loop generator comparison | 42 raw operator/seed actions agree, modulo the unit delta constraints |
| Four-loop layout | 13 denominator slots, 4 delta slots, 26 total index slots |
| Four-loop operator classification | 84 rotations, 11 degree classes, matched conformal seed weights |
| ISP restrictions | No automatic promotion of loop-loop numerator ISPs during factor completion |
| Finiteness safety | Equal residues accepted; equal coefficient sum with unequal residues rejected |
| Checkpoint behavior | Resume succeeds on unchanged implementation; source fingerprints recorded |

A supplementary four-loop development run generated and saved an initial extension of 496 relations and reached the subsequent expansion. That longer expansion was stopped during release preparation. It is **not** a passed four-loop closure test or a performance guarantee, and its large local artifacts are not included in the repository. Start a new campaign with the released source rather than resuming a development checkpoint with a different implementation fingerprint.

Not validated end-to-end: full three-/four-loop DE closure using this new package, recursive lower-loop source closure, overlapping collision certificates, and large Ubuntu production reductions. The legacy comparison is an optional test requiring the user's trusted original generator; that source is not redistributed here.
