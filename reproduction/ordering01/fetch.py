#!/usr/bin/env python3
"""Download private release artifacts and verify every extracted payload."""
import argparse
import hashlib
import json
import subprocess
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
    parser = argparse.ArgumentParser()
    parser.add_argument('--all', action='store_true', help='Include matrix and seed provenance')
    parser.add_argument('--local-assets', type=Path, help='Verify/extract already downloaded assets')
    parser.add_argument('--destination', type=Path, default=HERE / 'data')
    a = parser.parse_args()
    manifest = json.loads((HERE / 'snapshot.json').read_text())
    for rel, expected in manifest['legacy_sources'].items():
        if digest(HERE / rel) != expected:
            raise RuntimeError('Frozen source mismatch: ' + rel)
    dest = a.destination.resolve()
    dest.mkdir(parents=True, exist_ok=True)
    downloads = a.local_assets or dest / 'downloads'
    downloads.mkdir(parents=True, exist_ok=True)
    for asset in manifest['assets']:
        if not a.all and asset['kind'] != 'runtime':
            continue
        archive = downloads / asset['name']
        if not archive.exists():
            if a.local_assets:
                raise FileNotFoundError(archive)
            subprocess.run(['gh', 'release', 'download', manifest['release'], '--repo',
                            manifest['repository'], '--pattern', asset['name'],
                            '--dir', str(downloads)], check=True)
        if digest(archive) != asset['sha256']:
            raise RuntimeError('Archive checksum mismatch: ' + str(archive))
        expected = {f['path']: f for f in asset['files']}
        with tarfile.open(archive) as tar:
            members = tar.getmembers()
            if len(members) != len(expected) or {m.name for m in members} != set(expected):
                raise RuntimeError('Unexpected archive member list')
            for member in members:
                path = (dest / member.name).resolve()
                if not member.isfile() or dest not in path.parents:
                    raise RuntimeError('Unsafe archive entry: ' + member.name)
                if member.size != expected[member.name]['bytes']:
                    raise RuntimeError('Size mismatch: ' + member.name)
            tar.extractall(dest, members=members)
        for rel, info in expected.items():
            if digest(dest / rel) != info['sha256']:
                raise RuntimeError('Payload checksum mismatch: ' + rel)
        print('Verified:', asset['name'], len(expected), 'files', flush=True)


if __name__ == '__main__':
    main()
