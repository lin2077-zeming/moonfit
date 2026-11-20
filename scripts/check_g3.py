#!/usr/bin/env python3
"""Gate G3: differential decode against an independent decoder (fitparse).

Runs the native `moonfit dump` over every redacted corpus file and compares the
raw field values, message by message, against fitparse. Only scalar fields that
are actually present in the definition message are compared: fitparse
synthesises enhanced_speed / enhanced_altitude from speed / altitude even when
those fields are absent, and array fields (serial_number, time_in_*_zone) are
carried as raw bytes by this module, so both are excluded. Where fitparse
reports an invalid field as None, this module must report invalid=1.

Run with --self-test to confirm the comparator detects a deliberate mismatch.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
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


def dump_messages(exe, path):
    proc = subprocess.run([str(exe), "dump", str(path)], capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"dump failed for {path}: {proc.stderr.strip()}")
    return [json.loads(line) for line in proc.stdout.splitlines() if line.strip()]


def fitparse_messages(path):
    import fitparse
    ff = fitparse.FitFile(str(path))
    out = []
    for m in ff.get_messages():
        if getattr(m, "type", None) != "data":
            continue
        defset = {f.def_num for f in m.def_mesg.field_defs}
        fields = {}
        for f in m.fields:
            if f.def_num not in defset:
                continue  # synthesised (enhanced_*)
            raw = f.raw_value
            if isinstance(raw, (tuple, list)):
                continue  # array field, carried raw by moonfit
            fields[f.def_num] = raw
        out.append((m.mesg_num, fields))
    return out


def compare(mine, theirs):
    failures = []
    if len(mine) != len(theirs):
        return [f"message count {len(mine)} != {len(theirs)}"]
    for idx, (msg, (global_num, fields)) in enumerate(zip(mine, theirs)):
        if msg["g"] != global_num:
            failures.append(f"msg{idx}: global {msg['g']} != {global_num}")
        mine_fields = {f["d"]: f for f in msg["f"]}
        for def_num, raw in fields.items():
            mf = mine_fields.get(def_num)
            if mf is None:
                failures.append(f"msg{idx} def{def_num}: missing in moonfit")
                continue
            if raw is None:
                if mf["i"] != 1 or mf["v"] is not None:
                    failures.append(f"msg{idx} def{def_num}: expected invalid, got {mf}")
            else:
                if mf["i"] != 0:
                    failures.append(f"msg{idx} def{def_num}: unexpected invalid")
                elif isinstance(raw, float):
                    if abs(float(mf["v"]) - raw) > 1e-6:
                        failures.append(f"msg{idx} def{def_num}: {mf['v']} != {raw}")
                elif mf["v"] != raw:
                    failures.append(f"msg{idx} def{def_num}: {mf['v']!r} != {raw!r}")
    return failures


def self_test(exe):
    path = CORPUS / "ride-20260803.fit"
    mine = dump_messages(exe, path)
    theirs = fitparse_messages(path)
    base = compare(mine, theirs)
    if base:
        print("  FAIL baseline not clean:", base[:3])
        return 1
    print("  ok   baseline differential comparison is clean")
    poisoned = json.loads(json.dumps(mine))
    for f in poisoned[0]["f"]:
        if f["i"] == 0 and isinstance(f["v"], int):
            f["v"] = f["v"] + 1
            break
    bad = compare(poisoned, theirs)
    ok = len(bad) >= 1
    print(f"  {'ok  ' if ok else 'FAIL'} comparator detects an injected mismatch ({len(bad)})")
    return 0 if ok else 1


def main(argv):
    exe = locate_cli()
    if exe is None:
        print("::error::CLI not built; run moon build cmd/moonfit --target native --release")
        return 1
    if os.name != "nt" and not os.access(exe, os.X_OK):
        exe.chmod(exe.stat().st_mode | 0o111)
    if "--self-test" in argv:
        print("check_g3 self-test (R4: verify the ruler first)")
        return self_test(exe)
    total = 0
    failures = []
    for path in sorted(CORPUS.glob("*.fit")):
        mine = dump_messages(exe, path)
        theirs = fitparse_messages(path)
        fails = compare(mine, theirs)
        total += len(mine)
        if fails:
            failures.append((path.name, fails))
    if failures:
        print("Gate G3 FAILED:")
        for name, fails in failures:
            print(f"  {name}:")
            for f in fails[:10]:
                print(f"    - {f}")
        return 1
    print(f"Gate G3 OK: {total} data messages across {len(list(CORPUS.glob('*.fit')))} files match fitparse.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
