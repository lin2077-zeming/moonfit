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
| FIT protocol CRC-16 with the measured coverage rules, checked against the standard ARC check value and every corpus checksum | `src/fit/fit_test.mbt` |
| FIT file header parsing (12 B and 14 B), with signature, size-consistency and header-CRC validation | `src/fit/fit_test.mbt` |
| All sixteen base types: wire codes, element sizes, endian-aware read/write and per-type invalid-value detection | `src/fit/fit_test.mbt` |
| FIT record-stream walker: definition, normal-data and compressed-timestamp messages, with local-type redefinition and exact stream consumption | `src/fit/fit_test.mbt` |
| `moonfit dump` JSONL of raw field values, and the G3 differential gate comparing every scalar field of every corpus message against fitparse | `scripts/check_g3.py` |
| Element-wise decoding of array fields (serial_number, time_in_*_zone) into `BaseValue::Array`, compared element-wise by G3 | `src/fit/fit_test.mbt` |
| Absolute timestamp on every data message, reconstructed from compressed 5-bit offsets with 0x20 roll-over | `src/fit/fit_test.mbt` |
| Structure-preserving re-encoding (`encode_fit`) and Gate G2: decode->encode reproduces every corpus file byte-for-byte (SHA-256), on all four backends and via the native CLI | `src/fit/fit_test.mbt` |
| Canonical activity model with invalid-as-None extraction and fixed (global, def_num) provenance | `src/model/model.mbt` |
| Derived metrics (device + GPS distance, three-way time, pace, per-km splits, smoothing-window ascent, caller-defined HR zones) and Gate G4 vs an independent Karney reference | `scripts/check_g4.py` |
| TCX decoding into the same canonical model (BOM + namespace tolerance, iGPSPORT/Huawei variants, non-standard Sport normalisation), cross-checked on all 14 corpus .tcx against an independent XML parse | `scripts/check_tcx.py` |
| FIT vs TCX divergence report encoding laws L1/L6 and defect B1 as checkable facts, cross-checked on all 6 pairs against an independent reference (Gate G5) | `scripts/check_g5.py` |
| Native FIT redaction (zero serial, exact semicircle coordinate shift, optional record trim, optional `--strip-hr`, machine-readable `--report`) that reproduces the committed corpus byte-for-byte from raw exports and is idempotent + structure-preserving | `scripts/check_redact.py` |
| Robustness: typed errors for truncation / bad signature / bad header size / header-CRC / missing definition / unknown base type / overlong field, and a full single-byte mutation sweep rejected on all four backends (Gate G6) | `src/fit/fit_test.mbt` |
| `moonfit verify` (total validity) and `moonfit info` (header + counts) | `scripts/check_g6.py` |
| Exhaustive base-type round-trip (16 types x both endiannesses x representative values) and per-type invalid detection | `src/fit/basetype_exhaustive_test.mbt` |
| Gate G8: every definition field of every corpus message present in the dump with an explicit disposition (140 distinct fields), silent drop fails CI | `scripts/check_g8.py` |
| Coverage report distinguishing unit-suite coverage from corpus-gate coverage | `docs/coverage.md` |
| Corpus redaction tooling that zeroes the device serial, shifts coordinates by an exact semicircle offset and recomputes the CRC, with a self-test proving no other byte changes | `scripts/redact_corpus.py` |
| Fourteen redacted real activities with a provenance manifest and checksums | `corpus/redacted/manifest.csv` |
| Corpus provenance and CC0 dedication, with the redaction offset and the list of fields deliberately left unmodified | `corpus/README.md` |

## Known limitations

Deliberately out of scope for this release. Nothing here is promised for a
later date, and none of it is required by any claim made above.

| Not delivered | Reason |
|---|---|
| Developer-field element semantics | Developer data is carried as a raw blob so the stream advances exactly; normal array fields are decoded, but developer-defined element semantics are out of scope |
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
