# Changelog

All notable changes to this module are recorded here. The format follows
Keep a Changelog, and the version numbers follow semantic versioning.

## 0.1.0

### Added

- `src/units`: opaque `Int64` newtypes for every FIT wire scalar observed in
  the corpus — `Semicircle`, `FitTimestamp`, `UnixSecond`, `Centimetre`,
  `Decimetre`, `AltitudeRaw`, `MillimetrePerSecond`, `Millisecond`,
  `CentiPercent`, and the marker units `Bpm`, `Rpm`, `Watt` and `Celsius`.
  Fields are private, so a value can only be built or read through the
  package's own functions.
- Conversions from each native unit to its `Double` form, plus the inverse for
  altitude. The inverse returns `None` for a decimetre value with no exact
  representation rather than truncating.
- ISO-8601 UTC rendering of a FIT timestamp, covering the whole uint32 range,
  leap days, the pre-epoch floor-division branch and the unrepresentable-year
  branch.
- `src/fit`: the FIT container layer. Protocol CRC-16 with the measured coverage
  rules (file CRC spans `[0, len-2)` including the header-CRC bytes; header CRC
  spans `[0, 12)`), file-header parsing for both 12-byte and 14-byte headers with
  signature / size / header-CRC validation, and all sixteen base types with
  endian-aware readers and writers plus per-type invalid-value detection.
  Signed narrow integers are sign-extended from their own width, and the
  invalid conventions (signed max-positive, unsigned all-ones, `z` types zero,
  string leading-zero) are compared on the decoded bit pattern so they are
  endian-correct.
- `src/fit` record-stream walker: definition messages (endian from the
  architecture byte), normal and compressed-timestamp data messages, local-type
  redefinition, and exact consumption of the data section. Array / opaque
  fields are carried as raw bytes; scalar fields are decoded and invalid-flagged.
- Exhaustive base-type round-trip and invalid-detection tests (206 generated
  cases) bringing the suite to 257 tests across four backends; Gate G8 asserts
  every definition field of every corpus message is emitted with an explicit
  disposition (140 distinct fields). Coverage report added (docs/coverage.md).
- `fit::verify` total validity check and Gate G6: typed errors for malformed
  inputs plus an exhaustive single-byte mutation sweep (every byte of the embedded
  corpus flipped) rejected on all four backends; a CI gate repeats header/data/CRC
  mutations across all six files. `moonfit verify` and `moonfit info` added.
- `src/diff`: FIT vs TCX divergence report (point counts L1, timer equality L6,
  pause lost, distance delta, altitude/HR presence, sport normalisation, timestamp
  alignment, bounding-box defect B1 as swc_zero/ne_swc_contradiction). `moonfit diff`; Gate G5 cross-checks all 6 pairs independently and
  asserts B1 (session swc==0 with nec!=0).
- `src/redact`: native FIT redaction (zero device serial, exact semicircle coordinate
  shift, optional leading/trailing record trim) re-encoded with recomputed CRCs.
  Verified to reproduce the committed redacted corpus byte-for-byte from the raw
  exports (6/6, local); CI gate checks idempotence and that trim(5) drops exactly
  10 records and still round-trips. `moonfit redact`.
- `src/tcx`: TCX decoding into the canonical model using the Milky2018/xml pull
  parser. Tolerates UTF-8 BOM and namespace prefixes; handles the rich iGPSPORT
  and minimal Huawei variants; normalises non-standard Sport values (e.g.
  "户外跑步") and flags them. Maps Lap/TotalTimeSeconds to timer_s per law L6.
  `moonfit tcx` emits a JSON summary; a CI gate cross-checks all 14 corpus .tcx
  against an independent ElementTree parse.
- `src/model`: canonical activity model (TrackPoint/Lap/Activity) extracting FIT
  fields into native units with invalid-as-None and fixed (global, def_num)
  provenance. `src/metrics`: device + GPS (haversine) distance, three-way time,
  pace, per-km splits from device distance, trailing-window computed ascent, and
  caller-defined heart-rate zone durations. `moonfit metrics` emits JSON; Gate G4
  cross-checks against geographiclib Karney plus identical ascent/zone/split
  algorithms.
- `src/fit/encode.mbt`: structure-preserving re-encoding. Header and definitions
  are rebuilt from the parsed structure; data fields replay their original bytes
  in definition order; CRCs recomputed. Gate G2 asserts decode->encode is
  byte-identical (SHA-256) for all six corpus files, embedded on every backend
  and via `moonfit roundtrip` in CI.
- Element-wise decoding of array fields into `BaseValue::Array`, and an absolute
  `timestamp` on every data message reconstructed from compressed 5-bit offsets
  (with 0x20 roll-over). G3 now compares array fields element-wise as well.
- `moonfit dump <file>` emitting JSONL of raw field values, and Gate G3: a
  differential comparison of every scalar field of every corpus data message
  against fitparse (3313 messages), excluding fitparse's synthesised enhanced_*
  fields and array fields.
- `cmd/moonfit` with `version` and `units` subcommands, built on
  `moonbitlang/core/argparse`. Exit 0 on success, exit 2 on a usage error,
  diagnostics on stderr.
- `corpus/redacted`: fourteen real activities redacted for publication, with
  `SHA256SUMS` and a provenance record.
- CI gates: corpus byte integrity, unit conversion constants, scope contract,
  documentation discipline, and a CLI contract smoke test. Each Python gate
  carries a `--self-test` mode that is run before the gate itself.
- `docs/boundaries.md`, `docs/testing.md` and `docs/spec-notes.md`.
