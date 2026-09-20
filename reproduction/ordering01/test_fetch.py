"""Small offline tests for archive integrity checks; no GitHub credentials used."""
import contextlib
import hashlib
import io
import json
import sys
import tarfile
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import fetch


class FetchTests(unittest.TestCase):
    def exercise(self, name='reference/test.wl', corrupt=False, bad_payload=False):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            archive = root / 'test.tar.gz'
            content = b'{1,2,3}\n'
            with tarfile.open(archive, 'w:gz') as tar:
                info = tarfile.TarInfo(name)
                info.size = len(content)
                tar.addfile(info, io.BytesIO(content))
            manifest = {'legacy_sources': {}, 'assets': [{'kind': 'runtime',
                'name': archive.name, 'sha256': 'bad' if corrupt else fetch.digest(archive),
                'files': [{'path': name, 'bytes': len(content),
                           'sha256': 'bad' if bad_payload else hashlib.sha256(content).hexdigest()}]}]}
            (root / 'snapshot.json').write_text(json.dumps(manifest))
            args = ['fetch.py', '--local-assets', str(root), '--destination', str(root / 'out')]
            with patch.object(fetch, 'HERE', root), patch.object(sys, 'argv', args), contextlib.redirect_stdout(io.StringIO()):
                fetch.main()
            self.assertEqual((root / 'out' / name).read_bytes(), content)

    def test_valid(self):
        self.exercise()

    def test_corrupt_archive(self):
        with self.assertRaisesRegex(RuntimeError, 'Archive checksum'):
            self.exercise(corrupt=True)

    def test_corrupt_member(self):
        with self.assertRaisesRegex(RuntimeError, 'Payload checksum'):
            self.exercise(bad_payload=True)

    def test_path_traversal(self):
        with self.assertRaisesRegex(RuntimeError, 'Unsafe archive'):
            self.exercise(name='../outside.wl')


if __name__ == '__main__':
    unittest.main()
