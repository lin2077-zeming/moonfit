///|
// Runnable example: take the values a FIT `record` message carries on the wire
// and turn them into the quantities a caller actually wants.
//
// Every input below is a real value read out of
// corpus/redacted/ride-20261114.fit, and every expected output is asserted in
// src/units/units_test.mbt against a constant derived independently of this
// code.
//
// Run with:  moon run examples/wire_units

///|
fn main {
  // The first record of the ride, exactly as the device wrote it.
  let raw_lat = 266661528L
  let raw_lon = 1355157796L
  let raw_timestamp = 1163581919L
  let raw_distance_cm = 3170445L
  let raw_speed_mmps = 6964L
  let raw_altitude = 2458L
  let raw_timer_ms = 4310000L

  let lat = @units.degrees_of_semicircle(@units.semicircle(raw_lat))
  let lon = @units.degrees_of_semicircle(@units.semicircle(raw_lon))
  println(
    "position    : \{@units.degrees_value(lat)}, \{@units.degrees_value(lon)}",
  )

  match @units.iso8601_of_fit_timestamp(@units.fit_timestamp(raw_timestamp)) {
    Some(text) => println("timestamp   : \{text}")
    None => println("timestamp   : <unrepresentable year>")
  }

  let distance = @units.metre_of_centimetre(@units.centimetre(raw_distance_cm))
  println("distance    : \{@units.metre_value(distance)} m")

  let speed = @units.metre_per_second_of_millimetre_per_second(
    @units.millimetre_per_second(raw_speed_mmps),
  )
  println("speed       : \{@units.metre_per_second_value(speed)} m/s")

  // Altitude goes through decimetres so the result is exact. The naive float
  // expression raw / 5.0 - 500.0 does not produce the same Double.
  let decimetres = @units.decimetre_of_altitude_raw(
    @units.altitude_raw(raw_altitude),
  )
  let altitude = @units.metre_of_decimetre(decimetres)
  println(
    "altitude    : \{@units.metre_value(altitude)} m (exact, via \{@units.decimetre_value(decimetres)} dm)",
  )
  println(
    "naive float : \{raw_altitude.to_double() / 5.0 - 500.0} m (a different Double)",
  )

  let timer = @units.second_of_millisecond(@units.millisecond(raw_timer_ms))
  println("timer time  : \{@units.second_value(timer)} s")

  // The inverse conversion refuses a value it cannot represent exactly rather
  // than truncating it.
  match @units.altitude_raw_of_decimetre(decimetres) {
    Some(back) =>
      println(
        "inverse     : \{@units.altitude_raw_value(back)} (round trip exact)",
      )
    None => println("inverse     : <no exact representation>")
  }
  match @units.altitude_raw_of_decimetre(@units.decimetre(-83L)) {
    Some(_) => println("odd dm      : unexpectedly representable")
    None => println("odd dm      : no exact altitude raw, reported as None")
  }
}
