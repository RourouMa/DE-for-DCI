"""Fetch and build the audited feyntrop revision into a fresh directory."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

REPOSITORY = "https://github.com/michibo/feyntrop.git"
COMMIT = "ad0d683274977836f5c2ab3e71496ba307413d63"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", nargs="?", type=Path,
                        default=Path(__file__).resolve().parents[1] / "external-tools/feyntrop")
    parser.add_argument("--jobs", type=int, default=4)
    args = parser.parse_args()
    dest = args.destination.resolve()
    if dest.exists() or args.jobs < 1:
        parser.error("destination must not exist and jobs must be positive")
    subprocess.run(["git", "clone", REPOSITORY, str(dest)], check=True)
    subprocess.run(["git", "checkout", "--detach", COMMIT], cwd=dest, check=True)
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=dest, text=True).strip()
    if head != COMMIT:
        raise RuntimeError("unexpected source revision")
    subprocess.run(["make", f"-j{args.jobs}"], cwd=dest, check=True)
    binary = dest / "feyntrop"
    record = {"Repository": REPOSITORY, "Commit": COMMIT, "Executable": str(binary),
              "ExecutableSHA256": hashlib.sha256(binary.read_bytes()).hexdigest()}
    (dest / "DCI-build.json").write_text(json.dumps(record, indent=2) + "\n")
    print(json.dumps(record, indent=2))


if __name__ == "__main__":
    main()
