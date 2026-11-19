///|
// Unit conversions. Each one has exactly one implementation here and exactly
// one gate-G7 test asserting a hardcoded constant derived independently of
// this code. Nothing else in the project is allowed to scale a FIT scalar.

///|
// FIT epoch: 1989-12-31T00:00:00Z expressed in Unix seconds.
pub let fit_epoch_unix : Int64 = 631065600L

///|
// 2 ^ 31, the number of semicircles in half a turn. Held as a Double literal
// because it is one past the maximum Int64-magnitude value that a 32-bit
// `Int` target could hold, and it is only ever used as a divisor.
pub let semicircles_per_half_turn : Double = 2147483648.0

///|
// One semicircle is about 8.381903171539307e-8 degrees, roughly 9.3 mm on the
// equator. That is why FIT positions carry more precision than the
// 6-decimal degrees some devices write into GPX.
pub fn degrees_of_semicircle(x : Semicircle) -> Degrees {
  { value: x.value.to_double() * 180.0 / semicircles_per_half_turn }
}

///|
pub fn unix_of_fit_timestamp(x : FitTimestamp) -> UnixSecond {
  { value: x.value + fit_epoch_unix }
}

///|
pub fn fit_timestamp_of_unix(x : UnixSecond) -> FitTimestamp {
  { value: x.value - fit_epoch_unix }
}

///|
pub fn metre_of_centimetre(x : Centimetre) -> Metre {
  { value: x.value.to_double() / 100.0 }
}

///|
// FIT stores altitude as (metres + 500) * 5. Converting to decimetres keeps
// the value exact: raw * 2 - 5000.
pub fn decimetre_of_altitude_raw(x : AltitudeRaw) -> Decimetre {
  { value: x.value * 2L - 5000L }
}

///|
// Inverse of the above. Returns None when the decimetre value has no exact
// altitude raw, rather than silently truncating: an odd (dm + 5000) is not
// representable.
pub fn altitude_raw_of_decimetre(x : Decimetre) -> Option[AltitudeRaw] {
  let shifted = x.value + 5000L
  if shifted % 2L != 0L {
    None
  } else {
    Some({ value: shifted / 2L })
  }
}

///|
pub fn metre_of_decimetre(x : Decimetre) -> Metre {
  { value: x.value.to_double() / 10.0 }
}

///|
pub fn metre_per_second_of_millimetre_per_second(
  x : MillimetrePerSecond
) -> MetrePerSecond {
  { value: x.value.to_double() / 1000.0 }
}

///|
pub fn second_of_millisecond(x : Millisecond) -> Second {
  { value: x.value.to_double() / 1000.0 }
}

///|
// Grade fields are sint16 with scale 100, i.e. hundredths of a percent.
pub fn percent_of_centi_percent(x : CentiPercent) -> Percent {
  { value: x.value.to_double() / 100.0 }
}
