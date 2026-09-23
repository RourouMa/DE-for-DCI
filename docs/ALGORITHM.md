# Algorithm and Audit Contract

## Representation and Degrees

For `L` loops and `E` external vectors, let the ordered scalar products be `P_j`. An integral is

`G[n] = integral (product_i d^6 Yi delta(Yi^2)) / product_j P_j^n_j`

with the projective conformal measure understood. Delta indices are stored explicitly and must equal one. Each loop has physical weight four. The propagator incidence matrix contains one for an external-loop product and one for each endpoint of a loop-loop product.

For active loop `Yi`, choose distinct `a,b` from the other loop and external vectors:

`u_i = (Yi.a) b - (Yi.b) a`.

`Yi.u_i = 0` and `div_i u_i = 0`. The stored operator degree is minus the number of appearances of each loop vector in `{a,b}`. Thus external-linear propagators contribute to scaling too. An application is allowed only when `incidence . seed + degree = {4,...,4}`. Whole conformal combinations use only degree-zero operators.

The rotation backend covers the delta-only workflow used here. It is not a general module-intersection implementation for arbitrary denominator-preserving syzygies.

## Contacts

Decompose a rotation into two scalar-coefficient vector terms. For each term, inspect the effective integrand after multiplication by that scalar coefficient. A double loop-loop pole contributes a contact only if the active derivative is an endpoint of that edge. Spectator derivatives produce no such contact.

The retained convention is the original generator's `-2` endpoint contact with the infinity-vector ratio, evaluated after identifying the collision endpoints. Infinity products must cancel in the complete candidate expression. The package does not map any surviving infinity product to an ISP. Simultaneous endpoint contacts unsupported by the implementation are reported rather than dropped.

An emptied loop is converted to a lower-loop source, with remaining dummy loop labels reindexed uniformly. Contact source relations are never interpreted as zero without solving the lower-loop problem.

## Iteration

```text
original finite input
        |
        v
differentiate complete expressions, including coefficients
        |
        v
simplify first -> actual targets
        |
        v
reduce targets + every historical target/representative
        |
        v
seed actual targets AND surviving representatives
  - include simpler centers from relations incident to those representatives
  - axial +/-1 per factor
  - declared completed ladder/box supersectors
  - Cartesian products across independent blocks
  - degree matching and ISP-domain checks
        |
        +-- new rows --> accumulate system --> replay from ORIGINAL input
        |
        v
exact input-span DE closure test
        |
        +-- not closed --> certified finite cover --> next input
        |
        +-- closed block --> explicit source check --> flatness when source-free
```

The result distinguishes raw support, single finite integrals, constant and variable combinations, targets, and input/output counts. None is silently substituted for the others. Previous input elements are reconstructed in the current system; obsolete dependent expressions are not appended to inflate the basis.

Local relation neighbors are essential even for a one-loop box: an unconstrained single axial shift changes conformal weight, so degree-zero operators may initially receive only the center itself. When that center survives, the system automatically follows simpler neighbors in its existing IBP rows. For example, the regression suite recovers `G[-2,2,4,0,1] = (1+x^2+x^4)/(3 x^2) G[0,0,2,2,1]` without importing any precomputed one-loop identity.

## Finite Cover

Write the divergent part of all reduced rows as `C(z) H`. Clear rational denominators and collect polynomial coefficients in all kinematic variables. The row span over the rational numbers of those coefficient vectors is the required constant envelope.

Candidates are two-term differences in that envelope, followed by primitive row-reduced constant vectors. Prioritize small support and small integer coefficients. Accept a candidate only if collision residues cancel and it increases the constant span rank. Select exactly enough independent candidates to span the actual envelope, and reconstruct every original row exactly. Single finite integrals are kept separately.

This avoids both kinematic-dependent definitions and arbitrary `H_i-H_1` assumptions. It does not promise a globally minimum-support solution. A valid cover outside the enumerated candidates can exist even when this conservative implementation returns `UnverifiedFiniteCover`.

## Deliberate Limits

- External/collinear regularity is an assumption on the deformed external configuration, not inferred from the Gram matrix alone.
- The built-in collision certificate handles no divergent cluster, or an isolated two-loop double-pole residue. More complex overlapping clusters require further mathematics or an explicit validator.
- A completed scalar ladder block is inferred from the supported ladder convention. Other family completions must be declared by the caller.
- Lower-loop DE recursion, protected-propagator syzygies, large distributed matrix storage, and global sparse-basis optimization are not implemented in version 0.1.
- Passing a finite seed range is not evidence that all magic relations have been found. Unseen targets, self-reduced complex targets, degree coverage gaps and rejected applications are exposed for the next extension.

## Selection objective and reporting

Finite coverage and DE closure are correctness requirements; simplicity is the optimization objective. Prefer sparse rational-constant combinations, without enlarging the actual differentiated span merely to avoid combinations. The constant builder is not a proof that variable coefficients are forbidden or that a failed search is impossible. Before trying a variable cover, assess candidate completeness, IBP and supersector symmetry, and compare costs. Record the autonomous decision; differentiate coefficients as well as integrals. The default builder still searches constant covers only. Three-loop constant feasibility guides diagnosis; it must not be assumed for four loops.

Every round reports raw support, all finite basis components, independently measured rank, closure level, verification type and artifact location. Missing rank stays unknown. Every relation-pool expansion reports the new epoch and top replay; basis selection alone does not increment the epoch. See [the reporting contract](REPORTING.zh-CN.md).
