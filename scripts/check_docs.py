#!/usr/bin/env python3
"""R3 / FM5 enforcement: docs may not promise what is not delivered, and may
not make quality claims that no test can substantiate.

The previous project in this series was rejected partly because a planning
document inside the repository promised log-spectrum and band-filtering
features that were never delivered. Reviewers treat every document in the
repository as part of the declared scope, so this gate keeps the repository
free of promissory language and of unmeasurable quality adjectives.

Measured statements are fine and encouraged ("GPX carries ceil(n/2) of the FIT
records"). Self-congratulation is not ("high-precision", "production-grade",
"full support", "lossless", "accuracy").

Run with --self-test to verify the detector against embedded examples before
trusting a green run.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Promissory language: describes work that does not exist yet.
PROMISSORY = [
    "roadmap", "backlog", "后续计划", "未来将", "将会支持", "计划支持", "即将",
    "planned", "upcoming", "will be supported", "will support", "to be implemented",
    "not yet implemented", "尚未实现", "待实现", "敬请期待", "coming soon",
    "work in progress", "wip",
]

# Quality claims no test in this repository can substantiate.
UNMEASURABLE = [
    "高精度", "精确到", "精度极高", "完整支持", "生产级", "业界", "全球领先",
    "high-precision", "high precision", "production-grade", "production grade",
    "pixel-perfect", "state-of-the-art", "full support", "fully support",
    "lossless", "bit-perfect", "accuracy", "准确率", "召回率",
]

# Leftover markers that should never ship.
MARKERS = ["TODO", "FIXME", "XXX", "HACK"]

DOC_GLOBS = ["README.mbt.md", "docs/*.md", "CHANGELOG.md", "corpus/*.md"]
SOURCE_GLOBS = ["src/**/*.mbt", "cmd/**/*.mbt"]

# A doc line inside one of these sections is describing a limitation, which is
# honest rather than promissory, so promissory matches there are allowed.
LIMITATION_HEADINGS = ("known limitations", "out of scope", "已知限制", "明确不做")


def scan(paths: list[Path], needles: list[str], allow_limitation_section: bool):
    hits = []
    for path in paths:
        if not path.exists():
            continue
        in_limitation = False
        for lineno, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            stripped = raw.strip()
            if stripped.startswith("#"):
                in_limitation = stripped.lstrip("#").strip().lower() in LIMITATION_HEADINGS
            if allow_limitation_section and in_limitation:
                continue
            lowered = raw.lower()
            for needle in needles:
                if needle.lower() in lowered:
                    hits.append((path, lineno, needle, stripped[:110]))
    return hits


def docs() -> list[Path]:
    out: list[Path] = []
    for pattern in DOC_GLOBS:
        out.extend(sorted(ROOT.glob(pattern)))
    return out


def sources() -> list[Path]:
    out: list[Path] = []
    for pattern in SOURCE_GLOBS:
        out.extend(sorted(ROOT.glob(pattern)))
    return out


def self_test() -> int:
    samples = [
        ("# Roadmap\n", PROMISSORY, True),
        ("GPX carries ceil(n/2) of the FIT records.\n", PROMISSORY, False),
        ("This is a high-precision parser.\n", UNMEASURABLE, True),
        ("One semicircle is 8.381903171539307e-8 degrees.\n", UNMEASURABLE, False),
        ("// TODO: handle developer fields\n", MARKERS, True),
        ("// Developer fields are passed through untouched.\n", MARKERS, False),
    ]
    failures = 0
    for text, needles, should_hit in samples:
        hit = any(n.lower() in text.lower() for n in needles)
        status = "ok " if hit == should_hit else "FAIL"
        if hit != should_hit:
            failures += 1
        print(f"  {status} expected_hit={should_hit} got={hit} :: {text.strip()[:60]}")

    # The limitation-section exemption must actually exempt.
    exempt = "## Known limitations\n\nDeveloper fields are not yet implemented.\n"
    tmp = ROOT / "scripts" / ".selftest_doc.md"
    tmp.write_text(exempt, encoding="utf-8")
    try:
        hits = scan([tmp], PROMISSORY, allow_limitation_section=True)
    finally:
        tmp.unlink()
    ok = not hits
    print(f"  {'ok ' if ok else 'FAIL'} limitation section exempts promissory match :: hits={len(hits)}")
    if not ok:
        failures += 1
    return 1 if failures else 0


def main(argv: list[str]) -> int:
    if "--self-test" in argv:
        print("check_docs self-test (R4: verify the ruler first)")
        return self_test()

    failures = []
    failures += scan(docs(), PROMISSORY, allow_limitation_section=True)
    failures += scan(docs(), UNMEASURABLE, allow_limitation_section=True)
    failures += scan(docs(), MARKERS, allow_limitation_section=False)
    failures += scan(sources(), MARKERS, allow_limitation_section=False)

    if failures:
        print("docs discipline gate FAILED:")
        for path, lineno, needle, line in failures:
            rel = path.relative_to(ROOT).as_posix()
            print(f"  {rel}:{lineno}: matched {needle!r} :: {line}")
        print()
        print("Move genuine limitations under a '## Known limitations' heading,")
        print("and delete promissory or unmeasurable wording elsewhere.")
        return 1

    print(f"docs discipline gate OK: {len(docs())} docs, {len(sources())} sources scanned.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
