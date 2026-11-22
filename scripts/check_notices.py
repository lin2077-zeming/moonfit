#!/usr/bin/env python3
"""Runtime-dependency attribution gate.

Every dependency declared in the `import { ... }` block of `moon.mod` is linked
into anything built from this module, so each one must be attributed in
`THIRD_PARTY_NOTICES.md`. An unattributed runtime dependency is the licence-side
version of the scope drift that sank the previous project in this series. This
gate fails if a declared dependency is missing from the notices.

Run with --self-test to verify the parser against embedded fixtures first.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def mod_deps(mod_text: str) -> list[str]:
    m = re.search(r"import\s*\{([^}]*)\}", mod_text, re.S)
    if not m:
        return []
    return [e.split("@")[0].strip() for e in re.findall(r'"([^"]+)"', m.group(1))]


def check(mod_text: str, notices_text: str) -> list[str]:
    failures = []
    for name in mod_deps(mod_text):
        if name and name not in notices_text:
            failures.append(
                f"runtime dependency '{name}' declared in moon.mod is missing "
                f"from THIRD_PARTY_NOTICES.md"
            )
    return failures


FIXTURE_MOD = """
name = "x/y"
import {
  "a/b@1.0.0",
  "c/d@2.3.4",
}
"""
FIXTURE_NOTICES_OK = "| `a/b` | Apache-2.0 | use |\n| `c/d` | MIT | use |\n"
FIXTURE_NOTICES_BAD = "| `a/b` | Apache-2.0 | use |\n"


def self_test() -> int:
    deps = mod_deps(FIXTURE_MOD)
    deps_ok = deps == ["a/b", "c/d"]
    print(f"  {'ok  ' if deps_ok else 'FAIL'} parses import block deps :: {deps}")
    good = check(FIXTURE_MOD, FIXTURE_NOTICES_OK)
    bad = check(FIXTURE_MOD, FIXTURE_NOTICES_BAD)
    good_ok = not good
    bad_ok = len(bad) == 1 and "c/d" in bad[0]
    print(f"  {'ok  ' if good_ok else 'FAIL'} complete notices report nothing :: {good}")
    print(f"  {'ok  ' if bad_ok else 'FAIL'} missing dependency flagged :: {bad}")
    return 0 if (deps_ok and good_ok and bad_ok) else 1


def main(argv: list[str]) -> int:
    if "--self-test" in argv:
        print("check_notices self-test (R4: verify the ruler first)")
        return self_test()
    mod = ROOT / "moon.mod"
    notices = ROOT / "THIRD_PARTY_NOTICES.md"
    if not mod.exists() or not notices.exists():
        print("::error::moon.mod or THIRD_PARTY_NOTICES.md is missing")
        return 1
    mod_text = mod.read_text(encoding="utf-8")
    failures = check(mod_text, notices.read_text(encoding="utf-8"))
    if failures:
        print("runtime-dependency attribution gate FAILED:")
        for f in failures:
            print(f"  - {f}")
        return 1
    deps = mod_deps(mod_text)
    print(f"runtime-dependency attribution gate OK: {len(deps)} declared deps attributed ({', '.join(deps)}).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
