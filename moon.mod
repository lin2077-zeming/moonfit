// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html

name = "lin2077-zeming/moonfit"

version = "0.1.0"

readme = "README.mbt.md"

repository = "https://github.com/lin2077-zeming/moonfit"

license = "Apache-2.0"

keywords = [ "fit", "garmin", "tcx", "gps", "activity", "codec", "parser" ]

preferred_target = "native"

description = "Spec-driven Garmin FIT activity codec with byte-exact round-trip, TCX decoding, and measured cross-format divergence reports."

import {
  "moonbitlang/x@0.5.7",
}
