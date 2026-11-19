///|
// The FIT wire-unit conversion table, printed by `moonfit units`.
//
// Each row states the scaling, the exact integer representation the decoder
// keeps, and where the constant asserted by gate G7 came from. Printing the
// table from the same @units functions the tests call keeps the documentation
// and the implementation from drifting apart.

///|
pub struct UnitRow {
  field : String
  wire : String
  stored_as : String
  conversion : String
  constant_source : String
}

///|
pub fn unit_table() -> Array[UnitRow] {
  [
    {
      field: "position_lat, position_long",
      wire: "sint32 semicircles",
      stored_as: "Semicircle (Int64)",
      conversion: "degrees = semis * 180 / 2^31",
      constant_source: "266661528 -> 22.351311072707176, equal to the GPX export of the same point",
    },
    {
      field: "timestamp, start_time, local_timestamp",
      wire: "uint32 seconds since 1989-12-31T00:00:00Z",
      stored_as: "FitTimestamp (Int64)",
      conversion: "unix = fit + 631065600",
      constant_source: "1163581919 -> 2026-11-14T09:11:59Z, equal to the timestamp in the file name the device wrote",
    },
    {
      field: "distance, total_distance",
      wire: "uint32 centimetres",
      stored_as: "Centimetre (Int64)",
      conversion: "metres = cm / 100",
      constant_source: "3170445 -> 31704.45 m, equal to the TCX Lap DistanceMeters of the same activity",
    },
    {
      field: "altitude, enhanced_altitude",
      wire: "uint16 or uint32 as (metres + 500) * 5",
      stored_as: "Decimetre (Int64) via raw * 2 - 5000",
      conversion: "metres = dm / 10",
      constant_source: "2458 -> -84 dm -> exactly -8.4 m, while the naive 2458 / 5.0 - 500.0 gives -8.399999999999977",
    },
    {
      field: "speed, enhanced_speed, avg_speed, max_speed",
      wire: "uint16 or uint32 millimetres per second",
      stored_as: "MillimetrePerSecond (Int64)",
      conversion: "m/s = mmps / 1000",
      constant_source: "6964 -> 6.964 m/s, equal to the TCX Extensions TPX Speed of the same point",
    },
    {
      field: "total_elapsed_time, total_timer_time, total_moving_time",
      wire: "uint32 milliseconds",
      stored_as: "Millisecond (Int64)",
      conversion: "seconds = ms / 1000",
      constant_source: "5355000 -> 5355.0 s, equal to the TCX Lap TotalTimeSeconds of the same activity",
    },
    {
      field: "avg_grade, avg_pos_grade, max_neg_grade",
      wire: "sint16 hundredths of a percent",
      stored_as: "CentiPercent (Int64)",
      conversion: "percent = cp / 100",
      constant_source: "515 -> 5.15 percent, -421 -> -4.21 percent",
    },
    {
      field: "heart_rate, cadence, power, temperature",
      wire: "uint8, uint8, uint16, sint8; scale 1",
      stored_as: "Bpm, Rpm, Watt, Celsius (Int64)",
      conversion: "identity; the types only prevent interchange",
      constant_source: "heart_rate and cadence are both uint8 on the wire, so only the type keeps them apart",
    },
  ]
}

///|
pub fn print_unit_table() -> Unit {
  println("FIT wire units, the exact integer type each is stored in, and the")
  println("independent source of every constant asserted by gate G7.")
  println("")
  for row in unit_table() {
    println("field      : \{row.field}")
    println("on the wire: \{row.wire}")
    println("stored as  : \{row.stored_as}")
    println("conversion : \{row.conversion}")
    println("constant   : \{row.constant_source}")
    println("")
  }
  println("Live values from the units package:")
  println("  fit epoch in unix seconds  = \{@units.fit_epoch_unix}")
  println("  semicircles per half turn  = \{@units.semicircles_per_half_turn}")
  let one = @units.degrees_of_semicircle(@units.semicircle(1L))
  println("  one semicircle in degrees  = \{@units.degrees_value(one)}")
  let anchor = @units.metre_of_decimetre(
    @units.decimetre_of_altitude_raw(@units.altitude_raw(2500L)),
  )
  println("  altitude raw 2500 in metres = \{@units.metre_value(anchor)}")
}
