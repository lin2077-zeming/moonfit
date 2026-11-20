#!/usr/bin/env python3
"""Gate G2: byte-exact decode->encode round trip over the whole corpus.

Runs the native `moonfit roundtrip in out` for every redacted corpus file and
asserts the re-encoded file is byte-identical (SHA-256) to the input. This is the
strongest statement the project makes about its decoder: the parsed structure,
replayed verbatim, reproduces the original bytes including both CRCs.

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
    for name in ("moonfit.exe", "moonfit"):
        p = BUILD / name
        if p.exists():
            return p
    found = sorted(BUILD.glob("moonfit*")) if BUILD.exists() else []
    return found[0] if found else None


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def roundtrip(exe, src, dst):
    proc = subprocess.run([str(exe), "roundtrip", str(src), str(dst)], capture_output=True, text=True)
    return proc.returncode


def self_test(exe):
    src = CORPUS / "ride-20260803.fit"
    with tempfile.TemporaryDirectory() as td:
        dst = Path(td) / "out.fit"
        if roundtrip(exe, src, dst) != 0 or sha(dst) != sha(src):
            print("  FAIL baseline round trip not byte-exact")
            return 1
        print("  ok   baseline round trip is byte-exact")
        # Corrupt one byte of a copy; round trip must still succeed (walker does
        # not check CRC) but the output CRC is recomputed, so it must differ.
        bad = Path(td) / "bad.fit"
        data = bytearray(src.read_bytes())
        data[20] ^= 0xFF
        bad.write_bytes(bytes(data))
        out = Path(td) / "out2.fit"
        rc = roundtrip(exe, bad, out)
        ok = rc == 0 and sha(out) != sha(bad)
        print(f"  {'ok  ' if ok else 'FAIL'} corrupted input re-encodes with a fixed CRC (differs)")
        return 0 if ok else 1


def main(argv):
    exe = locate_cli()
    if exe is None:
        print("::error::CLI not built; run moon build cmd/moonfit --target native --release")
        return 1
    if os.name != "nt" and not os.access(exe, os.X_OK):
        exe.chmod(exe.stat().st_mode | 0o111)
    if "--self-test" in argv:
        print("check_g2 self-test (R4: verify the ruler first)")
        return self_test(exe)
    failures = []
    n = 0
    with tempfile.TemporaryDirectory() as td:
        for src in sorted(CORPUS.glob("*.fit")):
            dst = Path(td) / (src.name + ".rt")
            rc = roundtrip(exe, src, dst)
            n += 1
            if rc != 0:
                failures.append(f"{src.name}: roundtrip exit {rc}")
            elif sha(dst) != sha(src):
                failures.append(f"{src.name}: SHA-256 mismatch after round trip")
    if failures:
        print("Gate G2 FAILED:")
        for f in failures:
            print(f"  - {f}")
        return 1
    print(f"Gate G2 OK: {n} corpus files re-encode byte-identical (SHA-256).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
