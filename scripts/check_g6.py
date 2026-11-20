#!/usr/bin/env python3
"""Gate G6: robustness / mutation rejection via `moonfit verify`.

The exhaustive single-byte mutation sweep over the embedded corpus file runs as
a MoonBit test on all four backends (see src/fit/fit_test.mbt). This CI gate
complements it across ALL six corpus files: each pristine file must verify, and
single-byte mutations at the header, a data byte, and the trailing CRC must all
be rejected (CRC-16 detects every single-byte error). Typed-error cases
(truncation, bad signature/base type, missing definition, overlong field) are
asserted as MoonBit tests.

Run with --self-test to confirm the gate detects a deliberate corruption.
"""
from __future__ import annotations

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


def verify(exe, path):
    return subprocess.run([str(exe), "verify", str(path)], capture_output=True, text=True).returncode


def self_test(exe):
    src = CORPUS / "ride-20260803.fit"
    if verify(exe, src) != 0:
        print("  FAIL pristine file does not verify")
        return 1
    print("  ok   pristine corpus verifies")
    data = bytearray(src.read_bytes())
    data[100] ^= 0xFF
    with tempfile.TemporaryDirectory() as td:
        bad = Path(td) / "bad.fit"
        bad.write_bytes(bytes(data))
        ok = verify(exe, bad) != 0
    print(f"  {'ok  ' if ok else 'FAIL'} a mutated byte is rejected")
    return 0 if ok else 1


def main(argv):
    exe = locate_cli()
    if exe is None:
        print("::error::CLI not built")
        return 1
    if os.name != "nt" and not os.access(exe, os.X_OK):
        exe.chmod(exe.stat().st_mode | 0o111)
    if "--self-test" in argv:
        print("check_g6 self-test (R4: verify the ruler first)")
        return self_test(exe)
    failures = []
    n = 0
    with tempfile.TemporaryDirectory() as td:
        for src in sorted(CORPUS.glob("*.fit")):
            n += 1
            if verify(exe, src) != 0:
                failures.append(f"{src.name}: pristine does not verify")
            data = bytearray(src.read_bytes())
            for pos in (0, 8, len(data) // 2, len(data) - 2, len(data) - 1):
                mut = bytearray(data)
                mut[pos] ^= 0xFF
                bad = Path(td) / "m.fit"
                bad.write_bytes(bytes(mut))
                if verify(exe, bad) == 0:
                    failures.append(f"{src.name}: mutation at byte {pos} not rejected")
    if failures:
        print("Gate G6 FAILED:")
        for f in failures:
            print(f"  - {f}")
        return 1
    print(f"Gate G6 OK: {n} files verify; header/data/CRC single-byte mutations all rejected.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
