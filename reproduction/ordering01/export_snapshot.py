#!/usr/bin/env python3
"""Maintainer-only export of the frozen legacy calculation, not the new engine."""
import argparse
import hashlib
import json
import shutil
import tarfile
from pathlib import Path

HERE = Path(__file__).resolve().parent


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(8 * 1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--source', type=Path, required=True)
    p.add_argument('--outputs', type=Path, required=True)
    p.add_argument('--destination', type=Path, required=True)
    a = p.parse_args()
    campaign = a.outputs / 'four_loop_ladder/closure_campaign'
    order = campaign / 'ordering01'
    a.destination.mkdir(parents=True, exist_ok=True)
    vendor = HERE / 'legacy'
    vendor.mkdir(exist_ok=True)
    names = ['IBP4loop.wl', 'IBP4IterationTools.wl', 'IBP4ActualDECombinationAudit.wl',
             'IBP4LocalSmallBlocks.wl', 'IBP4ShortConstantBasis.wl',
             'IBP4ConstantDECoefficientBlocks.wl', 'IBP4ConstantFromTop.wl',
             'IBP4FactorizedOrdering.wl', 'IBP4FactorCache.wl', 'IBP4SeedDomain.wl',
             'IBP4GeneratorVersion.wl', 'IBP4LaurentOperatorCache.wl',
             'IBP4ContactLaurentCache.wl']
    for name in names:
        shutil.copy2(a.source / name, vendor / name)
    for name in ['ClosureOutputAdmission.wl', 'CollisionResidueSymmetry.wl']:
        shutil.copy2(a.outputs / name, vendor / name)

    runtime = []
    for f in sorted((order / 'from_top').rglob('*.wl')):
        runtime.append((f, 'reference/' + str(f.relative_to(order / 'from_top'))))
    for name in ['IBP4ReductionRules.txt', 'OrderingSummary.wl', 'Projection.wl']:
        runtime.append((order / 'reduction' / name, 'reduction/' + name))
    for f in sorted((order / 'query01/reduction').glob('*')):
        if f.is_file():
            runtime.append((f, 'query01/reduction/' + f.name))
    for name in ['CompositionChecks.wl', 'SolveSummary.wl', 'ComplexIdentityFocus.wl']:
        runtime.append((order / 'query01' / name, 'query01/' + name))
    for name in ['SystemManifest.wl', 'SolveSummary.wl', 'CompositionChecks.wl',
                 'OrderingSummary.wl', 'ReferenceFactorOrdering.wl']:
        if (order / name).exists():
            runtime.append((order / name, 'system/' + name))
    base = a.source / 'IBP4_from96/constant_from_top/remaining_dot/compact/system/IBP4EquationsWithSymmetry.txt'
    matrix = [(base, 'matrix/BaseEquationsWithSymmetry.wl')]
    for name in ['CanonicalAddedEquations.wl', 'ColumnOrder.wl', 'SolverQueries.wl',
                 'QueryMap.wl', 'CanonicalReductionRules.wl']:
        matrix.append((order / name, 'matrix/' + name))

    seeds = []
    # Preserve actual seed/operator pairings and audits, not bulky intermediate maps.
    wanted = {'SeedData.wl', 'SeedSummary.wl', 'SeedProvenance.wl', 'FocusTargets.wl',
              'ComponentCatalogues.wl', 'ComponentSourceMap.wl', 'IndependentQA.wl',
              'HistoricalChecks.wl', 'GeneratorUpgrade.wl', 'GenerationAudit.wl',
              'SystemManifest.wl', 'CoupledActionProvenance.wl', 'README.md', 'RESULTS.md'}
    for directory in sorted(campaign.iterdir()):
        if directory.is_dir():
            for f in sorted(directory.iterdir()):
                if f.is_file() and f.name in wanted:
                    seeds.append((f, 'provenance/campaign/' + directory.name + '/' + f.name))
    for pattern in ['Closure*.wl', 'closure_*.cpp']:
        for f in sorted(a.outputs.glob(pattern)):
            seeds.append((f, 'provenance/scripts/' + f.name))
    opdir = a.source / 'IBP4_ladder_rotated_syzygy_degree_fixed'
    for f in sorted(opdir.iterdir()):
        if f.is_file():
            seeds.append((f, 'operators/' + f.name))
    for f in sorted(a.source.glob('ibp4_*.cpp')):
        seeds.append((f, 'provenance/native/' + f.name))

    manifest = {'schema': 1, 'repository': 'RourouMa/DE-for-DCI',
                'release': 'ordering01-repro-2026-09-21',
                'branch': 'legacy ordering01, not the generic package runs/',
                'chain': [1, 4, 12, 26, 66], 'closed': False,
                'projection': 'G4 quotient; G3 source terms are NOT physically zero',
                'matrix_rows': 2833280, 'matrix_columns': 2850483, 'assets': [],
                'legacy_sources': {str(f.relative_to(HERE)): digest(f)
                                   for f in sorted(vendor.glob('*.wl'))}}
    for kind, entries in [('runtime', runtime), ('matrix', matrix), ('seeds', seeds)]:
        name = 'ordering01-' + kind + '.tar.gz'
        archive = a.destination / name
        files = []
        with tarfile.open(archive, 'w:gz', compresslevel=6) as tar:
            for src, rel in entries:
                if not src.is_file():
                    raise FileNotFoundError(src)
                files.append({'path': rel, 'bytes': src.stat().st_size, 'sha256': digest(src)})
                tar.add(src, arcname=rel, recursive=False)
        entry = {'name': name, 'kind': kind, 'bytes': archive.stat().st_size,
                 'sha256': digest(archive), 'files': files}
        manifest['assets'].append(entry)
        print(name, entry['bytes'], entry['sha256'], flush=True)
    (HERE / 'snapshot.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
