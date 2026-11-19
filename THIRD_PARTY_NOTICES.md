# Third-party notices

## Runtime dependencies

These are declared in `moon.mod` and are linked into anything built from this
module.

| Module | Licence | Use |
|---|---|---|
| `moonbitlang/core` | Apache-2.0 | Language core. `core/argparse` provides command-line parsing and `core/env` provides process arguments and exit. |

## Development-only tooling

These are used to generate or cross-check golden files. They are **not** linked
into this module, are not declared in `moon.mod`, and are not required to build
or test it.

| Tool | Licence | Use |
|---|---|---|
| `fitparse` 1.2.0 | BSD-3-Clause | Independent FIT decoder used to cross-check the byte-level walker and to produce field-level golden snapshots. Where the two disagree the walker is authoritative, because `fitparse` synthesises `enhanced_speed` and `enhanced_altitude` from `speed` and `altitude` even when those fields are absent from the file. |
| `geographiclib` | MIT | Karney geodesics, used to derive expected distances independently of this module. |

## Garmin FIT SDK

This module is **not** derived from the Garmin FIT SDK. The SDK is distributed
under a proprietary licence and no SDK source code has been copied, translated
or linked here. The SDK's published file-format description and profile field
tables were consulted as a specification, in the same way an RFC is consulted,
and the field numbers, scalings and invalid-value conventions recorded in
`docs/spec-notes.md` were then confirmed against the corpus by direct byte-level
inspection.

## Corpus

The activity files under `corpus/redacted/` were recorded by the project author
using an iGPSPORT cycle computer and a Huawei band, and were redacted before
being committed. They are not third-party works. See `corpus/LICENSE.md` and
`corpus/README.md`.
