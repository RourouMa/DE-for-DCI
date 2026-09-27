# DE-for-DCI / ConformalIBP

A Wolfram Language research package for auditable IBP reduction and differential-equation iteration of **four-dimensional embedding-space conformal integrals at variable loop order**.

Version 0.6.0 is an experimental research package. The four-loop ladder result below has a complete, verified source-retaining differential-equation system. This family-specific result does not imply support for every conformal family or completeness of a bounded IBP seed search. Unsupported cases return diagnostics.

## Current local work (27 September 2026)

The [0.6.0 strategy notes](docs/STRATEGIES_0.6.0.zh-CN.md) describe the integrated physical-coordinate finite-cover route and the rule to repair relations after three increases along a fixed direction. The new from-Top ladder run has **12** highest-loop finite elements and **12+7+4 = 23** elements in the full source-retaining system; both independently passed full-pool numerical verification. The tennis-court cover has decreased from **31 to 23** at highest loop and from **46 to 23+11+4 = 38** in the full source-retaining system; both passed independent verification. The prior verified baselines were **19+7+4 = 30** and **31+11+4 = 46**. The compressed bases have substantially more complicated DE entries; [the recorded selection lesson](docs/FINITE_COVER_COMPLEXITY_LESSONS.zh-CN.md) prioritizes simple atoms and short constant combinations and requires a matrix-complexity comparison before adopting a smaller basis.

The [complete four-loop ladder system](reproduction/four-loop-full-20260927/README.zh-CN.md) closes with **53+24+7+4 = 88 individual integrals**, including all lower-loop sources. Three independent native-pool checks and the exact full curvature check passed. A rational invertible transformation gives a [constant-residue dlog form with 18 letters](reproduction/four-loop-full-20260927/dlog/README.zh-CN.md). [All 88 analytic integral functions](reproduction/four-loop-full-20260927/analytic-88/README.zh-CN.md) are exported as explicit finite Chen/GPL sums, with every integration constant fixed. Two independent direct top integrations passed the predeclared **0.1% statistical precision** check at (1/4,3/4), using the complete sector sum as one integrand. Earlier unsafe concurrent-sector runs and correlated-error estimates remain documented and excluded from acceptance. The operational bound **70** applies to the highest-loop quotient. The [25 September collaborator handoff](docs/COLLABORATOR_HANDOFF.md) is a historical release snapshot.

Use `python3 scripts/run-four-loop.py --help` for the configurable production
launcher. A portable [epoch-3 relation-pool snapshot](reproduction/four-loop-20260925/README.md)
is supplied separately as a Release asset; a clone contains code, documentation,
small basis/status files and corrected three-loop matrices. There is no Codex or
Claude runtime dependency. The current local 0.6.0 source passes [52 regression groups](docs/VALIDATION_0.6.0.json).
The [0.5.0 validation](docs/VALIDATION_0.5.0.json) records the 44 groups for the earlier release.

## Reusing the latest work for four-loop tennis court

The [transfer workflow](docs/FOUR_LOOP_TENNIS_WORKFLOW_20260927.zh-CN.md) collects the low-power finite-cover policy, source-retaining closure checks, exact dlog helpers, boundary construction, analytic iteration, and numerical validation. [Adapters/DLogTools.wl](Adapters/DLogTools.wl) exposes exact constant-residue decomposition, rational Hermite extraction and gauge verification; it does not perform an automatic full gauge search.

The [tropical Monte Carlo adapter](Adapters/TropicalMonteCarlo.zh-CN.md) accepts a verified momentum-graph JSON for a new topology and records normalization, fixed sample budgets, actual threads, warnings and errors. Its [ladder pilot](reproduction/four-loop-tropical-20260927/README.zh-CN.md) passes exact U/F mapping checks but has **not** reached the 0.1% top precision target. The accepted complete-sum Vegas result remains available. External feyntrop is pinned and installed separately; no large relation pools, binary caches or compiled libraries are included in this source snapshot.

## Counting before DE iteration (0.5.0)

The four-loop ladder campaign uses the user-estimated same-loop threshold **70**:
`MasterCountStrategy -> "UserEstimate", MasterCountUserUpperBound -> 70`.
When the rational rank of the input plus both derivatives exceeds this value,
the campaign repairs the relation pool and replays from the original top before
advancing differentiation. This operational threshold is not a certified count;
all lower-loop sources and the full closure checks remain required. The reusable
configuration is [four-loop-count-policy.wl](Examples/four-loop-count-policy.wl).

`RunDE` first attempts a budgeted geometric reference count, separately for the
active loop order, using the input's sectors and exact kinematic symmetries.
The default `MasterCountPreflight -> "Advisory"` allows DE work to proceed when
the 60-second counting budget expires or applicability remains uncertified;
such an estimate never truncates a basis. `"Required"` instead returns an
explicit diagnostic before the first DE round if no usable bound was established,
unless the explicit `"UserEstimate"` strategy supplies a positive stopping threshold.

`CriticalPointCount` includes multiplicities and detects nonisolated critical
loci. `TopDerivativeBound` is an optional tighter route using fresh FiniteFlow
relations for a bounded top-derivative ansatz. Its default scope is the highest
loop quotient, with all lower-loop source rows retained. A one-loop top bound
of four was established independently of the known MI and DE. Two/three-loop
cost tests did not establish a certified tight bound within the chosen budgets,
so this method is retained as a reserve, not the default preflight.
See [counting scopes, certificates and cost results](docs/MASTER_COUNT_BOUND.zh-CN.md).

The [older Ubuntu note](docs/UBUNTU_HANDOFF.zh-CN.md) is a historical archive guide, not the current run configuration. Use the English handoff above for this release.


## Current seeding and finite-priority policy (0.4.0)

For the three-loop experience, read the [posterior seeding guide (Chinese)](docs/THREE_LOOP_POSTERIOR_SEEDING.zh-CN.md):
use complete DE residuals to select seeds, complete their compatible operator
blocks, extend symmetry in the same domain, and replay after pool expansion.
The guide separates corrected full-system evidence from historical pool
comparisons and states which scheduling steps still require campaign scripts.

- `FiniteBasisPolicy -> "StrictOrdering"` remains the default. Explicit
  `"PreserveActualSpan"` selects simple finite representatives inside the actual
  reduced input/DE span, with exact membership and coverage checks. It is a
  separate basis policy, not strict preservation of ordering free columns.
  See [the method and its validation scope](docs/PRESERVE_ACTUAL_SPAN.zh-CN.md).
- `"FiniteSupportThenSpan"` retains every normal-form atom when all are individually
  finite, and uses `"PreserveActualSpan"` when divergent support remains. The active
  branch is recorded per round. The four-loop campaign uses this policy to avoid
  unnecessary first-round relation searches; its threshold 100 applies to the
  whole same-loop space even when direct finite support enlarges the top span.
- `SeedGeometry -> "InverseTargets"` now applies every degree-compatible operator
  to each inverse-selected seed (`InverseOperatorPolicy -> "Complete"`). The old
  `"DirectHit"` mode remains available for controlled comparisons. See
  [the same-pool ablation and four-loop transfer plan](docs/RESIDUAL_OPERATOR_COMPLETE_SEEDING.zh-CN.md).
- Contracted sources are checked as complete expressions before admitting ordinary
  or coupled IBP relations. Uncertified divergent sources return a diagnostic;
  see [the contact-source audit](docs/CONTACT_SOURCE_VALIDITY.zh-CN.md).
- O6 (`TierReference`) prefers retained columns in this order: finite factorized,
  uncertified factorized, finite connected, uncertified connected. Each tier uses
  the ordering01 structural/reference-shape key. O1–O6 and the old `ClosureFirst`
  profile are selectable; see [strategy details](docs/STRATEGIES_0.3.0.zh-CN.md).
- When every remaining reduced integral is individually finite, `BuildFiniteBasis`
  returns that support directly. It does not run a row-space minimization or a
  finite-combination search. Coefficients and all lower-loop sources are retained.
  Only divergent support enters constant finite-combination construction.
- Seed planning is parallel, applications are globally deduplicated before dispatch,
  and worker payloads contain only needed history/cache entries. Every expansion
  extends ordinary/factorized symmetry and restarts from the original top.
- General families use `FamilyOnly` with explicitly justified supersectors. The
  [tennis-court family example](Examples/tennis-court-family.wl) includes two horizontal
  ladder embeddings and one vertical embedding derived from actual contractions.
  Its campaign uses `SeedDomain -> "Extended"` to seed those declared supersectors;
  the package never infers that arbitrary loop pairs have either orientation.
- Load FiniteFlow for production runs. Symbolic row-space and inverse calculations
  then use FiniteFlow with exact reconstruction checks. Numerical residual checks
  default to one point and retain all rows and boundary coefficients.

```wolfram
InitializeFiniteFlow[finiteFlowInstallDirectory, finiteFlowMathlinkDirectory];
FiniteFlow`FFNThreads = 24;
config = Get[FileNameJoin[{repositoryDirectory, "Examples", "tennis-court-family.wl"}]];
result = RunDE[config["Family"], config["Input"],
  Sequence @@ config["CampaignOptions"], "OutputDirectory" -> outputDirectory];
```

Load the package and `Examples/kinematics.wl` before this snippet. This example
configures an independent computation and does not bundle the large production
archives. The adaptive O7 historical pool failed the joint high/lower consistency
audit despite zero homogeneous curvature; its old exported block remains
quarantined. A fresh 0.4.0 regeneration now verifies the complete ladder system
(19+7+4 elements) and tennis system (31+11+4 elements), including all lower sources,
generic full-pool reduction checks and exact full curvature. See the
[corrected three-loop artifacts and verification scope](reproduction/corrected-three-loop-20260923/README.zh-CN.md).
Older checkpoint hashes remain incompatible; start a fresh package campaign.
Historical research snapshots require separate validation against the corrected
admission rules.

**Reproduce the legacy fourth round (66 finite elements):** use the [frozen ordering01 snapshot](reproduction/ordering01/README.zh-CN.md). Its historical Release assets include the complete solved linear system, exact column order, seed/operator records, reduction rules and finite combinations. A normal `git pull` does not download these assets; run its `fetch.py` first. This is a separate reproducibility fixture, not a claim that the generic package or the four-loop DE is closed.

## Quick Start

Wolfram Language 13 or newer is required. Development tests were run with the local Wolfram installation; a license permitting multiple simultaneous kernels is needed only for multi-process generation. The small exact solver needs no external software.

From the repository directory, run:

```sh
# macOS
/Applications/Wolfram.app/Contents/MacOS/WolframKernel -script Examples/one-loop.wls

# Ubuntu: use the executable supplied by your Wolfram installation
WolframKernel -script Examples/one-loop.wls
```

In a fresh Mathematica session:

```wolfram
Get[FileNameJoin[{repositoryDirectory, "Kernel", "ConformalIBP.wl"}]];
Get[FileNameJoin[{repositoryDirectory, "Examples", "kinematics.wl"}]];

family = LadderFamily[1, kinematics, {x, y}];
result = RunDE[family, G[1,1,1,1,1],
  "Solver" -> "Exact", "OutputDirectory" -> "runs/box"];

result["Status"]
result["Basis"]
result["Matrices"]
```

The one-loop example reaches a four-element basis and passes an exact flatness check. This is a small regression example, not a four-loop performance benchmark.

Only reduction is also supported:

```wolfram
result = RunReduction[family, {G[-2,2,4,0,1]},
  "OutputDirectory" -> "runs/reduction"];
result["ReducedInputs"]
```

## Family Input

Supply the family, external kinematics and target integral(s). `LadderFamily[L,...]` supplies the ladder convention. For another topology:

```wolfram
family = CreateFamily[<|
  "Name" -> "MyFamily",
  "External" -> {X1,X2,X3,X4},
  "Loops" -> {Y1,Y2},
  "Variables" -> {x,y},
  "Kinematics" -> kinematics,
  "Propagators" -> Automatic,
  "TopSector" -> {1,1,0,1, 0,1,1,1, 1},
  "Completion" -> "LadderBlocks"
|>];
FamilyPropagators[family]
```

The complete scalar-product basis contains every `SP[Xi,Yj]` and every distinct `SP[Yi,Yj]`. It must retain ISP slots even when those slots are not denominators. Self-products are unit delta cuts appended by the package. A user-supplied permutation of the complete propagator list is preserved exactly; `TopSector` must follow that permutation.

Default order: external products grouped by loop, adjacent loop edges, other loop edges, delta cuts. Thus the four-loop ladder has **13 denominator propagators plus 4 cuts**, represented in **26 index slots**, not 26 denominators:

```wolfram
G[1,1,0,1, 0,1,0,1, 0,1,0,1, 0,1,1,1,
  1,1,1,0,0,0, 1,1,1,1]
```

`Kinematics` must specify the entire symmetric external Gram matrix, including external norms. The built-in derivative is the symmetric Gram deformation `C_z = (d Gram/dz).Inverse[Gram]/2`. A singular Gram matrix requires an explicit association of `"ExternalDerivatives" -> <|z -> matrix, ...|>`; the matrices are checked against the Gram derivatives.

Supported integrands have integer powers of scalar products and unit delta indices in physical dimension four. Nonlinear propagators, nonunit delta derivatives, other dimensions, dimension regularization, and degenerate massless/collinear finiteness analysis are not implemented. Kinematics are symbolic and generic, away from exceptional denominators and singular Gram loci. Finiteness tests assume the deformed external configuration removes external/collinear singularities.

## What Is Automated

1. Analytic delta-tangent rotation operators, classified by all loop-scaling degrees. Four loops give 84 rotations in 11 degree classes. This backend does not need Singular and is not an arbitrary protected-propagator syzygy solver.
2. Component-local **axial +1/-1** seed neighborhoods and seed/operator degree matching. Independent factor neighborhoods use Cartesian products by default; `"BlockExpansion" -> "SingleBlock"` enables the measured smaller alternative. All degree classes are considered, and empty classes are reported.
3. IBP actions including endpoint-local isolated double-collision contact terms. Whole finite combinations are additionally acted on by degree-zero operators before checking infinity cancellation.
4. All loop permutations and Gram-preserving external permutations. Distinct factor blocks undergo independent external transformations, including simultaneous transformations on every block. Every generated support is canonicalized.
5. Gaussian column ordering that prefers factorized free representatives, zero loop-loop ISP indices, and simple isolated boxes. High powers in an isolated tadpole are not, by themselves, a complexity failure.
6. Re-reduction of historical targets and representatives after every system extension, followed by replay from the original input. A self-rule `G -> G` is recorded, never counted as a successful simplification, and remains a seed center. Simpler neighbors in existing relations containing a surviving representative also become centers. This supplies conformal centers that a lone unconstrained axial shift would miss; the applied seed geometry remains axial. The audit lists these added centers.
7. Constant-coefficient finite combinations extracted from the actual reduced expressions. Simple two-term candidates are considered first; bare finite integrals remain single basis elements. Exact coverage and collision cancellation are checked before the next differentiation.
8. Full coefficient product rules, simplification of whole combinations before target collection, and closure testing on the **same differentiated input span**. Stable counts alone do not imply closure.

### Factorized Supersectors and ISP Restrictions

`"Completion" -> "LadderBlocks"` completes disconnected scalar ladder blocks to ladders, with isolated one-loop factors completed to boxes. It preserves the requested left/right external assignment. This is not a union of arbitrary sectors. For other topologies use `"Completion" -> "FamilyOnly"` and explicitly list allowed supersectors as denominator ID lists:

```wolfram
"SuperSectors" -> {{1,2,3,4,6,8,9}, {1,2,4,5,6,7,8,9}}
```

A positive index must fit one declared domain. Loop-loop ISPs remain nonpositive unless a specified supersector explicitly promotes them. Positive loop-loop powers are capped at two by default. No hidden global seed truncation is used. A numerator connecting two loops is conservatively treated as a connection, not as a product of independent scalar factors.

### Finite Combinations

`BuildFiniteBasis[family, rows]` uses the constant coefficient span of the actual rational coefficient rows. It never invents differences merely because two integrals are divergent. A zero coefficient sum is a candidate condition, not proof of finiteness: the built-in checker also compares contracted isolated-collision residues modulo symmetry. Unequal residues reject the difference.

The built-in `BuildFiniteBasis` search constructs rational-constant combinations. This is the preferred search, not a universal prohibition on variable coefficients. The objective is a finite, closed DE with a simple basis and simple equations. A separately constructed variable-coefficient cover requires an explicit assessment of the constant search, relation completeness, and alternatives, together with finiteness and exact coverage; coefficient derivatives must be included. The default builder does not yet automate that fallback. See [reporting and basis-selection policy](docs/REPORTING.zh-CN.md). Their count equals the rank of the actual constant divergent coefficient span when the available candidates are certified. This is **not** a proof of the globally sparsest basis, nor of the true irreducible MI count with a more complete IBP system. Overlapping or larger collision clusters stop the built-in certification. An expert-supplied `"FiniteValidator" -> Function[{family,expression}, ...]` may replace it, but assumes responsibility for that proof.

## Lower-Loop Sources and Closure

Contacts are retained as `BoundaryIntegral[L, indices]` in the standard lower-loop order. They are not zero and are not differentiated as constants. The engine does **not yet recursively close the lower-loop source systems**.

- `"Closed"`: derivatives return to the selected input span, all retained source residuals vanish, and the source-free connection is flat.
- `"ClosedModuloBoundary"`: the same-loop block closes, but lower-loop source terms remain explicitly recorded.
- `"QuotientClosed"`: same situation when the user explicitly sets `"BoundaryPolicy" -> "Quotient"`. `"Closed"` is still `False`.
- `"RoundLimit"`, `"ExpansionLimit"`, or a `Failure`: unfinished computation, not closure.
- `"ReductionFixedPoint"`: the current degree-matched local search generated no new rows. It is not a proof of global IBP completeness.

Read `Basis`, `Matrices`, `BoundaryRows`, `AllInputDEResidualSources`, and `InputReconstructionSources` together. **Close the highest-loop block first**, retaining every lower-loop source symbolically. Only after that closure is verified, collect the final source list and solve the lower-loop families together, then connect their DEs. Computing lower-loop closure during an unfinished highest-loop search repeats work whenever a new source appears.

For large pools, `"TargetSelector" -> "FiniteFlowDirect"` reconstructs only the queried normal forms. A fresh full-pool finite-field solve checks all retained query and image columns. Its certificate has `"VerificationScope" -> "FullPoolTargetNormalForms"`; it does not claim that unrequested rules or every symbolic equation residual were reconstructed. Numerical verification is the default; explicitly requested exact verification uses the existing selected-equation backend.

Verified target forms can be reused when the implementation, family, complete ordered pool and verification settings match, and every new query atom is already covered by that certificate. Atomic queries retain their reconstructed coefficients without redundant expansion; combined physical expressions still pass the usual exact coverage checks.

`"QueryCoveragePolicy" -> "ActualRows"` allows an on-demand campaign to continue when the complete input and derivative rows have a certified finite cover, even if an intermediate atom is absent from the pool. Historical identities and the master-count threshold still apply. The default remains `"AllTargets"`. `"CheckpointFormat" -> "MX"` writes local binary snapshots behind the usual hash-checked `Checkpoint.wl` entry point; use the default `"WL"` format for portable checkpoints. For large local states, `"CheckpointFormat" -> "MXFileHash"` verifies SHA256 of the immutable serialized file before loading it, avoiding repeated hashing of the full symbolic state. Its `"HashType"` explicitly distinguishes the storage hash from the legacy expression hash. Both native formats require a compatible local Wolfram runtime.

`"DeferBoundaryCoefficientSimplification" -> True` combines highest-loop coefficients while retaining the complete, unsimplified source coefficients during the search. It changes no source term or relation. Source coefficients are fully combined when same-loop closure is established. The default is `False`.

## FiniteFlow and Independent Kernels

Install FiniteFlow from its upstream project and build it for the host platform; the package does not ship binaries or third-party source. Then load explicit local paths:

```wolfram
InitializeFiniteFlow[finiteFlowInstallDirectory, finiteFlowMathlinkDirectory];
result = RunDE[family, targets, "Solver" -> "FiniteFlow", "Workers" -> 4];
```

`Automatic` uses FiniteFlow when loaded, otherwise the exact solver. Exact reduction is capped at 1500 columns by default. Reconstruction is followed by checks at one numerical kinematic point by default (all integral coefficients, including boundary sources). `"VerificationMode" -> "Numerical"` is the default; `"NumericalVerificationPoints" -> {{11,17}}` specifies the point for a two-parameter system; an explicit two-point list remains supported. Singular points fail verification. These checks are numerical evidence, not an analytic proof. Symbolic residual checks run only with explicit `"VerificationMode" -> "Exact"`. A custom trusted solver can be provided as `Function[{equations, columns, queries}, rules]`.

`Workers -> 4` launches up to four independent kernel processes, not Wolfram `Parallel*`. IBP application IDs are independent of shard numbering. Use `"KernelExecutable"` to specify a different kernel path. Reduction itself is not sharded by this option. Failed worker job directories are retained for inspection.

## Optional NeatIBP-style selection and Kira

The [linear-system adapters](Adapters/README.md) apply SparseRREF/SpaSM or
coefficient-aware target dependency selection to existing conformalIBP
equations. They also export arbitrary homogeneous systems to Kira. Generator
syzygies and the default campaign solver are unchanged. A production-sized
numerical comparison reduced 104615 selected original rows to 49082 while
preserving all 1084 target normal forms in an independent full-pool check;
this does not by itself establish symbolic closure or an end-to-end speedup.

## Checkpoints and Ubuntu

All machine-specific paths are supplied at runtime. On Ubuntu, clone this repository, install/activate Wolfram, and build the Linux FiniteFlow backend. Do not copy macOS dynamic libraries.

```sh
git clone https://github.com/RourouMa/DE-for-DCI.git
cd DE-for-DCI
WolframKernel -script Tests/RunTests.wls
WolframKernel -script Examples/one-loop.wls
```

Use `ResumeRun["runs/box"]` in Wolfram to resume. Checkpoints store the family, original input, accumulated system, application ledger, historical reductions and limits. Content, family, version and source fingerprints are checked. **Only load trusted checkpoints:** they are executable Wolfram expressions. Changed implementation or finite-basis logic requires a new campaign from the original input, not reuse of stale ledgers.

Output directories contain a checkpoint and `epochN/roundM/` artifacts: input, derivatives/targets, reduction rules, reduced DE, finite basis and count summary. The checkpoint also records rejected IBP applications, degree coverage gaps and pending relations. `MaxRounds` and `MaxSystemExpansions` are per invocation. Large-system memory planning and scheduler integration remain the caller's responsibility.

## Tests

```sh
WolframKernel -script Tests/RunTests.wls
WolframKernel -script Tests/Workers.wls
WolframKernel -script Tests/FiniteFlow.wls /path/to/finiteflow/install /path/to/finiteflow/mathlink
# Optional comparison with a trusted original local four-loop generator:
WolframKernel -script Tests/CompareLegacy.wls /path/to/IBP4loop.wl
```

The repository excludes original research inputs, PDFs and large relation caches. Selected verified matrices, analytic functions and audit certificates are bundled under `reproduction/`; their documentation identifies the retained external inputs needed for full relation-pool reconstruction.

## Optimized reduction and default seeding (0.2.0)

`RunDE` and `RunReduction` now default to original `TopSector` seeds,
`"GapSeeding" -> True`, `"GenerationPolicy" -> "OnDemand"`, and
`"ReductionScope" -> "Targets"`. DE generation is skipped when queries are covered
and a finite cover exists. For an existing pool, uncovered queries and failures
of finite-cover construction trigger local seeding around **all original-domain
symmetry images** of the unresolved integrals, including connected targets.
If this adds no new equation, the same-domain search widens to the current
queries, representatives and neighboring equation terms. Every extension
replays the original inputs; an exhausted search is not a closure certificate.
`GenerationHistory` records centers, gaps, policy, rejected applications and work.

Families default to `"IntegralOrdering" -> "TierReference"` (O6, 四层导航). `ClosureFirst` remains an explicit legacy profile. Searching for a
finite, closed DE does **not** prioritize eliminating outside-family columns.
Exact symmetry canonicalization still chooses an original-domain image when
available; this does not remove an independent direction.

`RunDE` defaults to `"BasisPreference" -> "None"`. The historical post-closure optimization is available explicitly with `"BasisPreference" -> "FamilyAfterClosure"`. The priority is:
certified finiteness, verified full differential-equation closure, then as many
original-family basis elements as possible. With this opt-in enabled, once `Closed` and `FlatnessVerified`
are true, the package searches already reduced finite candidates for an
invertible change of basis. Candidates must lie in the closed span **including
all boundary terms**. Necessary outside-family integrals remain in the basis.
It updates the matrices with `(D[T,z] + T.A[z]).Inverse[T]`, updates original-input
reconstruction, and checks flatness before accepting the replacement. Failure
retains the verified closed basis. `FamilyPreferenceAudit` and
`FamilyPreferenceTransform` record the decision and change of basis. Preference
is optimized over available certified candidates, not over every possible integral.

`ClosedModuloBoundary`, `QuotientClosed`, and finite coverage of a derivative round
are not full closure and do not authorize this optimization. `ClosureFirst` is
a priority policy, not a guarantee that an arbitrary column order will find a
finite cover or that a bounded IBP search will close.

Old family specifications containing `"LadderFirst"` are switched
to `ClosureFirst` only when `FamilyAfterClosure` is explicitly enabled, with both requested and actual
orderings recorded. For historical reproduction only, explicit `LadderFirst` or
`Legacy` family orderings remain available; `"BasisPreference" -> "None"` disables
the DE override and post-closure optimization. No seed domain is widened by this
basis preference. Changed source hashes require a fresh campaign rather than
silently resuming an older checkpoint.

Explicit alternatives:

```wolfram
RunDE[family, top, "SeedDomain" -> "Extended"]; (* permit completion/supersector seeds *)
RunDE[family, top, "BlockExpansion" -> "SingleBlock"];
RunDE[family, top, "GapSeeding" -> False];        (* broad centers on generation *)
GenerateSystem[family, targets, "SeedCenters" -> "AllOriginalImages"];
GenerateSeeds[family, targets, Automatic, "SeedCenters" -> "Representative"];
```

`SeedCenters` accepts `Raw`, `Representative`, or `AllOriginalImages` on direct
seed/system generation. Missing original-domain images are reported as
`UnmappedCenters`. Direct `IBPRelation` remains a low-level evaluator; the
seed-domain policy governs `GenerateSeeds`, `GenerateSystem`, and campaigns.
Changing seed policy does not erase declared completion domains needed to
represent generated equations. `SingleBlock` remains opt-in because its
combination with every domain-only closure problem is not yet established.

Included implementation optimizations: compiled ordinary IBP shifts; shared
operator-degree seed geometry; coefficient-wise rational normalization and
one expansion per coefficient-matrix row; sparse FiniteFlow output; dependency
selection of original equation rows; single-point residual/idempotence checks;
full-pool target comparison for the FiniteFlow selector; sampling, permutation,
symmetry-orbit, application and verified-reduction caches; worker cache transfer
and checkpoint fingerprints. See [the optimization and strategy report](docs/OPTIMIZATIONS_20260920.zh-CN.md).

Gram relations remain an explicitly loaded candidate extension in
`Extensions/GramCandidates.wl`; campaigns never add them automatically.
Old checkpoints intentionally fail implementation/version checks: start a new
campaign rather than transplanting an old application ledger into changed code.

Run the portable regression suite with:

```sh
python3 scripts/run-tests.py --kernel /path/to/WolframKernel
# Include the optional FiniteFlow tests:
FINITEFLOW_ROOT=/path/to/finiteflow python3 scripts/run-tests.py --kernel /path/to/WolframKernel
```

Archive comparison scripts in `Tests/` additionally require the baseline/job
files described at their beginning; they are not part of the portable suite.

For parallel residual checks, `"VerificationWorkers" -> 4` uses independent
kernels to verify every selected original equation. It defaults to 1 and does
not change the mathematical acceptance checks. Relation-frontier construction
is also deferred until broad seeding is needed and uses a single support scan.
See [the verification notes](docs/PARALLEL_VERIFICATION.zh-CN.md).

Recommended hardware allocation: `RecommendedWorkerCount[]` returns four fifths of logical CPUs, rounded to the nearest integer (32 → 26). Set both `"Workers"` and `"VerificationWorkers"` explicitly; FiniteFlow threads are configured separately. See [parallel configuration](docs/PARALLEL_VERIFICATION.zh-CN.md).

Version 0.2.2 computes the seed plan once in the parent process and dispatches only operator/seed applications absent from the completed ledger. Fully overlapping ordinary neighborhoods launch no workers. See [seeding deduplication](docs/SEEDING_DEDUPLICATION.zh-CN.md) and [17-group validation](docs/VALIDATION_0.2.2.json).

Version 0.2.3 also skips worker startup when finite-combination applications are already completed. Pending finite combinations still run. This changes dispatch only; the active four-loop campaign remains on its frozen 0.2.2 source. See [targeted validation](docs/VALIDATION_0.2.3.json).

Version 0.2.4 prepares large seed plans across center partitions before global application deduplication. `"SeedPlanningWorkers" -> Automatic` follows `"Workers"`; `"SeedPlanningThreshold" -> 64` keeps small plans serial. Planning and IBP generation run in separate phases. See [parallel seed planning](docs/PARALLEL_SEED_PLANNING.zh-CN.md).

The 0.2.4 release passed all [18 validation groups](docs/VALIDATION_0.2.4.json), including complete serial/parallel plan equivalence and unchanged generated relation/application sets.

### Joint seed/operator identities (0.2.8)

`FindCoupledIBPRelations[family, seeds]` searches constant rational combinations
of complete degree-zero rotation actions across the supplied seeds. It solves
exact constraints for auxiliary-infinity cancellation, output domain and literal
collision residues before admitting an identity. Primitive actions rejected by
ordinary seeding are retained in this joint search. Every admitted identity is
also checked against an independent rational ordinary action plus the complete
contact sum, before symmetry canonicalization. Lower-loop sources are retained.

```wolfram
joint = FindCoupledIBPRelations[family, conformalSinglePoleSeeds];
newRows = joint["Equations"];
certificates = joint["Certificates"];
```

To include explicit groups during system generation:

```wolfram
system = GenerateSystem[family, targets,
  "SeedDomain" -> "Extended",
  "CoupledSeedGroups" -> {seedGroup1, seedGroup2},
  "CompletedCoupledGroups" -> previousJointLedger];
```

Joint groups run on the coordinator after ordinary workers merge. Their separate
completion ledger is keyed by implementation, family, seed group and requested
operators; completed or rejected primitive applications do not suppress them.
Only search within each supplied group is claimed. Seeds must be conformal and
in the declared domain, with at most one double loop pole. Operators must be
verified degree-zero rotations. Unsupported endpoint contacts are reported;
outputs with unsupported overlapping clusters are excluded by exact constraints.
No claim of exhaustive identities or general convergence proof is made.

`CoupledIBPRelation[family, terms]` independently verifies a specified identity;
each term is an association with `"Coefficient"`, `"Seed"`, and `"Operator"`.
Changing the implementation invalidates old checkpoint fingerprints. Explicitly
archived historical equations can be reused in a documented new experiment, but
old checkpoints must not be relabeled as generated by the new implementation.

Parallel workers receive only completed finite-expression applications needed by their extra finite-seed branch. Ordinary applications are already deduplicated by the coordinator. Their symmetry cache is restricted to requested targets, pending seeds, finite seeds, and canonical representative self-mappings; other mappings are recomputed exactly on demand. `WorkerPayload` reports ledger counts, cache counts, and serialized sizes. This avoids replicating the full campaign history and cache in every worker.

Joint action searches also admit seeds with disjoint double-collision pairs. Each completed relation must cancel every literal pair residue and pass the independent rational-action check. Overlapping multi-pair seeds remain unsupported; the ordinary contact calculation is unchanged. This extends relation discovery, not the finite-basis validator or the closure acceptance criterion.

Joint searches match seed weights to each generated operator degree, so legal mixed-degree pairs can participate together. Sparse constraint assembly avoids allocating coefficients for absent integral/action pairs; complete candidate actions still undergo the independent rational and residue checks.

### Physical-coordinate finite coverage (0.6.0)

`RunPhysicalCoordinateDE[family, {top}, physicalEquations, "OutputDirectory" -> path]` restarts from the original input and reconstructs complete physical rows directly in an independent finite basis. It uses constant physical candidates, exact constant cancellations of over-limit propagator powers, hard finite-representative limits of three for external-loop denominators and two for loop-loop denominators, physical derivative caching, a full-pool finite-field rank witness and rational coordinate reconstruction. Sources are retained in the immutable physical pool; this API reports highest-loop closure modulo sources, not a full mixed-loop DE.

Initialize FiniteFlow first. Options include `"Workers"`, `"MasterCountUserUpperBound"`, `"GrowthChainThreshold" -> 3`, `"VerificationPoint" -> {11,17}`, `"ExtraFiniteCandidates"`, and `"FiniteReferenceBasis"`. The latter uses a finite candidate frame only as a coordinate reference: all coordinates are recomputed in the current physical pool and only the actual independent span is selected, preferring constant combinations when available. A candidate is not verified closure until `scripts/verify-physical-coordinate-run.wls RUN FINITEFLOW_ROOT [PACKAGE_ROOT]` passes a fresh full-pool solve, native differentiation, basis independence, numerical homogeneous curvature, and original-top rational coverage.

Repeated chains trigger `RelationRepairRequired` before another DE input is accepted. `AssessGrowthChains` also drives the ordinary `RunDE` repair path. `DifferentiatePhysicalRelations` derives identities from complete finite source-free physical relations, including coefficient derivatives; callers must verify the parent identities are in their physical pool. No projected reduction identity may be promoted to a physical relation.

The planned IBP generator now collects equations, application records and rejected applications with `Reap`/`Sow`, preserving their exact native order, symmetry expansion and deduplication.

`ReconstructFiniteCoordinateSystem[families, basis, originalInputs, physicalEquations, "OutputDirectory" -> path]` reconnects a verified highest-loop basis with declared lower-loop finite candidates. `families` maps each loop count to a complete `CreateFamily` result. It recomputes every native derivative, maps all contact sources to their declared families, reconstructs the full rational matrices, and checks full-pool independence, top coverage, and numerical curvature. Saved DE matrices are not used as equations. Run `scripts/verify-finite-coordinate-system.wls RUN FINITEFLOW_ROOT [PACKAGE_ROOT]` for a separate process that recomputes derivatives and checks the saved matrices against a fresh complete-pool solve.

For the four-loop closure search, use `"FiniteCoverPolicy" -> "LowPoleClosureFirst"` with [the four-loop physical-cover options](Examples/four-loop-physical-closure-policy.wl). Low-pole simple representatives take precedence over matching cover cardinality to the current rank. A larger covering space receives a separate rational coverage certificate and actual-rank certificate. After closure, use the verified finite definitions as a reference frame and replay with `"PreserveActualSpan"` to compress the system, then reverify closure.

The [four-loop simple physical cover](reproduction/four-loop-physical-cover-20260927/README.zh-CN.md) has independently verified highest-loop closure with **53 individual integrals**, with external-loop powers at most 3 and loop-loop powers at most 1. Its [complete mixed-loop extension](reproduction/four-loop-full-20260927/README.zh-CN.md) contains 88 individual integrals and retains every lower-loop source. The dlog basis and analytic functions are provided alongside the original atom basis.

同步验证见 [SYNC_20260927.json](docs/SYNC_20260927.json)。从 package 根目录运行 `python3 scripts/verify-artifacts.py` 可核对已发布结果的 SHA-256 清单。
