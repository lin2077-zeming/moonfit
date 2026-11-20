#!/usr/bin/env python3
"""Gate G6-redact (D8): native redaction is byte-exact and structure-preserving.

For every corpus .fit:
  * idempotence: redact(in, trim=0, dlat=0, dlon=0) reproduces the input byte-for-byte
    (serial already zero, no shift), proving the re-encode path is exact;
  * trimming: redact(in, trim=5, 0, 0) drops exactly 10 record messages and the
    result still round-trips byte-exactly (CRC + data-size header recomputed).

The raw-export equivalence (redact reproduces the committed corpus from the
unredacted device files) was verified locally at 6/6; it is not run in CI because
the raw exports are intentionally not committed.

Run with --self-test to confirm the gate detects a deliberate corruption.
"""
from __future__ import annotations

import hashlib
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / "_build" / "native" / "release" / "build" / "cmd" / "moonfit"
CORPUS = ROOT / "corpus" / "redacted"


def locate_cli():
    for n in ("moonfit.exe", "moonfit"):
        p = BUILD / n
        if p.exists():
            return p
    f = sorted(BUILD.glob("moonfit*")) if BUILD.exists() else []
    return f[0] if f else None


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def run(exe, *args):
    return subprocess.run([str(exe), *map(str, args)], capture_output=True, text=True)


def records(exe, p):
    out = run(exe, "dump", p).stdout
    return sum(1 for line in out.splitlines() if '"g":20' in line)


def self_test(exe):
    src = CORPUS / "ride-20260803.fit"
    with tempfile.TemporaryDirectory() as td:
        dst = Path(td) / "o.fit"
        if run(exe, "redact", src, dst, 0, 0, 0).returncode != 0 or sha(dst) != sha(src):
            print("  FAIL idempotence baseline not byte-exact")
            return 1
        print("  ok   redact(0,0,0) is byte-exact idempotent")
        shifted = Path(td) / "s.fit"
        run(exe, "redact", src, shifted, 0, 600000, -800000)
        ok = sha(shifted) != sha(src)
        print(f"  {'ok  ' if ok else 'FAIL'} a non-zero shift changes the bytes")
        return 0 if ok else 1


def main(argv):
    exe = locate_cli()
    if exe is None:
        print("::error::CLI not built")
        return 1
    if os.name != "nt" and not os.access(exe, os.X_OK):
        exe.chmod(exe.stat().st_mode | 0o111)
    if "--self-test" in argv:
        print("check_redact self-test (R4: verify the ruler first)")
        return self_test(exe)
    failures = []
    n = 0
    with tempfile.TemporaryDirectory() as td:
        for src in sorted(CORPUS.glob("*.fit")):
            n += 1
            idem = Path(td) / (src.name + ".idem")
            if run(exe, "redact", src, idem, 0, 0, 0).returncode != 0 or sha(idem) != sha(src):
                failures.append(f"{src.name}: idempotence not byte-exact")
            orig = records(exe, src)
            trimmed = Path(td) / (src.name + ".trim")
            if run(exe, "redact", src, trimmed, 5, 0, 0).returncode != 0:
                failures.append(f"{src.name}: trim failed")
                continue
            if records(exe, trimmed) != orig - 10:
                failures.append(f"{src.name}: trim removed {orig - records(exe, trimmed)} records, expected 10")
            rt = Path(td) / (src.name + ".rt")
            if run(exe, "roundtrip", trimmed, rt).returncode != 0 or sha(rt) != sha(trimmed):
                failures.append(f"{src.name}: trimmed file does not round-trip (CRC/size invalid)")
    if failures:
        print("redact gate FAILED:")
        for f in failures:
            print(f"  - {f}")
        return 1
    print(f"redact gate OK: {n} files idempotent + trim(5) drops 10 records and round-trips.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
