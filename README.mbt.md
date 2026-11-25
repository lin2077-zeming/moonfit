# moonfit

Garmin FIT activity codec and cross-format fidelity analysis for MoonBit.

FIT records wire-level activity data. TCX, GPX and KML can carry different
subsets of that data depending on the target's core fields, standard extensions
and the export policy chosen by a converter. moonfit keeps those questions
separate:

- `moonfit diff` compares a specific FIT export with a specific TCX export and
  reports observed differences.
- `moonfit fidelity` reports the expected result of a named target profile from
  the target format specification. It does not write TCX, GPX or KML files.
- FIT semicircles are converted to decimal degrees as a unit conversion. A
  profile reports rounding bounds only when its decimal serialization chooses a
  finite number of fractional digits.

Measured observations in this repository include GPX point subsampling,
TCX timer-versus-elapsed time, missing fields in Huawei exports and the SWC
corner values. They are corpus observations and are kept separate from the
format capability report.

## Current delivery state

[`docs/boundaries.md`](docs/boundaries.md) is the authoritative list of what
this release provides and what it does not. CI fails if a capability is claimed
there without an evidence file, so it cannot drift from the code. The current
fidelity command is an analysis report with `analysis_only=true`.

## Install

```sh
moon add lin2077-zeming/moonfit
```

Requires moonc 0.10.20 or newer.

## Run the CLI

```sh
moon run cmd/moonfit -- units
```

`units` prints the FIT wire-unit table: each field's encoding, the exact
integer type the decoder keeps it in, the conversion, and where the constant
asserted by the test suite came from. It is the fastest way to see what the
module knows about the format.

```text
moonfit version    print the module version                     exit 0
moonfit units      print the wire-unit table                     exit 0
moonfit --help     print usage                                   exit 0
moonfit            no command given                              exit 2
moonfit <unknown>  usage error, diagnostics on stderr            exit 2
```

Diagnostics go to stderr and usage errors exit non-zero, so a caller can tell a
failure from a success without parsing output.

## Runnable example

```sh
moon run examples/wire_units
```

Takes the raw bytes of the first `record` in `corpus/redacted/ride-20261114.fit`
and turns them into the quantities a caller wants:

```text
position    : 22.351311072707176, 113.58801428228617
timestamp   : 2026-11-14T09:11:59Z
distance    : 31704.45 m
speed       : 6.964 m/s
altitude    : -8.4 m (exact, via -84 dm)
naive float : -8.399999999999977 m (a different Double)
timer time  : 4310 s
inverse     : 2458 (round trip exact)
odd dm      : no exact altitude raw, reported as None
```

The altitude lines are the point of the whole design in two lines of output.
`raw / 5.0 - 500.0` and `raw * 2 - 5000` decimetres describe the same
quantity, and they are not the same `Double`. Only the integer one can be
asserted against a constant, and only the integer one round-trips back to 2458.

## Commands

```text
moonfit version                 print the module version
moonfit units                   FIT wire-unit table + constant provenance
moonfit info <f.fit>            header, CRC status and message counts (JSON)
moonfit verify <f.fit>          total validity; exit 0 valid / 1 invalid
moonfit dump <f.fit>            JSONL of raw field values per data message
moonfit roundtrip <in> <out>    structure-preserving re-encode (byte-exact)
moonfit metrics <f.fit> [bounds] [window]   derived metrics (JSON)
moonfit tcx <f.tcx>             TCX -> canonical model summary (JSON)
moonfit diff <f.fit> <f.tcx>    FIT vs TCX observed-divergence report (JSON)
moonfit fidelity <f.fit> --target tcx|gpx|kml [--profile portable-core|standard-extended|loss-minimal]   profile report (JSON)
moonfit redact <in> <out> [trim] [dlat] [dlon] [--strip-hr] [--report path]   native redaction
```

## Fidelity profiles

`moonfit fidelity` requires one explicit `--target` and accepts one of three strategies. `--profile` defaults to `portable-core`. `portable-core`
uses target core fields and seven decimal places, and marks fields intentionally
left out as `omitted`. `standard-extended` enables the standard extension
locations named by the target format and uses nine decimal places for the
coordinate estimate. `loss-minimal` models a named `moonfit` extension that
would retain original FIT semicircles and activity values for an audit path.

The command reports the selected strategy, `analysis_only=true`, `writer_available=false`, the maximum
angle bound, the equator bound, the bound at the activity's mean latitude, each
semantic's `status`, `policy`, `spec` and `reversible` flag. These values describe
a conversion policy and its expected representation. `reversible` describes what the named profile would preserve if a writer were implemented; `writer_available=false` makes that boundary explicit. They are not evidence that
an output writer exists. Writing TCX, GPX and KML remains outside this release.

## Verification

Eight gates (G1-G8), all binary judgements, run in CI on every push; the corpus
gates run the compiled binary over all six rides / eight runs. See
[`docs/testing.md`](docs/testing.md) and [`docs/coverage.md`](docs/coverage.md).


The gates are defined in [`docs/testing.md`](docs/testing.md). Each one is a
binary comparison against a value derived independently of the code under test.
Nothing in this repository asks whether a result is good; everything asks
whether it equals something computed elsewhere.

G7 runs first in CI. It pins each unit conversion to a hardcoded constant, and
it tests the tooling that generates golden files before that tooling is allowed
to produce any. The reason is specific: an earlier project by the same author
was rejected because its measurement harness mixed two different bases, so the
error report it produced was wrong and could not support the claim built on it.

Run the gates locally:

```sh
moon check --target all --deny-warn
moon test --target native --deny-warn
moon test --target wasm --deny-warn
moon test --target wasm-gc --deny-warn
moon test --target js --deny-warn
python3 scripts/check_docs.py --self-test
python3 scripts/check_boundaries.py --self-test
python3 scripts/smoke_cli.py --self-test
```

## Corpus

`corpus/redacted/` holds real activity files: six outdoor rides from an
iGPSPORT cycle computer and eight outdoor runs from a Huawei band, recorded by
the project author and redacted before being committed.
`corpus/README.md` records what was changed and why, and `corpus/LICENSE.md`
states the licence. `scripts/check_corpus_integrity.py` runs first in CI and
fails if the committed bytes stop matching `SHA256SUMS`, which is what keeps the
byte-exact round-trip gate honest.

## Layout

```text
src/units/     native-unit types and the conversions between them
src/fit/       FIT container layer: CRC-16, file header, the sixteen base types
cmd/moonfit/   command line entry point
scripts/       corpus tooling and the CI gates, each with a self-test
docs/          boundaries, verification gates, and the measured corpus profile
corpus/        redacted activity files and their provenance
examples/      runnable examples
```

There is deliberately no module root package. Having one alongside subpackages
makes `moon bundle --all` report multiple producers for the root `.core`
artifact.

## AI usage

AI tooling assisted with scaffolding, test enumeration and prose. The technical
decisions are the author's and are argued for in the repository rather than
asserted: storing every wire scalar as an exact `Int64` in its native unit and
converting to `Double` only at the boundary; routing altitude through
decimetres because `raw / 5.0 - 500.0` does not equal the exact value;
replaying the definition-message stream so that re-encoding can be byte-exact;
and treating every measured regularity in `docs/spec-notes.md` as a gate rather
than a comment.

## Licence

Apache-2.0. See [`LICENSE`](LICENSE) and
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
