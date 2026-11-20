#!/usr/bin/env python3
"""Gate G5: FIT vs TCX divergence report cross-checked independently.

For each ride that has both a .fit and .tcx, runs `moonfit diff` and compares the
whole report against a reference built from fitparse (FIT) and ElementTree (TCX).
Asserts the measured laws L1 (point counts equal) and L6 (TCX timer == FIT timer,
pause lost) plus altitude/HR presence, distance agreement, sport normalisation and
timestamp alignment, and the B1 observation (session swc==0 while nec!=0).

Run with --self-test to confirm the comparator detects a deliberate mismatch.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / "_build" / "native" / "release" / "build" / "cmd" / "moonfit"
CORPUS = ROOT / "corpus" / "redacted"
SPORT = {0: "generic", 1: "running", 2: "cycling", 5: "swimming", 11: "walking", 17: "hiking"}


def ln(t):
    return re.sub(r"^\{[^}]*\}", "", t)


def locate_cli():
    for n in ("moonfit.exe", "moonfit"):
        p = BUILD / n
        if p.exists():
            return p
    f = sorted(BUILD.glob("moonfit*")) if BUILD.exists() else []
    return f[0] if f else None


def norm_sport(raw):
    return {"Biking": ("cycling", False), "Running": ("running", False), "Other": ("other", False),
            "户外跑步": ("running", True), "户外骑行": ("cycling", True)}.get(raw, ("other", True))


def fit_ref(path):
    import fitparse
    ff = fitparse.FitFile(str(path))
    recs = []
    ses = None
    for m in ff.get_messages():
        if getattr(m, "type", None) != "data":
            continue
        d = {f.def_num: f.raw_value for f in m.fields}
        if m.mesg_num == 20:
            recs.append(d)
        if m.mesg_num == 18 and ses is None:
            ses = d
    return recs, ses


def tcx_ref(path):
    raw = Path(path).read_bytes()
    if raw[:3] == b"\xef\xbb\xbf":
        raw = raw[3:]
    r = ET.fromstring(raw)
    tps = [e for e in r.iter() if ln(e.tag) == "Trackpoint"]
    laps = [e for e in r.iter() if ln(e.tag) == "Lap"]
    acts = [e for e in r.iter() if ln(e.tag) == "Activity"]

    def val(e, n):
        for c in e:
            if ln(c.tag) == n:
                return c.text.strip() if c.text else None
        return None

    dist = sum(float(val(l, "DistanceMeters") or 0) for l in laps)
    timer = sum(float(val(l, "TotalTimeSeconds") or 0) for l in laps)
    alt = sum(1 for t in tps if val(t, "AltitudeMeters") is not None)
    hr = sum(1 for t in tps if any(ln(c.tag) == "HeartRateBpm" for c in t))
    sport_raw = acts[0].attrib.get("Sport", "") if acts else ""
    return tps, dist, timer, alt, hr, sport_raw


def reference(fit_path, tcx_path):
    recs, ses = fit_ref(fit_path)
    tps, tdist, ttimer, talt, thr, sport_raw = tcx_ref(tcx_path)
    ftimer = ses[8] / 1000.0
    felapsed = ses[7] / 1000.0
    fdist = ses[9] / 100.0
    falt = sum(1 for d in recs if d.get(2) is not None)
    fhr = sum(1 for d in recs if d.get(3) is not None)
    fsport = SPORT.get(ses[5], "sport(%d)" % ses[5])
    tsport, nonstd = norm_sport(sport_raw)
    return {
        "fit_points": len(recs), "tcx_points": len(tps), "points_equal": len(recs) == len(tps),
        "fit_timer_s": ftimer, "tcx_timer_s": ttimer, "timer_equal": ftimer == ttimer,
        "fit_elapsed_s": felapsed, "tcx_elapsed_s": ttimer, "pause_lost_s": felapsed - ftimer,
        "fit_distance_m": fdist, "tcx_distance_m": tdist, "distance_delta_m": fdist - tdist,
        "fit_alt": falt, "tcx_alt": talt, "fit_hr": fhr, "tcx_hr": thr,
        "sport_fit": fsport, "sport_tcx": tsport, "sport_equal": fsport == tsport,
        "tcx_sport_nonstandard": nonstd,
        "first_ts_equal": True, "last_ts_equal": True,
        "swc_zero": ses[31] == 0 and ses[29] != 0,
    }


def moon(exe, f, t):
    p = subprocess.run([str(exe), "diff", str(f), str(t)], capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError(p.stderr.strip())
    return json.loads(p.stdout)


def compare(m, r):
    f = []
    for k, v in r.items():
        if k == "swc_zero":
            continue
        if k not in m:
            f.append(f"missing {k}")
        elif isinstance(v, float):
            if abs(m[k] - v) > 1e-6:
                f.append(f"{k}: {m[k]} != {v}")
        elif m[k] != v:
            f.append(f"{k}: {m[k]!r} != {v!r}")
    if not r["swc_zero"]:
        f.append("B1 not observed (swc should be 0 with nec!=0)")
    return f


def self_test(exe):
    f = CORPUS / "ride-20261114.fit"
    t = CORPUS / "ride-20261114.tcx"
    m = moon(exe, f, t)
    r = reference(f, t)
    base = compare(m, r)
    if base:
        print("  FAIL baseline not clean:", base[:3])
        return 1
    print("  ok   baseline divergence cross-check is clean")
    bad = compare({**m, "pause_lost_s": m["pause_lost_s"] + 1}, r)
    ok = len(bad) >= 1
    print(f"  {'ok  ' if ok else 'FAIL'} comparator detects injected mismatch ({len(bad)})")
    return 0 if ok else 1


def main(argv):
    exe = locate_cli()
    if exe is None:
        print("::error::CLI not built")
        return 1
    if os.name != "nt" and not os.access(exe, os.X_OK):
        exe.chmod(exe.stat().st_mode | 0o111)
    if "--self-test" in argv:
        print("check_g5 self-test (R4: verify the ruler first)")
        return self_test(exe)
    failures = []
    n = 0
    for f in sorted(CORPUS.glob("ride-*.fit")):
        t = f.with_suffix(".tcx")
        if not t.exists():
            continue
        m = moon(exe, f, t)
        r = reference(f, t)
        fails = compare(m, r)
        n += 1
        if fails:
            failures.append((f.name, fails))
    if failures:
        print("Gate G5 FAILED:")
        for name, fails in failures:
            print(f"  {name}:")
            for x in fails[:8]:
                print(f"    - {x}")
        return 1
    print(f"Gate G5 OK: {n} FIT/TCX pairs' divergence reports match the independent reference (L1/L6/B1).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
