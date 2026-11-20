#!/usr/bin/env python3
"""CLI contract smoke test.

Asserts the properties a caller can actually depend on: exit codes, which
stream diagnostics go to, and that the version the CLI reports is the version
the module declares. That last one exists because a previous release in this
series shipped source at 0.1.5 while the registry still carried 0.1.4, so the
artifact a reviewer installed was not the artifact that was reviewed.

Run with --self-test to confirm the harness itself detects a wrong expectation.
"""
from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUILD_DIR = ROOT / "_build" / "native" / "release" / "build" / "cmd" / "moonfit"
CORPUS = ROOT / "corpus" / "redacted"


def locate_cli() -> Path | None:
    """Find the built CLI.

    MoonBit's native backend names the artifact `moonfit.exe` on every host,
    including Linux, so the extension cannot be inferred from os.name. Try both
    spellings and fall back to a glob so a toolchain rename does not silently
    turn this gate into a no-op.
    """
    for name in ("moonfit.exe", "moonfit"):
        candidate = BUILD_DIR / name
        if candidate.exists():
            return candidate
    found = sorted(BUILD_DIR.glob("moonfit*")) if BUILD_DIR.exists() else []
    return found[0] if found else None


EXE = locate_cli()


def module_version() -> str:
    text = (ROOT / "moon.mod").read_text(encoding="utf-8")
    match = re.search(r'^version\s*=\s*"([^"]+)"', text, re.MULTILINE)
    if not match:
        raise SystemExit("could not read version from moon.mod")
    return match.group(1)


def run(args: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(
        [str(EXE), *args], capture_output=True, text=True, timeout=60,
    )


def cases(version: str):
    """Each case: (args, expected exit, stdout predicate, stderr predicate)."""
    return [
        ([], 2, lambda o: o == "", lambda e: "no command given" in e and "Usage:" in e),
        (["version"], 0, lambda o, v=version: o.strip() == v, lambda e: e == ""),
        (["--version"], 0, lambda o, v=version: o.strip() == v, lambda e: e == ""),
        (["units"], 0, lambda o: "semicircles" in o and "631065600" in o, lambda e: e == ""),
        (["bogus"], 2, lambda o: o == "", lambda e: "unexpected value" in e or "unknown" in e),
        (["--help"], 0, lambda o: "Usage:" in o and "units" in o, lambda e: e == ""),
        (["help"], 0, lambda o: "Usage:" in o, lambda e: e == ""),
        (["version", "extra"], 2, lambda o: True, lambda e: e != ""),
        (["dump", str(CORPUS / "ride-20260803.fit")], 0, lambda o: '"g":20' in o, lambda e: e == ""),
        (["dump"], 2, lambda o: o == "", lambda e: "needs a file" in e),
        (["roundtrip"], 2, lambda o: o == "", lambda e: "needs" in e),
        (["metrics"], 2, lambda o: o == "", lambda e: "needs a file" in e),
        (["tcx"], 2, lambda o: o == "", lambda e: "needs a file" in e),
    ]


def evaluate(version: str, expect_override: dict | None = None) -> list[str]:
    failures: list[str] = []
    for args, expected_code, out_ok, err_ok in cases(version):
        if expect_override and tuple(args) in expect_override:
            expected_code = expect_override[tuple(args)]
        proc = run(args)
        label = " ".join(args) if args else "<no args>"
        if proc.returncode != expected_code:
            failures.append(
                f"[{label}] exit {proc.returncode}, expected {expected_code}"
            )
            continue
        if not out_ok(proc.stdout):
            failures.append(f"[{label}] stdout did not satisfy its contract: {proc.stdout[:120]!r}")
        if not err_ok(proc.stderr):
            failures.append(f"[{label}] stderr did not satisfy its contract: {proc.stderr[:120]!r}")
    return failures


def self_test() -> int:
    version = module_version()
    baseline = evaluate(version)
    if baseline:
        print("  FAIL baseline run is not clean, cannot self-test:")
        for item in baseline:
            print(f"        - {item}")
        return 1
    print("  ok   baseline contract run is clean")

    # The harness must notice a wrong expectation. Ask it to expect exit 0 for
    # an unknown command; that has to be reported as a failure.
    poisoned = evaluate(version, expect_override={( "bogus",): 0})
    ok = any("bogus" in item for item in poisoned)
    print(f"  {'ok  ' if ok else 'FAIL'} harness detects a wrong expectation ({len(poisoned)} reported)")
    for item in poisoned:
        print(f"        - {item}")
    return 0 if ok else 1


def main(argv: list[str]) -> int:
    if EXE is None:
        print(
            f"::error file={BUILD_DIR}::CLI not built. "
            "Run: moon build cmd/moonfit --target native --release"
        )
        return 1
    if os.name != "nt" and not os.access(EXE, os.X_OK):
        EXE.chmod(EXE.stat().st_mode | 0o111)
    if "--self-test" in argv:
        print("smoke_cli self-test (R4: verify the ruler first)")
        return self_test()
    version = module_version()
    failures = evaluate(version)
    if failures:
        print("CLI contract smoke test FAILED:")
        for item in failures:
            print(f"  - {item}")
        return 1
    print(
        f"CLI contract smoke test OK: {len(cases(version))} cases, "
        f"version {version}, binary {EXE.name}."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
