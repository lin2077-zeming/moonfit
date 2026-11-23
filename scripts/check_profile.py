#!/usr/bin/env python3
"""Gate profile: the complete-support endpoint under a pinned FIT standard.

Pins FIT protocol 1.0 / profile 20.74 (scripts/profile_20_74_fields.json, derived
from the corpus) and verifies the declared complete-support endpoint:
  * every corpus .fit declares the pinned protocol and profile;
  * the eight activity message types (file_id, session, lap, record, event,
    device_info, activity, file_creator) are all decoded;
  * the union of decoded (global, def_num) fields equals the pinned 140-field set
    (no silent drop, no undeclared field).

Base-type coverage (all 16) is asserted by src/fit/basetype_exhaustive_test.mbt;
field-level disposition is Gate G8. This gate pins the STANDARD VERSION and the
message/field endpoint so "complete support" has a verifiable boundary.

Run with --self-test to confirm the gate detects a deliberate mismatch.
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
REF = ROOT / "scripts" / "profile_20_74_fields.json"


def locate_cli():
    for n in ("moonfit.exe", "moonfit"):
        p = BUILD / n
        if p.exists():
            return p
    f = sorted(BUILD.glob("moonfit*")) if BUILD.exists() else []
    return f[0] if f else None


def run(exe, *args):
    return subprocess.run([str(exe), *map(str, args)], capture_output=True, text=True)


def collect(exe):
    protocols, profiles, globals_seen, fields = set(), set(), set(), set()
    for p in sorted(CORPUS.glob("*.fit")):
        info = json.loads(run(exe, "info", p).stdout)
        protocols.add(info["protocol"])
        profiles.add(info["profile"])
        for l in run(exe, "dump", p).stdout.splitlines():
            if not l.strip():
                continue
            m = json.loads(l)
            globals_seen.add(m["g"])
            for f in m["f"]:
                fields.add((m["g"], f["d"]))
    return protocols, profiles, globals_seen, fields


def check(exe, ref):
    fails = []
    protocols, profiles, globals_seen, fields = collect(exe)
    if sorted(protocols) != ref["protocol"]:
        fails.append(f"protocol {sorted(protocols)} != pinned {ref['protocol']}")
    if sorted(profiles) != ref["profile"]:
        fails.append(f"profile {sorted(profiles)} != pinned {ref['profile']}")
    if sorted(globals_seen) != ref["activity_messages"]:
        fails.append(f"activity messages {sorted(globals_seen)} != pinned {ref['activity_messages']}")
    pinned = {tuple(x) for x in ref["fields"]}
    if fields != pinned:
        missing = sorted(pinned - fields)
        extra = sorted(fields - pinned)
        if missing:
            fails.append(f"missing pinned fields: {missing[:6]}")
        if extra:
            fails.append(f"undeclared fields decoded: {extra[:6]}")
    return fails


def self_test(exe):
    ref = json.loads(REF.read_text(encoding="utf-8"))
    base = check(exe, ref)
    if base:
        print("  FAIL baseline not clean:", base[:3])
        return 1
    print("  ok   baseline profile endpoint is clean")
    bad = check(exe, {**ref, "profile": [9999]})
    ok = any("profile" in b for b in bad)
    print(f"  {'ok  ' if ok else 'FAIL'} gate detects a wrong pinned profile")
    bad2 = check(exe, {**ref, "fields": ref["fields"][:-1]})
    ok2 = any("fields" in b for b in bad2)
    print(f"  {'ok  ' if ok2 else 'FAIL'} gate detects a dropped pinned field")
    return 0 if (ok and ok2) else 1


def main(argv):
    exe = locate_cli()
    if exe is None:
        print("::error::CLI not built")
        return 1
    if os.name != "nt" and not os.access(exe, os.X_OK):
        exe.chmod(exe.stat().st_mode | 0o111)
    if "--self-test" in argv:
        print("check_profile self-test (R4: verify the ruler first)")
        return self_test(exe)
    ref = json.loads(REF.read_text(encoding="utf-8"))
    fails = check(exe, ref)
    if fails:
        print("profile endpoint gate FAILED:")
        for f in fails:
            print(f"  - {f}")
        return 1
    print(f"profile endpoint gate OK: protocol {ref['protocol']} / profile {ref['profile']}, "
          f"{len(ref['activity_messages'])} activity messages, {len(ref['fields'])} fields.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
