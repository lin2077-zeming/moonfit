///|
// Constructors and accessors. The struct fields are private, so these are the
// only way to build a unit value or read the native integer back out. That is
// deliberate: it is what stops a Centimetre from being passed where a
// Decimetre is expected.

///|
pub fn semicircle(value : Int64) -> Semicircle {
  { value, }
}

///|
pub fn semicircle_value(x : Semicircle) -> Int64 {
  x.value
}

///|
pub fn fit_timestamp(value : Int64) -> FitTimestamp {
  { value, }
}

///|
pub fn fit_timestamp_value(x : FitTimestamp) -> Int64 {
  x.value
}

///|
pub fn unix_second(value : Int64) -> UnixSecond {
  { value, }
}

///|
pub fn unix_second_value(x : UnixSecond) -> Int64 {
  x.value
}

///|
pub fn centimetre(value : Int64) -> Centimetre {
  { value, }
}

///|
pub fn centimetre_value(x : Centimetre) -> Int64 {
  x.value
}

///|
pub fn decimetre(value : Int64) -> Decimetre {
  { value, }
}

///|
pub fn decimetre_value(x : Decimetre) -> Int64 {
  x.value
}

///|
pub fn altitude_raw(value : Int64) -> AltitudeRaw {
  { value, }
}

///|
pub fn altitude_raw_value(x : AltitudeRaw) -> Int64 {
  x.value
}

///|
pub fn millimetre_per_second(value : Int64) -> MillimetrePerSecond {
  { value, }
}

///|
pub fn millimetre_per_second_value(x : MillimetrePerSecond) -> Int64 {
  x.value
}

///|
pub fn millisecond(value : Int64) -> Millisecond {
  { value, }
}

///|
pub fn millisecond_value(x : Millisecond) -> Int64 {
  x.value
}

///|
pub fn bpm(value : Int64) -> Bpm {
  { value, }
}

///|
pub fn bpm_value(x : Bpm) -> Int64 {
  x.value
}

///|
pub fn rpm(value : Int64) -> Rpm {
  { value, }
}

///|
pub fn rpm_value(x : Rpm) -> Int64 {
  x.value
}

///|
pub fn watt(value : Int64) -> Watt {
  { value, }
}

///|
pub fn watt_value(x : Watt) -> Int64 {
  x.value
}

///|
pub fn celsius(value : Int64) -> Celsius {
  { value, }
}

///|
pub fn celsius_value(x : Celsius) -> Int64 {
  x.value
}

///|
pub fn centi_percent(value : Int64) -> CentiPercent {
  { value, }
}

///|
pub fn centi_percent_value(x : CentiPercent) -> Int64 {
  x.value
}

///|
pub fn metre_value(x : Metre) -> Double {
  x.value
}

///|
pub fn second_value(x : Second) -> Double {
  x.value
}

///|
pub fn metre_per_second_value(x : MetrePerSecond) -> Double {
  x.value
}

///|
pub fn degrees_value(x : Degrees) -> Double {
  x.value
}

///|
pub fn percent_value(x : Percent) -> Double {
  x.value
}
