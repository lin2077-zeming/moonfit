#!/usr/bin/env python3
"""Gate 0: prove the committed corpus is still byte-identical.

Every other gate in this project measures behaviour against the real device
files under corpus/redacted/. If Git ever applies line-ending normalisation to
a .fit file, the committed blob stops being the bytes the device wrote and the
G2 byte-exact round-trip assertion becomes meaningless rather than failing.

This script runs first in CI and compares each tracked corpus file against
corpus/redacted/SHA256SUMS. It also fails if a .fit is recorded with the
`text` attribute, which would mean .gitattributes regressed.
"""
from __future__ import annotations

import hashlib
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CORPUS = ROOT / "corpus" / "redacted"
SUMS = CORPUS / "SHA256SUMS"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def git_attributes() -> dict[str, str]:
    files = [str(p.relative_to(ROOT)) for p in sorted(CORPUS.rglob("*")) if p.is_file()]
    if not files:
        return {}
    out = subprocess.run(
        ["git", "check-attr", "text", "eol", "binary", "--"] + files,
        cwd=ROOT, capture_output=True, text=True, check=True,
    ).stdout
    attrs: dict[str, str] = {}
    for line in out.splitlines():
        path, _, rest = line.partition(": ")
        attrs.setdefault(path, "")
        attrs[path] += f" {rest.strip()}"
    return attrs


def main() -> int:
    if not SUMS.exists():
        print(f"::error file={SUMS}::{SUMS.name} is missing")
        return 1

    expected: dict[str, str] = {}
    for line in SUMS.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        digest, _, name = line.partition("  ")
        expected[name.strip()] = digest.strip()

    failures: list[str] = []
    for name, digest in sorted(expected.items()):
        path = CORPUS / name
        if not path.exists():
            failures.append(f"missing: {name}")
            continue
        actual = sha256(path)
        if actual != digest:
            failures.append(f"digest mismatch: {name} expected {digest} got {actual}")

    on_disk = {
        str(p.relative_to(CORPUS)).replace("\\", "/")
        for p in CORPUS.rglob("*") if p.is_file() and p.name != "SHA256SUMS"
    }
    for extra in sorted(on_disk - set(expected)):
        failures.append(f"untracked by SHA256SUMS: {extra}")

    for path, attrs in sorted(git_attributes().items()):
        if path.endswith(".fit") and "text: set" in attrs:
            failures.append(f".fit tracked as text (EOL normalisation risk): {path}")

    if failures:
        print("Gate 0 FAILED:")
        for item in failures:
            print(f"  - {item}")
        return 1

    print(f"Gate 0 OK: {len(expected)} corpus files verified byte-identical.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
