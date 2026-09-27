"""Verify every published ArtifactManifest.json from a clone or source archive."""
import argparse
import hashlib
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    root = args.root.resolve()
    count, problems = 0, []
    manifests = sorted(root.rglob("ArtifactManifest.json"))
    if not manifests:
        parser.error("no artifact manifests found")
    for manifest in manifests:
        for name, expected in json.loads(manifest.read_text()).items():
            file = (manifest.parent / name).resolve()
            count += 1
            if root not in file.parents or not file.is_file():
                problems.append({"Manifest": str(manifest.relative_to(root)), "MissingOrOutsideRoot": name})
            elif hashlib.sha256(file.read_bytes()).hexdigest() != expected:
                problems.append({"Manifest": str(manifest.relative_to(root)), "HashMismatch": name})
    print(json.dumps({"Passed": not problems, "Manifests": len(manifests),
                      "HashChecks": count, "Problems": problems}, indent=2))
    return int(bool(problems))


if __name__ == "__main__":
    raise SystemExit(main())
