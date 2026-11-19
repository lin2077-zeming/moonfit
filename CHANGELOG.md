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
- `cmd/moonfit` with `version` and `units` subcommands, built on
  `moonbitlang/core/argparse`. Exit 0 on success, exit 2 on a usage error,
  diagnostics on stderr.
- `corpus/redacted`: fourteen real activities redacted for publication, with
  `SHA256SUMS` and a provenance record.
- CI gates: corpus byte integrity, unit conversion constants, scope contract,
  documentation discipline, and a CLI contract smoke test. Each Python gate
  carries a `--self-test` mode that is run before the gate itself.
- `docs/boundaries.md`, `docs/testing.md` and `docs/spec-notes.md`.
