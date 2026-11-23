#!/usr/bin/env python3
"""Gate fidelity: the spec-derived format loss budget is cross-checked.

Runs `moonfit fidelity` over every corpus .fit for each target (tcx/gpx/kml) and
verifies, against an independent fitparse read of the session, that:
  * pause_lost_s equals max(0, elapsed - timer);
  * the format-inherent losses required by each format's schema are present;
  * every loss cites a non-empty format specification and a valid kind;
  * vendor export behaviour (point subsampling / point count) is NOT claimed as a
    format limitation.

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
TARGETS = ("tcx", "gpx", "kml")
REQUIRED = {
    "tcx": {"auto_pause", "device_serial", "coord_precision", "enhanced_altitude"},
    "gpx": {"auto_pause", "device_serial", "coord_precision", "heart_rate", "distance"},
    "kml": {"auto_pause", "device_serial", "coord_precision", "heart_rate", "distance"},
}
KINDS = {"unrepresentable", "degraded", "extension_required"}
VENDOR = {"point_halving", "point_count", "subsample"}


def locate_cli():
    for n in ("moonfit.exe", "moonfit"):
        p = BUILD / n
        if p.exists():
            return p
    f = sorted(BUILD.glob("moonfit*")) if BUILD.exists() else []
    return f[0] if f else None


def reference_pause(path):
    import fitparse
    ff = fitparse.FitFile(str(path))
    ses = None
    for m in ff.get_messages():
        if getattr(m, "type", None) == "data" and m.mesg_num == 18 and ses is None:
            ses = {f.def_num: f.raw_value for f in m.fields}
    return max(0.0, ses[7] / 1000.0 - ses[8] / 1000.0)


def moon_fidelity(exe, path, target):
    p = subprocess.run([str(exe), "fidelity", str(path), "--target", target],
                       capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError(p.stderr.strip())
    return json.loads(p.stdout)


def compare(m, ref_pause, target):
    f = []
    if m.get("target") != target:
        f.append(f"target {m.get('target')} != {target}")
    if abs(m.get("pause_lost_s", -1) - ref_pause) > 1e-6:
        f.append(f"pause_lost_s {m.get('pause_lost_s')} != {ref_pause}")
    sems = {l["semantic"] for l in m.get("losses", [])}
    for req in sorted(REQUIRED[target]):
        if req not in sems:
            f.append(f"missing format-inherent loss: {req}")
    for bad in sorted(VENDOR & sems):
        f.append(f"vendor behaviour claimed as format loss: {bad}")
    for l in m.get("losses", []):
        if not l.get("spec"):
            f.append(f"loss {l.get('semantic')} lacks a spec citation")
        if l.get("kind") not in KINDS:
            f.append(f"loss {l.get('semantic')} has invalid kind {l.get('kind')}")
    return f


def self_test(exe):
    path = CORPUS / "ride-20260925.fit"
    ref = reference_pause(path)
    m = moon_fidelity(exe, path, "tcx")
    base = compare(m, ref, "tcx")
    if base:
        print("  FAIL baseline not clean:", base[:3])
        return 1
    print("  ok   baseline fidelity cross-check is clean")
    bad = compare({**m, "pause_lost_s": m["pause_lost_s"] + 1}, ref, "tcx")
    ok = len(bad) >= 1
    print(f"  {'ok  ' if ok else 'FAIL'} comparator detects injected pause mismatch ({len(bad)})")
    dropped = {**m, "losses": [l for l in m["losses"] if l["semantic"] != "auto_pause"]}
    ok2 = len(compare(dropped, ref, "tcx")) >= 1
    print(f"  {'ok  ' if ok2 else 'FAIL'} comparator detects a dropped required loss")
    return 0 if (ok and ok2) else 1


def main(argv):
    exe = locate_cli()
    if exe is None:
        print("::error::CLI not built")
        return 1
    if os.name != "nt" and not os.access(exe, os.X_OK):
        exe.chmod(exe.stat().st_mode | 0o111)
    if "--self-test" in argv:
        print("check_fidelity self-test (R4: verify the ruler first)")
        return self_test(exe)
    failures = []
    n = 0
    for path in sorted(CORPUS.glob("*.fit")):
        ref = reference_pause(path)
        for target in TARGETS:
            m = moon_fidelity(exe, path, target)
            fails = compare(m, ref, target)
            n += 1
            if fails:
                failures.append((path.name, target, fails))
    if failures:
        print("fidelity gate FAILED:")
        for name, target, fails in failures:
            print(f"  {name} [{target}]:")
            for x in fails[:8]:
                print(f"    - {x}")
        return 1
    print(f"fidelity gate OK: {n} file/target loss budgets match the independent reference.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
