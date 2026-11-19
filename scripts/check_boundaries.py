#!/usr/bin/env python3
"""Scope contract check.

`docs/boundaries.md` is the single in-repo statement of what this release does
and does not do. The competition proposal carries a copy of the Delivered
table, so the two cannot drift without this gate noticing.

The gate enforces:
  * every Delivered row names an evidence file that exists in the repository;
  * every row has a non-empty capability name;
  * no capability is repeated within a table, or claimed in both tables;
  * every Known limitations row states a reason;
  * neither table is empty.

Run with --self-test to check the parser against embedded fixtures before
trusting a green run.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BOUNDARIES = ROOT / "docs" / "boundaries.md"

DELIVERED_HEADING = "delivered"
LIMITS_HEADING = "known limitations"
HEADER_FIRST_CELLS = {"capability", "not delivered"}


def is_separator(cells: list[str]) -> bool:
    return all(c and set(c) <= set("-: ") for c in cells)


def parse_tables(text: str):
    section = None
    delivered: list[tuple[str, str]] = []
    limits: list[tuple[str, str]] = []
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith("#"):
            heading = line.lstrip("#").strip().lower()
            if heading == DELIVERED_HEADING:
                section = "delivered"
            elif heading == LIMITS_HEADING:
                section = "limits"
            else:
                section = None
            continue
        if section is None or not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) < 2 or is_separator(cells):
            continue
        if cells[0].lower() in HEADER_FIRST_CELLS:
            continue
        if section == "delivered":
            delivered.append((cells[0], cells[1]))
        else:
            limits.append((cells[0], cells[1]))
    return delivered, limits


def clean(path_cell: str) -> str:
    return path_cell.strip().strip("`").strip()


def check(text: str, exists) -> list[str]:
    failures: list[str] = []
    delivered, limits = parse_tables(text)

    if not delivered:
        failures.append("the Delivered table is empty")
    if not limits:
        failures.append("the Known limitations table is empty")

    for table_name, rows in (("Delivered", delivered), ("Known limitations", limits)):
        seen: set[str] = set()
        for capability, second in rows:
            if not capability:
                failures.append(f"{table_name} row has an empty capability name")
                continue
            key = capability.strip().lower()
            if key in seen:
                failures.append(f"{table_name} repeats a capability: {capability[:60]}")
            seen.add(key)
            if table_name == "Delivered":
                path = clean(second)
                if not path:
                    failures.append(f"delivered row has no evidence: {capability[:60]}")
                elif not exists(path):
                    failures.append(
                        f"evidence file missing for '{capability[:60]}': {path}"
                    )
            elif not second.strip():
                failures.append(f"limitation has no reason: {capability[:60]}")

    delivered_keys = {c.strip().lower() for c, _ in delivered if c}
    for capability, _ in limits:
        if capability and capability.strip().lower() in delivered_keys:
            failures.append(f"capability appears in both tables: {capability[:60]}")

    return failures


FIXTURE_OK = """
# Declared scope

## Delivered

| Capability | Evidence |
|---|---|
| Unit layer | `src/units/units_test.mbt` |

## Known limitations

| Not delivered | Reason |
|---|---|
| TCX decoding | Depends on the model layer |
"""

FIXTURE_BAD = """
# Declared scope

## Delivered

| Capability | Evidence |
|---|---|
| Unit layer | `src/does_not_exist.mbt` |
| Unit layer | `src/units/units_test.mbt` |
|  | `src/units/units_test.mbt` |
| No evidence row |  |

## Known limitations

| Not delivered | Reason |
|---|---|
| Blank reason |  |
| Unit layer | duplicated claim |
"""


def self_test() -> int:
    fake_exists = lambda p: p == "src/units/units_test.mbt"
    good = check(FIXTURE_OK, fake_exists)
    bad = check(FIXTURE_BAD, fake_exists)
    expected_kinds = 6
    ok = not good and len(bad) >= expected_kinds
    print(f"  {'ok  ' if not good else 'FAIL'} well-formed fixture reports nothing (got {len(good)})")
    print(f"  {'ok  ' if len(bad) >= expected_kinds else 'FAIL'} broken fixture reports {len(bad)} problems (expected >= {expected_kinds})")
    for item in bad:
        print(f"        - {item}")
    return 0 if ok else 1


def main(argv: list[str]) -> int:
    if "--self-test" in argv:
        print("check_boundaries self-test (R4: verify the ruler first)")
        return self_test()
    if not BOUNDARIES.exists():
        print(f"::error file={BOUNDARIES}::docs/boundaries.md is missing")
        return 1
    text = BOUNDARIES.read_text(encoding="utf-8")
    failures = check(text, lambda p: (ROOT / p).exists())
    if failures:
        print("scope contract gate FAILED:")
        for item in failures:
            print(f"  - {item}")
        return 1
    delivered, limits = parse_tables(text)
    print(f"scope contract gate OK: {len(delivered)} delivered, {len(limits)} declared limitations.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
