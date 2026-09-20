# DE-for-DCI / ConformalIBP

A Wolfram Language research package for auditable IBP reduction and differential-equation iteration of **four-dimensional embedding-space conformal integrals at variable loop order**.

Version 0.2.4 is an experimental, tested extraction of the ladder workflow. It does not assert that the four-loop ladder is closed, that every possible conformal family is supported, or that a bounded seed search finds all IBP identities. Unsupported cases return diagnostics instead of fabricated finite combinations or a false closure certificate.

For the ongoing four-loop computation, legacy checkpoint status and migration to a larger Ubuntu host, read the [Chinese handoff note](docs/UBUNTU_HANDOFF.zh-CN.md). It distinguishes the published package from the separate large production archives.

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

The chosen combinations contain rational constants, not `x`, `y` or other kinematic parameters. Their count equals the rank of the actual constant divergent coefficient span when the available candidates are certified. This is **not** a proof of the globally sparsest basis, nor of the true irreducible MI count with a more complete IBP system. Overlapping or larger collision clusters stop the built-in certification. An expert-supplied `"FiniteValidator" -> Function[{family,expression}, ...]` may replace it, but assumes responsibility for that proof.

## Lower-Loop Sources and Closure

Contacts are retained as `BoundaryIntegral[L, indices]` in the standard lower-loop order. They are not zero and are not differentiated as constants. The engine does **not yet recursively close the lower-loop source systems**.

- `"Closed"`: derivatives return to the selected input span, all retained source residuals vanish, and the source-free connection is flat.
- `"ClosedModuloBoundary"`: the same-loop block closes, but lower-loop source terms remain explicitly recorded.
- `"QuotientClosed"`: same situation when the user explicitly sets `"BoundaryPolicy" -> "Quotient"`. `"Closed"` is still `False`.
- `"RoundLimit"`, `"ExpansionLimit"`, or a `Failure`: unfinished computation, not closure.
- `"ReductionFixedPoint"`: the current degree-matched local search generated no new rows. It is not a proof of global IBP completeness.

Read `Basis`, `Matrices`, `BoundaryRows`, `AllInputDEResidualSources`, and `InputReconstructionSources` together. To build a full triangular system, solve the retained lower-loop families separately and connect their DEs; do not erase the sources.

## FiniteFlow and Independent Kernels

Install FiniteFlow from its upstream project and build it for the host platform; the package does not ship binaries or third-party source. Then load explicit local paths:

```wolfram
InitializeFiniteFlow[finiteFlowInstallDirectory, finiteFlowMathlinkDirectory];
result = RunDE[family, targets, "Solver" -> "FiniteFlow", "Workers" -> 4];
```

`Automatic` uses FiniteFlow when loaded, otherwise the exact solver. Exact reduction is capped at 1500 columns by default. Reconstruction is followed by checks at exactly two numerical kinematic points (all integral coefficients, including boundary sources). `"VerificationMode" -> "Numerical"` is the default; `"NumericalVerificationPoints" -> {{11,17},{13,19}}` overrides the points for a two-parameter system. Singular points fail verification. These checks are numerical evidence, not an analytic proof. Symbolic residual checks run only with explicit `"VerificationMode" -> "Exact"`. A custom trusted solver can be provided as `Function[{equations, columns, queries}, rules]`.

`Workers -> 4` launches up to four independent kernel processes, not Wolfram `Parallel*`. IBP application IDs are independent of shard numbering. Use `"KernelExecutable"` to specify a different kernel path. Reduction itself is not sharded by this option. Failed worker job directories are retained for inspection.

## Checkpoints and Ubuntu

All machine-specific paths are supplied at runtime. On Ubuntu, clone this private repository using your GitHub authorization, install/activate Wolfram, and build the Linux FiniteFlow backend. Do not copy macOS dynamic libraries.

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

The repository excludes original research inputs, PDFs, large relation caches and computed campaign outputs. No four-loop closure result is bundled or implied.

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

Families default to `"IntegralOrdering" -> "LadderFirst"`: prefer original-domain
symmetry representatives and eliminate outside-domain columns first. Use
`CreateFamily[Join[KeyDrop[family, {"Hash"}],
<|"IntegralOrdering" -> "Legacy"|>]]` for the previous ordering.

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
selection of original equation rows; two-point residual/idempotence checks;
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
