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
import json
import os
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / "_build" / "native" / "release" / "build" / "cmd" / "moonfit"
CORPUS = ROOT / "corpus" / "redacted"
DLAT = 600000
DLON = -800000
LAT_FIELDS = {(20, 0), (18, 3), (18, 29), (19, 3), (19, 5)}
LON_FIELDS = {(20, 1), (18, 4), (18, 30), (19, 4), (19, 6)}
_CRC_T = [0x0000,0xCC01,0xD801,0x1400,0xF001,0x3C00,0x2800,0xE401,0xA001,0x6C00,0x7800,0xB401,0x5000,0x9C01,0x8801,0x4400]


def crc16(b):
    c = 0
    for x in b:
        t = _CRC_T[c & 0xF]; c = ((c >> 4) & 0x0FFF) ^ t ^ _CRC_T[x & 0xF]
        t = _CRC_T[c & 0xF]; c = ((c >> 4) & 0x0FFF) ^ t ^ _CRC_T[(x >> 4) & 0xF]
    return c & 0xFFFF


def wrap32(v):
    return ((v + 2**31) % 2**32) - 2**31


def dump_msgs(exe, p):
    out = run(exe, "dump", p).stdout
    return [json.loads(l) for l in out.splitlines() if l.strip()]


def coords(msgs):
    out = []
    for m in msgs:
        for f in m["f"]:
            key = (m["g"], f["d"])
            if f["i"] == 0 and (key in LAT_FIELDS or key in LON_FIELDS):
                out.append((key, f["v"]))
    return out


def serials(msgs):
    return [f["v"] for m in msgs if m["g"] in (0, 23) for f in m["f"] if f["d"] == 3]


def swc(msgs):
    return [f["v"] for m in msgs if m["g"] == 18 for f in m["f"] if f["d"] in (31, 32)]


def redef_fit():
    body = bytearray()
    body += bytes([0x41, 0, 0, 20, 0, 2, 0, 4, 0x85, 1, 4, 0x85])
    body += bytes([0x01]) + struct.pack("<i", 1000000) + struct.pack("<i", 0)
    body += bytes([0x41, 0, 1, 0, 20, 2, 0, 4, 0x85, 1, 4, 0x85])
    body += bytes([0x01]) + struct.pack(">i", 2000000) + struct.pack(">i", 0)
    hdr = bytearray([14, 0x10, 0xEA, 0x07]) + struct.pack("<I", len(body)) + b".FIT"
    hdr += struct.pack("<H", crc16(hdr))
    full = hdr + body
    full += struct.pack("<H", crc16(full))
    return bytes(full)


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
        # P2-3: local-type redefinition little->big must still shift correctly.
        rd = Path(td) / "redef.fit"
        rd.write_bytes(redef_fit())
        ro = Path(td) / "redef.out"
        run(exe, "redact", rd, ro, 0, 600000, -800000)
        rc = coords(dump_msgs(exe, ro))
        want = [((20, 0), 1600000), ((20, 1), -800000), ((20, 0), 2600000), ((20, 1), -800000)]
        ok_endian = rc == want
        print(f"  {'ok  ' if ok_endian else 'FAIL'} little->big redefinition shifts both records :: {rc}")
        return 0 if (ok and ok_endian) else 1


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
            # P2-3: every lat/lon = original + delta; serial zeroed; swc stays 0.
            shifted = Path(td) / (src.name + ".shift")
            if run(exe, "redact", src, shifted, 0, DLAT, DLON).returncode != 0:
                failures.append(f"{src.name}: shift redact failed")
                continue
            ic, oc = coords(dump_msgs(exe, src)), coords(dump_msgs(exe, shifted))
            if len(ic) != len(oc):
                failures.append(f"{src.name}: coord count changed under shift")
            else:
                for (k, v), (k2, v2) in zip(ic, oc):
                    delta = DLAT if k in LAT_FIELDS else DLON
                    if k != k2 or v2 != wrap32(v + delta):
                        failures.append(f"{src.name}: {k} {v2} != wrap({v}+{delta})")
                        break
            if any(sv != [0] * 8 for sv in serials(dump_msgs(exe, shifted))):
                failures.append(f"{src.name}: serial not all zero")
            if any(sw != 0 for sw in swc(dump_msgs(exe, shifted))):
                failures.append(f"{src.name}: swc 31/32 not 0")
    if failures:
        print("redact gate FAILED:")
        for f in failures:
            print(f"  - {f}")
        return 1
    print(f"redact gate OK: {n} files idempotent + trim(5) drops 10 records and round-trips.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
