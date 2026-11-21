# Coverage

`moon coverage analyze` reports 273 uncovered lines across 16 files when only the
`moon test` unit suite is considered. These are **not** untested behaviour: they
are the CLI I/O glue and the branch paths that the CI *integration* gates exercise
by running the compiled binary over the entire corpus (G2 round-trip, G3 decode,
G4 metrics, G5 divergence, G6 verify/mutation, G8 field coverage, TCX, redact and
the CLI smoke test). Unit tests deliberately target the pure core (units, fit
parse/encode, base types) with binary assertions; the corpus-driven gates target
the assembled pipeline.

Per-file uncovered lines (unit-suite view):

| File | Uncovered | Exercised by |
|---|---|---|
| cmd/moonfit/dump.mbt | 78 | G2/G3/G4/G5/G8/TCX/redact/smoke (CLI) |
| src/model/model.mbt | 38 | G4/G5 (CLI metrics/diff) |
| src/diff/diff.mbt | 24 | G5 (CLI diff) |
| src/metrics/metrics.mbt | 24 | G4 (CLI metrics) |
| cmd/moonfit/main.mbt | 19 | smoke (dispatch/exit codes) |
| src/redact/redact.mbt | 16 | redact gate (CLI) |
| src/tcx/tcx.mbt | 16 | TCX gate (CLI) |
| src/fit/message.mbt | 15 | G3/G8 (CLI dump) |
| examples/wire_units/main.mbt | 14 | runnable example (manual/CI run) |
| src/fit/basetype.mbt | 6 | exhaustive base-type tests cover the rest |
| src/units/ctor.mbt | 5 | units tests cover the rest |
| cmd/moonfit/dispatch.mbt | 5 | smoke |
| cmd/moonfit/units_table.mbt | 4 | `units` CLI |
| src/fit/encode.mbt | 3 | G2 |
| src/fit/header.mbt | 3 | G6 |
| src/units/time.mbt | 3 | units ISO tests cover the rest |

The raw report is committed as `coverage_uncovered.log`. No core conversion,
parse or encode path is left without a binary assertion in either the unit suite
or the corpus gates.
