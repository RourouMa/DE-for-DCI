# Reproducibility checks

`Replay.wl` records a fresh local run of `replay.wls`, followed by `verify.wls`.
For all four rounds it compares exact basis definitions, freshly regenerated
targets and reduced DE expressions against the released reference. Algebraic
coverage checks and the isolated-double-pole admission test all passed.
The output counts are 4, 12, 26, 66. This is not a closure certificate.

`OperatorAudit.wl` in the parent directory checks all 84 operators in 11
degree classes and a round trip from the original MX to portable WL text.
The frozen generator fingerprint matches the production contact-local fix.

`SeedSmoke.wl` records a limited targeted16 shard-1 seed replay, one saved
seed per nonempty operator row. Each checked action agrees with the direct
operator implementation, and accepted outputs pass the explicit domain
guards. It is not a full regeneration of the historical seed campaign.

`python3 reproduction/ordering01/test_fetch.py` tests valid extraction,
archive corruption, payload corruption and path traversal rejection.

The reference payload and all assets have SHA-256 checks in `snapshot.json`.
`fetch.py` verifies both compressed archives and their individual members.
Validation of solved-rule replay does not by itself validate a new full
FiniteFlow solve; that optional run produces its own `Verification.wl`.

Tests were run on the source Mac with the version recorded in `Replay.wl`.
No Ubuntu runtime result is asserted until these checks are run on Ubuntu.
