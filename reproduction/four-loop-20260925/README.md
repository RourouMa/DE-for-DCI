# Four-loop ladder: open epoch-3 snapshot

This snapshot accompanies release **v0.5.0**. It is an unfinished highest-loop
calculation, not a four-loop DE solution. The fifth round has a finite 100-element
cover; the sixth-round joint input/DE rank is 166 and triggers pool expansion.

Download `g4-epoch3-snapshot.tar.gz` and its SHA256 file from
<https://github.com/RourouMa/DE-for-DCI/releases/tag/v0.5.0>.

```sh
sha256sum -c g4-epoch3-snapshot.tar.gz.sha256
tar -xzf g4-epoch3-snapshot.tar.gz
git checkout v0.5.0
python3 scripts/run-four-loop.py --kernel /path/to/WolframKernel \
  --finiteflow /path/to/finiteflow --workers 8 --ff-threads 16 \
  --pool /path/to/g4-epoch3/PortablePool.wl --output runs/g4-epoch3-replay
```

The portable Wolfram-text pool retains the full equations, including lower-loop
contact sources, and the completed operator and symmetry ledgers. The launcher
checks the implementation, family, original input and content hashes before
replaying from the original top. No production absolute paths, reduction caches
or native checkpoints are needed. `Snapshot.json` gives the captured pool size;
`files.sha256` checks individual archive members. The archived fifth-round
expressions are for inspection and are not silently substituted for a new replay.

The small status and basis files in this directory are readable without downloading
the pool. For strategy, caveats, hardware and a fresh run, see the
[collaborator handoff](../../docs/COLLABORATOR_HANDOFF.md).
