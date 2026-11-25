# Changelog

All notable changes to this module are recorded here. The format follows
Keep a Changelog, and the version numbers follow semantic versioning.

## 0.5.0 - 2026-11-25


### Changed

- `moonfit fidelity` now takes `portable-core`, `standard-extended` or
  `loss-minimal` and reports the selected policy, coordinate digit count, angle
  and metre bounds, semantic status, specification reference and reversibility.
  The JSON report carries `analysis_only=true` while TCX, GPX and KML writers
  remain outside the release boundary.
- The fidelity documentation separates FIT semicircle unit conversion from
  decimal rounding and separates format capability from vendor export
  observations.
- TCX point JSON is collected and joined once. The TCX gate checks the linear
  serialization shape as well as every emitted point.

### Fixed

- `redact` rejects input/output/report path collisions, unknown options, extra
  positional arguments and invalid signed 32-bit coordinate offsets before
  writing any output.
- TCX rejects invalid calendar timestamps and XML documents without exactly one
  activity and at least one lap. Missing per-lap distance falls back to the
  per-lap trackpoint distance delta.
- JSON real values use the shared finite-number serializer. Metrics split
  interpolation resets on non-monotonic segments, handles distance plateaus and
  records large-jump truncation. SWC coordinate handling distinguishes the
  corpus zero sentinel from non-zero values, and trimming rewrites retained
  compressed timestamps when their reference record is removed.

## 0.4.0

### Added

- `moonfit fidelity <fit> --target tcx|gpx|kml`: a profile-based capability
  report. Each target format can be evaluated with `portable-core`,
  `standard-extended` or `loss-minimal`, and each entry carries a status, policy,
  specification reference, coordinate bound and reversibility flag. Vendor export
  behaviour is excluded and the report is marked analysis-only.
- `check_fidelity` gate (independent fitparse cross-check, rejects vendor-behaviour
  claims) and `check_profile` gate (pins FIT protocol 1.0 / profile 20.74 and the
  8-activity-message / 140-field complete-support endpoint against a checked-in
  reference). Both self-test and run in CI.

### Changed

- `diff` is documented as a retrospective observed-divergence comparison of two
  specific exports, not a predictive conversion-loss model.
- `docs/spec-notes.md` separates vendor export observations (L1-L6 / B1-B11) from
  format-inherent limitations (spec-derived); `docs/boundaries.md` states the
  complete-support endpoint under the pinned standard version.

## 0.3.0

### Added

- `moonfit tcx` emits a per-point `points` array (ts/lat/lon/alt/dist/speed/hr/cad)
  alongside the summary, so callers and the TCX gate can inspect every trackpoint.
- `check_json` and `check_corpus_integrity` gain `--self-test` modes (strict-JSON
  ruler rejects NaN/Infinity; sha256 known-vector and flipped-byte detection), so
  every CI gate self-tests.

### Changed

- Gate G4/G5 oracles are computed independently: G5 derives first/last timestamp
  equality from fitparse and stdlib datetime (no hardcoded True); G4 ascent uses a
  prefix-sum moving average and HR zones use bisect bucketing.
- The TCX gate compares every trackpoint's lat/lon/alt/speed/HR/ts against the
  independent XML parse; the redact gate verifies every lat/lon equals
  wrap(original + delta), serials are zeroed, session swc stays 0, and a
  little-to-big local-type redefinition shifts correctly.
- CI runs each gate's `--self-test` before the gate itself; the coverage step is
  labelled informational (not a gate).
- `docs/testing.md` describes live references and self-tests rather than
  checked-in golden snapshots; `docs/metrics.md` states pause-subtracted splits
  are out of scope for this release.

## 0.2.0

### Added

- `redact --strip-hr` invalidates heart-rate fields (record/session/lap) and
  `--report <path>` writes a machine-readable JSON list of what changed
  (serial_zeroed, lat_shifted, lon_shifted, hr_stripped, trimmed_records,
  fields_changed, lat_delta, lon_delta). `redact_ex` returns the report alongside
  the bytes; head/tail trim remains an optional, tested capability.
- `diff` reports the bounding-box defect B1 as `swc_zero` and
  `ne_swc_contradiction`; `model.Activity` carries `swc_lat`/`swc_long`/`nec_lat`/
  `nec_long` read from session fields 31/32/29/30. Gate G5 compares these against
  the independent reference.
- `dump` emits `ts_offset` (the raw compressed 5-bit offset, null when absent)
  alongside `ts`.
- `metrics.gps_avg_speed_mps` cross-check field; `docs/metrics.md` documents the
  elapsed split basis.
- New gates: `check_json` (JSON validity) and `check_notices` (runtime-dependency
  attribution); `check_boundaries` detects prefix-subset scope drift;
  `smoke_cli` covers bounds/window/trim usage errors.

### Changed

- `dump` `ts` is now the absolute reconstructed timestamp (was the raw offset).
- `model` prefers `enhanced_altitude`(78)/`enhanced_speed`(73) over the base
  fields; `sub_sport` maps 3=trail, 11=cyclocross and unknown codes to `other`.
- TCX numeric fields parse strictly (malformed/NaN/Infinity raise `Malformed`,
  exit 2); timestamps honour `Z`/`+hh:mm`/`-hh:mm` offsets; multi-lap `max_hr` is
  the max over laps and `avg_hr` the timer-weighted mean; a lap missing
  distance/time falls back to its trackpoints.
- `metrics` per-km splits use linear interpolation with a trim-aware start and
  bounded generation (`splits_truncated`); `avg_speed`/`avg_pace` use device
  distance over timer time.
- `redact` uses per-message effective endianness across local-type redefinition.
- Multi-session FIT and multi-Activity TCX are rejected with typed errors instead
  of being silently merged.
- `bounds`/`window`/`trim` arguments are validated (usage errors exit 2).

### Fixed

- Haversine clamps its `a` term to [0,1] so near-antipodal points stay finite.
- `model.track_point` uses the reconstructed compressed timestamp.
- Unified JSON escaping (control characters, quotes); non-finite numbers become
  `null` across dump/tcx/metrics/diff.
- `docs/boundaries.md` no longer lists delivered capabilities as limitations;
  `THIRD_PARTY_NOTICES.md` attributes `Milky2018/xml` and `moonbitlang/x`.

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
