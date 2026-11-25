#!/usr/bin/env python3
"""Gate G-fidelity for the profile-based, spec-derived capability report."""
from __future__ import annotations

import json
import math
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / "_build" / "native" / "release" / "build" / "cmd" / "moonfit"
CORPUS = ROOT / "corpus" / "redacted"
TARGETS = ("tcx", "gpx", "kml")
PROFILES = ("portable-core", "standard-extended", "loss-minimal")
REQUIRED = {
    "tcx": {"auto_pause", "elapsed", "timer", "device_serial", "coord_precision", "enhanced_altitude"},
    "gpx": {"auto_pause", "elapsed", "timer", "device_serial", "coord_precision", "enhanced_altitude", "heart_rate", "distance"},
    "kml": {"auto_pause", "elapsed", "timer", "device_serial", "coord_precision", "enhanced_altitude", "heart_rate", "distance"},
}
STATUSES = {"exact", "rounded", "extension_preserved", "omitted", "unsupported"}
VENDOR = {"point_halving", "point_count", "subsample"}
EARTH_METRE_PER_DEGREE = 111319.49079327357


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
    for m in ff.get_messages():
        if getattr(m, "type", None) == "data" and m.mesg_num == 18:
            fields = {f.def_num: f.raw_value for f in m.fields}
            return max(0.0, fields[7] / 1000.0 - fields[8] / 1000.0)
    raise RuntimeError(f"no session message in {path}")


def moon_fidelity(exe, path, target, profile):
    p = subprocess.run(
        [str(exe), "fidelity", str(path), "--target", target, "--profile", profile],
        capture_output=True, text=True,
    )
    if p.returncode != 0:
        raise RuntimeError(p.stderr.strip())
    return json.loads(p.stdout)


def expected_status(target, profile, semantic):
    if semantic == "coord_precision":
        return "extension_preserved" if profile == "loss-minimal" else "rounded"
    if semantic == "enhanced_altitude" and target in {"tcx", "gpx", "kml"}:
        return "exact"
    if target == "kml" and semantic in {
        "auto_pause", "elapsed", "timer", "heart_rate", "cadence", "power",
        "speed", "distance", "temperature",
    }:
        return "omitted" if profile == "portable-core" else "extension_preserved"
    if target == "gpx" and semantic == "distance":
        return "omitted" if profile == "portable-core" else "extension_preserved"
    if target == "tcx" and semantic in {"speed", "power", "temperature"}:
        return "omitted" if profile == "portable-core" else "extension_preserved"
    return None


def compare(m, ref_pause, target, profile):
    failures = []
    if m.get("target") != target:
        failures.append(f"target {m.get('target')} != {target}")
    if m.get("profile") != profile:
        failures.append(f"profile {m.get('profile')} != {profile}")
    if m.get("analysis_only") is not True:
        failures.append("analysis_only is not true")
    if m.get("writer_available") is not False:
        failures.append("writer_available is not false")
    if abs(m.get("pause_lost_s", -1.0) - ref_pause) > 1e-6:
        failures.append(f"pause_lost_s {m.get('pause_lost_s')} != {ref_pause}")

    expected_digits = {"portable-core": 7, "standard-extended": 9, "loss-minimal": 0}[profile]
    expected_angle = {"portable-core": 0.5e-7, "standard-extended": 0.5e-9, "loss-minimal": 0.0}[profile]
    if m.get("coordinate_digits") != expected_digits:
        failures.append(f"coordinate_digits {m.get('coordinate_digits')} != {expected_digits}")
    if abs(m.get("max_angle_error_deg", -1.0) - expected_angle) > 1e-15:
        failures.append(f"max_angle_error_deg {m.get('max_angle_error_deg')} != {expected_angle}")
    equator = expected_angle * EARTH_METRE_PER_DEGREE
    if abs(m.get("max_equator_error_m", -1.0) - equator) > 1e-9:
        failures.append(f"max_equator_error_m {m.get('max_equator_error_m')} != {equator}")
    latitude = float(m.get("latitude_deg", 0.0))
    longitude = equator * math.cos(math.radians(latitude))
    if abs(m.get("max_longitude_error_m", -1.0) - longitude) > 1e-9:
        failures.append(f"max_longitude_error_m {m.get('max_longitude_error_m')} != {longitude}")

    losses = m.get("losses", [])
    semantics = {l.get("semantic") for l in losses}
    for semantic in sorted(REQUIRED[target] - semantics):
        failures.append(f"missing required semantic: {semantic}")
    for bad in sorted(VENDOR & semantics):
        failures.append(f"vendor behaviour claimed as format loss: {bad}")
    for loss in losses:
        if loss.get("status") not in STATUSES:
            failures.append(f"loss {loss.get('semantic')} has invalid status {loss.get('status')}")
        if not loss.get("source_unit") or not loss.get("representation") or not loss.get("policy"):
            failures.append(f"loss {loss.get('semantic')} lacks a complete policy description")
        if not loss.get("spec"):
            failures.append(f"loss {loss.get('semantic')} lacks a spec citation")
        if not isinstance(loss.get("reversible"), bool):
            failures.append(f"loss {loss.get('semantic')} has no boolean reversible flag")
        if not isinstance(loss.get("max_error"), (int, float)) or loss.get("max_error") < 0:
            failures.append(f"loss {loss.get('semantic')} has invalid max_error")
        expected = expected_status(target, profile, loss.get("semantic"))
        if expected is not None and loss.get("status") != expected:
            failures.append(
                f"{target}/{profile}/{loss.get('semantic')} status {loss.get('status')} != {expected}"
            )
    coord = next((l for l in losses if l.get("semantic") == "coord_precision"), None)
    if coord is None:
        failures.append("coord_precision loss is missing")
    elif profile == "loss-minimal":
        if coord.get("status") != "extension_preserved" or coord.get("reversible") is not True:
            failures.append("loss-minimal coordinates are not reversible extension_preserved")
    elif coord.get("status") != "rounded" or coord.get("reversible") is not False:
        failures.append(f"{profile} coordinates do not report rounded/reversible=false")
    return failures


def self_test(exe):
    path = CORPUS / "ride-20260925.fit"
    ref = reference_pause(path)
    m = moon_fidelity(exe, path, "tcx", "portable-core")
    base = compare(m, ref, "tcx", "portable-core")
    if base:
        print("  FAIL baseline not clean:", base[:3])
        return 1
    print("  ok   baseline profile cross-check is clean")
    bad = compare({**m, "max_angle_error_deg": m["max_angle_error_deg"] + 1}, ref, "tcx", "portable-core")
    ok = len(bad) >= 1
    print(f"  {'ok  ' if ok else 'FAIL'} comparator detects injected coordinate mismatch ({len(bad)})")
    dropped = {**m, "losses": [l for l in m["losses"] if l["semantic"] != "auto_pause"]}
    ok2 = len(compare(dropped, ref, "tcx", "portable-core")) >= 1
    print(f"  {'ok  ' if ok2 else 'FAIL'} comparator detects a dropped required semantic ({len(compare(dropped, ref, 'tcx', 'portable-core'))})")
    return 0 if ok and ok2 else 1


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
            for profile in PROFILES:
                m = moon_fidelity(exe, path, target, profile)
                fails = compare(m, ref, target, profile)
                n += 1
                if fails:
                    failures.append((path.name, target, profile, fails))
    if failures:
        print("fidelity gate FAILED:")
        for name, target, profile, fails in failures:
            print(f"  {name} [{target}/{profile}]:")
            for failure in fails[:8]:
                print(f"    - {failure}")
        return 1
    print(f"fidelity gate OK: {n} file/target/profile budgets match independent checks.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
