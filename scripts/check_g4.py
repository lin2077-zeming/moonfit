#!/usr/bin/env python3
"""Gate G4: derived metrics cross-checked against an independent computation.

Device-reported totals (distance, elapsed/timer/moving, ascent/descent) must
match the session fields exactly. The GPS-derived distance uses spherical
haversine in MoonBit and Karney geodesics (geographiclib) here, so it is compared
with a documented sphere-vs-ellipsoid relative tolerance. Computed ascent
(same trailing moving-average window), heart-rate zone seconds and per-km splits
(same device-distance method) are compared tightly.

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
BOUNDS = [100, 120, 140, 160]
WINDOW = 5
GPS_REL_TOL = 0.005  # sphere (haversine) vs WGS84 ellipsoid (Karney)


def locate_cli():
    for name in ("moonfit.exe", "moonfit"):
        p = BUILD / name
        if p.exists():
            return p
    found = sorted(BUILD.glob("moonfit*")) if BUILD.exists() else []
    return found[0] if found else None


def moon_metrics(exe, path):
    proc = subprocess.run(
        [str(exe), "metrics", str(path), ",".join(map(str, BOUNDS)), str(WINDOW)],
        capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"metrics failed: {proc.stderr.strip()}")
    return json.loads(proc.stdout)


def reference(path):
    import fitparse
    from geographiclib.geodesic import Geodesic
    ff = fitparse.FitFile(str(path))
    pts = []
    ses = None
    for m in ff.get_messages():
        if getattr(m, "type", None) != "data":
            continue
        if m.mesg_num == 18 and ses is None:
            ses = {f.def_num: f.raw_value for f in m.fields}
        if m.mesg_num == 20:
            d = {f.def_num: f.raw_value for f in m.fields}
            lat = d.get(0)
            lon = d.get(1)
            alt = d.get(2)
            pts.append({
                "ts": d.get(253),
                "lat": lat * 180.0 / 2**31 if lat is not None else None,
                "lon": lon * 180.0 / 2**31 if lon is not None else None,
                "alt": (alt * 2 - 5000) / 10.0 if alt is not None else None,
                "dist": d.get(5) / 100.0 if d.get(5) is not None else None,
                "hr": d.get(3),
            })
    gps = 0.0
    for a, b in zip(pts, pts[1:]):
        if None not in (a["lat"], a["lon"], b["lat"], b["lon"]):
            gps += Geodesic.WGS84.Inverse(a["lat"], a["lon"], b["lat"], b["lon"])["s12"]
    alts = [p["alt"] for p in pts if p["alt"] is not None]
    smooth = []
    for i in range(len(alts)):
        start = max(0, i - WINDOW + 1)
        smooth.append(sum(alts[start:i + 1]) / (i - start + 1))
    ascent = sum(max(0.0, smooth[i] - smooth[i - 1]) for i in range(1, len(smooth)))
    secs = [0] * (len(BOUNDS) + 1)
    for a, b in zip(pts, pts[1:]):
        if a["hr"] is not None and b["ts"] - a["ts"] > 0:
            idx = sum(1 for x in BOUNDS if a["hr"] >= x)
            secs[idx] += b["ts"] - a["ts"]
    splits = []
    last_km = 0
    last_ts = ses[2]
    for p in pts:
        if p["dist"] is not None:
            km = int(p["dist"] // 1000)
            if km > last_km:
                for k in range(last_km + 1, km + 1):
                    splits.append({"index": k, "end_distance_m": k * 1000.0, "time_s": p["ts"] - last_ts})
                last_ts = p["ts"]
                last_km = km
    timer = ses[8] / 1000.0
    return {
        "device_distance_m": ses[9] / 100.0,
        "elapsed_s": ses[7] / 1000.0,
        "timer_s": timer,
        "moving_s": ses[59] / 1000.0,
        "device_ascent_m": float(ses[22]),
        "device_descent_m": float(ses[23]),
        "gps_distance_m": gps,
        "avg_speed_mps": gps / timer if timer else 0.0,
        "computed_ascent_m": ascent,
        "hr_seconds": secs,
        "splits": splits,
    }


def compare(mine, ref):
    f = []
    for k in ("device_distance_m", "elapsed_s", "timer_s", "moving_s", "device_ascent_m", "device_descent_m"):
        if abs(mine[k] - ref[k]) > 1e-6:
            f.append(f"{k}: {mine[k]} != {ref[k]}")
    if abs(mine["gps_distance_m"] - ref["gps_distance_m"]) > GPS_REL_TOL * ref["gps_distance_m"]:
        f.append(f"gps_distance_m: {mine['gps_distance_m']} vs {ref['gps_distance_m']}")
    if abs(mine["avg_speed_mps"] - ref["avg_speed_mps"]) > GPS_REL_TOL * max(1.0, ref["avg_speed_mps"]):
        f.append(f"avg_speed_mps: {mine['avg_speed_mps']} vs {ref['avg_speed_mps']}")
    if abs(mine["computed_ascent_m"] - ref["computed_ascent_m"]) > 1e-6:
        f.append(f"computed_ascent_m: {mine['computed_ascent_m']} != {ref['computed_ascent_m']}")
    mz = [z["seconds"] for z in mine["hr_zones"]]
    if mz != ref["hr_seconds"]:
        f.append(f"hr_zones: {mz} != {ref['hr_seconds']}")
    if len(mine["splits"]) != len(ref["splits"]):
        f.append(f"split count {len(mine['splits'])} != {len(ref['splits'])}")
    else:
        for a, b in zip(mine["splits"], ref["splits"]):
            if a["index"] != b["index"] or abs(a["end_distance_m"] - b["end_distance_m"]) > 1e-6 or a["time_s"] != b["time_s"]:
                f.append(f"split {a} != {b}")
    return f


def self_test(exe):
    path = CORPUS / "ride-20261114.fit"
    mine = moon_metrics(exe, path)
    ref = reference(path)
    base = compare(mine, ref)
    if base:
        print("  FAIL baseline not clean:", base[:3])
        return 1
    print("  ok   baseline metrics cross-check is clean")
    poisoned = json.loads(json.dumps(mine))
    poisoned["device_distance_m"] += 1.0
    bad = compare(poisoned, ref)
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
        print("check_g4 self-test (R4: verify the ruler first)")
        return self_test(exe)
    failures = []
    n = 0
    for path in sorted(CORPUS.glob("*.fit")):
        mine = moon_metrics(exe, path)
        ref = reference(path)
        fails = compare(mine, ref)
        n += 1
        if fails:
            failures.append((path.name, fails))
    if failures:
        print("Gate G4 FAILED:")
        for name, fails in failures:
            print(f"  {name}:")
            for x in fails[:8]:
                print(f"    - {x}")
        return 1
    print(f"Gate G4 OK: {n} files' metrics match the independent reference.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
