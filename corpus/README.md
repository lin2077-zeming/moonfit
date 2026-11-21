# Corpus

Fourteen real activities recorded by the project author: six outdoor rides from
an iGPSPORT cycle computer and eight outdoor runs from a Huawei activity band.
Forty-two files in total, plus `SHA256SUMS` and `manifest.csv`.

This is not sample data and not synthetic data. Every file was produced by a
physical device during a physical activity, exported by the vendor's own
application, and redacted by `scripts/redact_corpus.py` before being committed.
`LICENSE.md` records the provenance and dedicates the files to the public
domain under CC0 1.0.

## What is here

| Prefix | Activities | Formats | Source |
|---|---|---|---|
| `ride-YYYYMMDD` | 6 | `.fit` `.tcx` `.gpx` | iGPSPORT cycle computer |
| `run-YYYYMMDD` | 8 | `.tcx` `.gpx` `.kml` | Huawei activity band |

`manifest.csv` maps every committed name back to the filename the vendor
application produced, together with its SHA-256.

Only FIT and TCX are parsed by this module. The GPX and KML files are kept
because the cross-format observations in `docs/spec-notes.md` are stated in
terms of all four exports, and a reviewer should be able to reproduce them.
GPX parsing belongs to `2973181701/moongpx` and KML to
`cp15695540483/moonkml`; see `docs/boundaries.md`.

## Redaction

The raw exports contained two things that must not be published: the device
serial number, and the absolute coordinates of the author's home and regular
routes.

Applied to every file:

| Change | Detail |
|---|---|
| Device serial number | Zeroed in all three places it occurs per FIT file: `file_id.serial_number` and both `device_info.serial_number` records, each a `uint32z` array of 8 elements. 18 fields across the corpus. |
| Latitude | Shifted by **+600000 semicircles** = +0.05029141902923584 degrees, about 5.6 km north |
| Longitude | Shifted by **-800000 semicircles** = -0.06705522537231445 degrees, about 6.2 km west at this latitude |
| FIT trailing CRC-16 | Recomputed over bytes `[0, len-2)` after the edit |

3144 FIT latitudes and 3144 FIT longitudes were shifted, plus 12207 of each in
the XML exports. In FIT the shift is an exact integer number of semicircles. In
the XML exports the equivalent number of degrees is added and the result is
re-rounded to the decimal precision that file already used, which is the entire
source of the deviations tabulated in `docs/spec-notes.md`.

Deliberately **not** changed:

- **`session.swc_lat` and `session.swc_long` stay at 0.** They are 0 in the raw
  exports too, while `nec_lat` and `nec_long` hold real values. That
  contradiction is defect B1 in `docs/spec-notes.md` and a gate asserts it, so
  shifting those fields would destroy the evidence.
- **Timestamps.** Every `timestamp`, `start_time` and `local_timestamp` is
  untouched, so durations, sampling intervals and auto-pause structure are all
  exactly as recorded.
- **Distance, speed, altitude, heart rate, temperature, calories, ascent and
  descent.** Untouched, in the raw units the device wrote.
- **Record counts and message structure.** Redaction is surgical byte patching,
  not a re-encode, so the definition-message stream, the field layouts and the
  message counts are unchanged. The tool's self-test asserts that no byte
  outside the serial, coordinate and trailing-CRC spans differs, that the file
  length is unchanged, and that the redacted file still walks exactly.

No track points are trimmed. The shortest ride (`ride-20260803`) has only 45
record messages, so removing 30 from each end would delete the whole track; the
corpus therefore uses trim=0 for every file. The `moonfit redact` command still
accepts an optional head/tail trim count, an optional `--strip-hr` flag that
invalidates heart-rate fields, and an optional `--report <path>` flag that writes
a machine-readable JSON list of what changed (serial zeroed, lat/lon shifted,
heart-rate stripped, records trimmed, fields changed, and the two deltas). Those
capabilities are covered by `src/redact/redact_test.mbt`; the committed corpus
exercises the trim=0, heart-rate-preserving path.

Residual exposure: the **shape** of each route is preserved, including its start
and end points. Only the absolute position moved, by the fixed offset published
above. Because that offset is published, the translation is reversible: it
obscures the absolute location but does not remove the route geometry. Trimming
the head/tail (available via `moonfit redact`) is the option that would remove the
start/end vicinity, and it is not applied to this corpus.

## Integrity

`SHA256SUMS` covers all 43 files including `manifest.csv`. Gate 0 in CI
verifies it before any other gate runs, and also fails if any `.fit` carries
the Git `text` attribute or if any text file in this directory contains a
carriage return. Both conditions have occurred once already:

- `.fit` files are marked `binary` in `.gitattributes`, committed before any
  corpus file. Had they been treated as text, line-ending normalisation would
  have changed the committed bytes and the byte-exact round-trip gate would
  have been comparing against something the device never wrote. Fixing
  `.gitattributes` afterwards does not repair blobs already in history.
- `manifest.csv` was first written with CRLF because `Path.write_text`
  translates newlines using the host default. The recorded digest was of the
  CRLF bytes while the repository stores LF, so a fresh clone did not
  reproduce it. `scripts/redact_corpus.py` now writes these files through an
  explicit LF helper, and Gate 0 rejects a carriage return outright.

Reproduce the corpus from raw exports:

```sh
python3 scripts/redact_corpus.py --self-test --source /path/to/raw/exports
python3 scripts/redact_corpus.py --source /path/to/raw/exports --out corpus/redacted
python3 scripts/check_corpus_integrity.py
```

Redaction is deterministic: running it twice over the same input reproduces
`SHA256SUMS` byte for byte.
