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
