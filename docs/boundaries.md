# Declared scope

This file is the scope contract for the current release. `scripts/check_boundaries.py`
runs in CI and fails if a capability is listed as delivered without an evidence
file that exists, if a capability appears in both tables, or if a limitation is
listed without a reason.

The declared scope in the competition proposal is a copy of the *Delivered*
table below. Keeping the two identical is what stops a document inside this
repository from promising more than the code does.

## Delivered

| Capability | Evidence |
|---|---|
| Native-unit type layer: semicircle, FIT timestamp, centimetre, decimetre altitude, millimetre per second, millisecond, centi-percent, and the marker units bpm / rpm / watt / celsius | `src/units/units_test.mbt` |
| ISO-8601 UTC rendering of a FIT timestamp, covering both ends of the uint32 range, leap day, the pre-epoch branch and the unrepresentable-year branch | `src/units/units_test.mbt` |
| CLI dispatch for `version` and `units` with exit code 0 on success and 2 on usage error | `scripts/smoke_cli.py` |
| Corpus byte-integrity gate proving the committed `.fit` files are still the bytes the redactor wrote | `scripts/check_corpus_integrity.py` |
| Runnable example decoding the first record of a corpus file into degrees, an ISO-8601 timestamp, metres, m/s and seconds | `examples/wire_units/main.mbt` |
| Corpus redaction tooling that zeroes the device serial, shifts coordinates by an exact semicircle offset and recomputes the CRC, with a self-test proving no other byte changes | `scripts/redact_corpus.py` |
| Fourteen redacted real activities with a provenance manifest and checksums | `corpus/redacted/manifest.csv` |
| Corpus provenance and CC0 dedication, with the redaction offset and the list of fields deliberately left unmodified | `corpus/README.md` |

## Known limitations

Deliberately out of scope for this release. Nothing here is promised for a
later date, and none of it is required by any claim made above.

| Not delivered | Reason |
|---|---|
| FIT message decoding beyond the unit layer | Requires message decoding; the corpus profile is recorded in `docs/spec-notes.md` |
| FIT encoding and the byte-exact round-trip assertion | Depends on message decoding |
| TCX decoding | Depends on the canonical activity model |
| FIT to TCX divergence report | Depends on TCX decoding |
| Developer field semantics | Absent from the corpus: 0 occurrences across 6 files and 3120 records |
| `length`, `hrv`, `course*`, `workout*`, `segments` messages | Absent from the corpus: 0 occurrences |
| Power, cadence, left/right balance, torque effectiveness, pedal smoothness | Present as fields but 100 percent invalid in the corpus, so there is nothing to interpret |
| GPX and KML parsing | Delegated to `2973181701/moongpx` and `cp15695540483/moonkml` |
| Reordering or recompressing definition messages when encoding | Only structure-preserving replay is intended, which is what makes a byte-exact result reachable |
| Writing TCX, GPX or KML | Out of scope for this release |
| Live device communication over ANT+, BLE or USB | Out of scope for this release |
| Scoring, recommendation, prediction, anomaly detection or training advice | Excluded on principle: such a claim could not be substantiated by a test in this repository |
