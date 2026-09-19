# Validation Record

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
