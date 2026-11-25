#!/usr/bin/env python3
"""Gate G7-TCX (D7): TCX decode cross-checked against an independent XML parse.

Runs `moonfit tcx` over every redacted corpus .tcx and compares point/lap counts,
lap distance and timer totals, heart-rate summaries, sport normalisation and the
first/last FIT-epoch timestamps, and every trackpoint's lat/lon/alt/speed/HR,
against a separate ElementTree walk. This proves
the MoonBit pull-parser extraction agrees with a conventional DOM parse on both
vendor variants, including the non-standard Huawei Sport value and BOM.

Run with --self-test to confirm the comparator detects a deliberate mismatch.
"""
from __future__ import annotations

import calendar
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
SOURCE = ROOT / "cmd" / "moonfit" / "dump.mbt"
FIT_EPOCH = 631065600


def ln(t):
    return re.sub(r"^\{[^}]*\}", "", t)


def locate_cli():
    for name in ("moonfit.exe", "moonfit"):
        p = BUILD / name
        if p.exists():
            return p
    found = sorted(BUILD.glob("moonfit*")) if BUILD.exists() else []
    return found[0] if found else None


def iso_fit(s):
    s = s.strip()
    m = re.match(r"(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})", s)
    if not m:
        return 0
    y, mo, d, h, mi, se = map(int, m.groups())
    import datetime
    unix = calendar.timegm(datetime.datetime(y, mo, d, h, mi, se).timetuple())
    return unix - FIT_EPOCH


def reference(path):
    raw = Path(path).read_bytes()
    if raw[:3] == b"\xef\xbb\xbf":
        raw = raw[3:]
    r = ET.fromstring(raw)
    acts = [e for e in r.iter() if ln(e.tag) == "Activity"]
    laps = [e for e in r.iter() if ln(e.tag) == "Lap"]
    tps = [e for e in r.iter() if ln(e.tag) == "Trackpoint"]

    def child(e, name):
        for c in e:
            if ln(c.tag) == name:
                return c
        return None

    def val(e, name):
        c = child(e, name)
        return c.text.strip() if c is not None and c.text else None

    dist = sum(float(val(l, "DistanceMeters") or 0) for l in laps)
    timer = sum(float(val(l, "TotalTimeSeconds") or 0) for l in laps)
    sport_raw = acts[0].attrib.get("Sport", "") if acts else ""
    avg = maxhr = None
    if laps:
        a = child(laps[0], "AverageHeartRateBpm")
        m = child(laps[0], "MaximumHeartRateBpm")
        avg = int(val(a, "Value")) if a is not None and val(a, "Value") else None
        maxhr = int(val(m, "Value")) if m is not None and val(m, "Value") else None
    times = [val(t, "Time") for t in tps if val(t, "Time")]

    def find_text(tp, name):
        for e in tp.iter():
            if ln(e.tag) == name:
                return e.text.strip() if e.text else None
        return None

    def hr_of(tp):
        for e in tp.iter():
            if ln(e.tag) == "HeartRateBpm":
                for c in e:
                    if ln(c.tag) == "Value":
                        return int(c.text.strip()) if c.text else None
        return None

    def fnum(x):
        return float(x) if x is not None else None

    points = []
    for tp in tps:
        t = val(tp, "Time")
        points.append({
            "ts": iso_fit(t) if t else 0,
            "lat": fnum(find_text(tp, "LatitudeDegrees")),
            "lon": fnum(find_text(tp, "LongitudeDegrees")),
            "alt": fnum(find_text(tp, "AltitudeMeters")),
            "speed": fnum(find_text(tp, "Speed")),
            "hr": hr_of(tp),
        })
    return {
        "n_points": len(tps),
        "n_laps": len(laps),
        "device_distance_m": dist,
        "timer_s": timer,
        "avg_hr": avg,
        "max_hr": maxhr,
        "sport_raw": sport_raw,
        "sport_nonstandard": sport_raw not in ("Biking", "Running", "Other"),
        "first_ts": iso_fit(times[0]) if times else 0,
        "last_ts": iso_fit(times[-1]) if times else 0,
        "points": points,
    }


def serialization_shape():
    """Reject the old quadratic point-string accumulation pattern."""
    source = SOURCE.read_text(encoding="utf-8")
    return (
        "let point_jsons : Array[String] = []" in source
        and "let pj = point_jsons.join(\",\")" in source
        and "pj = pj +" not in source
    )


def moon(exe, path):
    p = subprocess.run([str(exe), "tcx", str(path)], capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError(f"tcx failed: {p.stderr.strip()}")
    return json.loads(p.stdout)


def compare(m, r):
    f = []
    for k in ("n_points", "n_laps", "first_ts", "last_ts", "sport_raw", "sport_nonstandard", "avg_hr", "max_hr"):
        if m[k] != r[k]:
            f.append(f"{k}: {m[k]!r} != {r[k]!r}")
    for k in ("device_distance_m", "timer_s"):
        if abs(m[k] - r[k]) > 1e-6:
            f.append(f"{k}: {m[k]} != {r[k]}")
    mp, rp = m.get("points", []), r["points"]
    if len(mp) != len(rp):
        f.append(f"points len {len(mp)} != {len(rp)}")
    else:
        for i, (a, b) in enumerate(zip(mp, rp)):
            if a["ts"] != b["ts"]:
                f.append(f"point {i} ts {a['ts']} != {b['ts']}")
            if a["hr"] != b["hr"]:
                f.append(f"point {i} hr {a['hr']} != {b['hr']}")
            for k in ("lat", "lon", "alt", "speed"):
                av, bv = a[k], b[k]
                if (av is None) != (bv is None):
                    f.append(f"point {i} {k} presence {av} != {bv}")
                elif av is not None and abs(av - bv) > 1e-6:
                    f.append(f"point {i} {k} {av} != {bv}")
    return f


def self_test(exe):
    path = CORPUS / "ride-20261114.tcx"
    m = moon(exe, path)
    r = reference(path)
    base = compare(m, r)
    if base:
        print("  FAIL baseline not clean:", base[:3])
        return 1
    print("  ok   baseline TCX cross-check is clean")
    bad = compare({**m, "n_points": m["n_points"] + 1}, r)
    ok = len(bad) >= 1
    print(f"  {'ok  ' if ok else 'FAIL'} comparator detects injected mismatch ({len(bad)})")
    shape_ok = serialization_shape()
    print(f"  {'ok  ' if shape_ok else 'FAIL'} TCX point serialization uses linear join")
    return 0 if ok and shape_ok else 1


def main(argv):
    exe = locate_cli()
    if exe is None:
        print("::error::CLI not built")
        return 1
    if os.name != "nt" and not os.access(exe, os.X_OK):
        exe.chmod(exe.stat().st_mode | 0o111)
    if "--self-test" in argv:
        print("check_tcx self-test (R4: verify the ruler first)")
        return self_test(exe)
    failures = []
    if not serialization_shape():
        print("TCX gate FAILED: point serialization must collect then join")
        return 1
    n = 0
    for path in sorted(CORPUS.glob("*.tcx")):
        m = moon(exe, path)
        r = reference(path)
        fails = compare(m, r)
        n += 1
        if fails:
            failures.append((path.name, fails))
    if failures:
        print("TCX gate FAILED:")
        for name, fails in failures:
            print(f"  {name}:")
            for x in fails[:8]:
                print(f"    - {x}")
        return 1
    print(f"TCX gate OK: {n} corpus .tcx files match an independent XML parse.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
