///|
// Opaque newtypes for the units FIT actually stores on the wire.
//
// Design rule: every quantity is held as an exact integer in the device's own
// unit. Conversion to Double happens only at the API boundary and never in
// intermediate arithmetic. Three reasons, all of them concrete:
//
//   1. Width. FIT scalars are uint32. MoonBit's `Int` is 32-bit on the wasm
//      and js targets, so a uint32 timestamp or distance would overflow under
//      `moon check --target all`. Every native unit here is therefore Int64.
//
//   2. Exactness. Altitude raw 2458 decoded as `2458 / 5.0 - 500.0` yields
//      -8.399999999999977, while the exact decimetre path `2458 * 2 - 5000`
//      yields -84 dm, i.e. exactly -8.4 m. Those two Doubles are not equal.
//      Only the integer path can be asserted against a hardcoded constant.
//
//   3. Byte-exact re-encoding. The encoder works on these native integers, so
//      decode -> encode reproduces the original bytes by construction rather
//      than by luck with floating point.
//
// FIT mixes four scalings inside a single `record` message (semicircles,
// centimetres, mm/s, and altitude as (m + 500) * 5). Holding them in distinct
// types is what stops them from being silently interchanged.

///|
pub struct Semicircle {
  value : Int64
}

///|
pub struct Degrees {
  value : Double
}

///|
pub struct FitTimestamp {
  value : Int64
}

///|
pub struct UnixSecond {
  value : Int64
}

///|
pub struct Centimetre {
  value : Int64
}

///|
pub struct Decimetre {
  value : Int64
}

///|
#derive(Eq, Debug)
pub struct AltitudeRaw {
  value : Int64
}

///|
pub extend AltitudeRaw with Eq::{ not_equal, equal }

///|
pub extend AltitudeRaw with @moonbitlang/core/debug.Debug::{ to_repr }

///|
pub struct Metre {
  value : Double
}

///|
pub struct MillimetrePerSecond {
  value : Int64
}

///|
pub struct MetrePerSecond {
  value : Double
}

///|
pub struct Millisecond {
  value : Int64
}

///|
pub struct Second {
  value : Double
}

///|
pub struct Bpm {
  value : Int64
}

///|
pub struct Rpm {
  value : Int64
}

///|
pub struct Watt {
  value : Int64
}

///|
pub struct Celsius {
  value : Int64
}

///|
pub struct CentiPercent {
  value : Int64
}

///|
pub struct Percent {
  value : Double
}
