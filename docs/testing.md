# Verification gates

Every gate is a binary judgement. None of them asks whether a result is *good*;
each asks whether it equals a value derived independently of the code under
test.

`docs/boundaries.md` is the single source of truth for which capabilities this
release actually provides, and CI enforces it. This file only defines what each
gate means.

G7 runs before the others in CI: it validates the ruler before anything is
measured with it.

## Gate definitions

**G0 — corpus byte integrity.** Every file under `corpus/redacted/` hashes to
the value recorded in `SHA256SUMS`, and no `.fit` carries the Git `text`
attribute. Without this, G2 could pass against a file Git had silently
normalised and prove nothing.

**G1 — CRC.** The CRC-16 implementation reproduces the specification test
vectors, and rejects a corpus file whose trailing checksum has been flipped.

**G2 — byte-exact round trip.** `decode` followed by `encode` reproduces each
redacted `.fit` byte for byte, compared by SHA-256. This is the strongest
statement the project makes about its decoder, and it is checkable without
reference to any other implementation.

**G3 — field-level golden diff.** Every decoded field of every corpus file
equals the value an independent decoder reports for the same field, captured as
a checked-in golden snapshot.

**G4 — derived metric golden diff.** Distances, durations, pace, splits and
ascent equal the output of an independent script built on Karney geodesics,
with each tolerance written as a constant alongside its justification.

**G5 — divergence report golden diff.** The FIT to TCX divergence report equals
a checked-in snapshot, including the structural laws and the device defects
recorded in `docs/spec-notes.md`.

**G6 — robustness.** Truncated input, a broken checksum, an over-long field, a
zero-length message and a data record with no preceding definition each produce
a typed error rather than a panic or a non-terminating loop. A single-byte
mutation sweep across the corpus is rejected in full.

**G7 — the ruler.** Each unit conversion equals a hardcoded constant taken from
the FIT specification or from a cross-format corpus comparison. The tooling
that generates golden files has its own tests, run before its output is used.

**G8 — parameter space coverage.** Every message and every field observed in
the corpus has a recorded disposition. A field that is silently dropped fails
the gate, which is what prevents a single lucky sample from standing in for the
whole space.

## Rules that apply to all gates

- Expected values are constants. A test never calls the code under test to
  produce its own expectation.
- Tooling that generates a golden file is tested before its output is trusted.
- A parameter sweep replaces single-point checks. One clip start that happens to
  land on a frame boundary hides a systematic off-by-one; sweeping the space is
  what exposes it.
- Failure output states both the expected and the actual value, so a red gate is
  diagnosable without re-running anything.
- Errors leave through stderr and a non-zero exit code. A failure that prints to
  stdout and exits 0 is not a failure the caller can act on.
