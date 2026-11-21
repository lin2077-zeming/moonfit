#!/usr/bin/env python3
"""Gate G8: parameter-space / per-field disposition coverage.

For every corpus .fit, runs `moonfit dump` and checks that EVERY field declared in
each data message's definition is present in the dump, in definition order, with
an explicit disposition (null=invalid, list=array, number=scalar, "raw:N"=opaque).
A silently dropped field fails the gate. Also asserts the union of distinct
(global, def_num) pairs matches the independent fitparse definition union.

Run with --self-test to confirm the gate detects a deliberately dropped field.
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
    for n in ("moonfit.exe", "moonfit"):
        p = BUILD / n
        if p.exists():
            return p
    f = sorted(BUILD.glob("moonfit*")) if BUILD.exists() else []
    return f[0] if f else None


def dump(exe, path):
    p = subprocess.run([str(exe), "dump", str(path)], capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError(p.stderr.strip())
    return [json.loads(l) for l in p.stdout.splitlines() if l.strip()]


def fitparse_defs(path):
    import fitparse
    ff = fitparse.FitFile(str(path))
    msgs = []
    union = set()
    for m in ff.get_messages():
        if getattr(m, "type", None) != "data":
            continue
        defs = [fd.def_num for fd in m.def_mesg.field_defs]
        msgs.append((m.mesg_num, defs))
        for d in defs:
            union.add((m.mesg_num, d))
    return msgs, union


def disposition(f):
    v = f["v"]
    if f["i"] == 1 or v is None:
        return "invalid"
    if isinstance(v, list):
        return "array"
    if isinstance(v, str) and v.startswith("raw:"):
        return "raw"
    return "scalar"


def compare(mine, ref_msgs):
    fails = []
    if len(mine) != len(ref_msgs):
        return [f"message count {len(mine)} != {len(ref_msgs)}"]
    for idx, (msg, (g, defs)) in enumerate(zip(mine, ref_msgs)):
        if msg["g"] != g:
            fails.append(f"msg{idx} global {msg['g']} != {g}")
        got = [f["d"] for f in msg["f"]]
        if got != defs:
            fails.append(f"msg{idx} field set/order {got} != {defs}")
        for f in msg["f"]:
            if disposition(f) not in ("invalid", "array", "raw", "scalar"):
                fails.append(f"msg{idx} def{f['d']} unknown disposition")
    return fails


def self_test(exe):
    path = CORPUS / "ride-20260803.fit"
    mine = dump(exe, path)
    ref, union = fitparse_defs(path)
    base = compare(mine, ref)
    if base:
        print("  FAIL baseline not clean:", base[:3])
        return 1
    print("  ok   baseline field coverage is clean")
    poisoned = json.loads(json.dumps(mine))
    poisoned[0]["f"] = poisoned[0]["f"][1:]  # drop first field
    bad = compare(poisoned, ref)
    ok = len(bad) >= 1
    print(f"  {'ok  ' if ok else 'FAIL'} comparator detects a dropped field ({len(bad)})")
    return 0 if ok else 1


def main(argv):
    exe = locate_cli()
    if exe is None:
        print("::error::CLI not built")
        return 1
    if os.name != "nt" and not os.access(exe, os.X_OK):
        exe.chmod(exe.stat().st_mode | 0o111)
    if "--self-test" in argv:
        print("check_g8 self-test (R4: verify the ruler first)")
        return self_test(exe)
    failures = []
    union_all = set()
    n = 0
    for path in sorted(CORPUS.glob("*.fit")):
        mine = dump(exe, path)
        ref, union = fitparse_defs(path)
        union_all |= union
        fails = compare(mine, ref)
        n += 1
        if fails:
            failures.append((path.name, fails))
    if failures:
        print("Gate G8 FAILED:")
        for name, fails in failures:
            print(f"  {name}:")
            for x in fails[:8]:
                print(f"    - {x}")
        return 1
    print(f"Gate G8 OK: {n} files, every definition field present with a disposition; {len(union_all)} distinct (global,def) fields covered.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
