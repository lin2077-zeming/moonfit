///|
// Gate G7: the ruler gets tested first.
//
// Every expected value below is a hardcoded constant derived independently of
// the implementation - from the FIT specification for the scalings, and from
// Python's datetime / arithmetic for the timestamps. None of them is produced
// by calling the code under test. This gate runs first in CI on purpose: the
// previous project in this series failed acceptance because the measurement
// harness itself mixed two different bases, so the error report it produced
// was wrong and could not support the claimed accuracy.

///|
test "semicircle to degrees uses corpus-verified constants" {
  assert_eq(
    @units.degrees_value(@units.degrees_of_semicircle(@units.semicircle(0L))),
    0.0,
  )
  assert_eq(
    @units.degrees_value(
      @units.degrees_of_semicircle(@units.semicircle(266661528L)),
    ),
    22.351311072707176,
  )
  assert_eq(
    @units.degrees_value(
      @units.degrees_of_semicircle(@units.semicircle(1355157796L)),
    ),
    113.58801428228617,
  )
  assert_eq(
    @units.degrees_value(
      @units.degrees_of_semicircle(@units.semicircle(266888692L)),
    ),
    22.37035173922777,
  )
  assert_eq(
    @units.degrees_value(
      @units.degrees_of_semicircle(@units.semicircle(1344563350L)),
    ),
    112.69999807700515,
  )
}

///|
test "semicircle covers the full sint32 range" {
  assert_eq(
    @units.degrees_value(
      @units.degrees_of_semicircle(@units.semicircle(-2147483648L)),
    ),
    -180.0,
  )
  assert_eq(
    @units.degrees_value(
      @units.degrees_of_semicircle(@units.semicircle(2147483647L)),
    ),
    179.99999991618097,
  )
}

///|
test "one semicircle is about 9.3 mm on the equator" {
  let one = @units.degrees_value(
    @units.degrees_of_semicircle(@units.semicircle(1L)),
  )
  assert_eq(one, 8.381903171539307e-8)
  // Degrees to metres at the equator: 111319.49079327358 m per degree.
  assert_eq(one * 111319.49079327358, 0.009330691929342804)
}

///|
test "fit timestamp epoch is 1989-12-31T00:00:00Z" {
  assert_eq(
    @units.unix_second_value(
      @units.unix_of_fit_timestamp(@units.fit_timestamp(0L)),
    ),
    631065600L,
  )
  assert_eq(
    @units.unix_second_value(
      @units.unix_of_fit_timestamp(@units.fit_timestamp(1163581919L)),
    ),
    1794647519L,
  )
  assert_eq(@units.fit_epoch_unix, 631065600L)
}

///|
test "fit timestamp conversion round-trips" {
  for fit_value in [0L, 1L, 1154688006L, 1163581919L, 4294967295L] {
    let stamp = @units.fit_timestamp(fit_value)
    let unix = @units.unix_of_fit_timestamp(stamp)
    let back = @units.fit_timestamp_of_unix(unix)
    assert_eq(@units.fit_timestamp_value(back), fit_value)
  }
}

///|
test "iso8601 renders corpus timestamps" {
  assert_eq(
    @units.iso8601_of_unix_second(@units.unix_second(0L)),
    Some("1970-01-01T00:00:00Z"),
  )
  assert_eq(
    @units.iso8601_of_fit_timestamp(@units.fit_timestamp(1163581919L)),
    Some("2026-11-14T09:11:59Z"),
  )
  assert_eq(
    @units.iso8601_of_fit_timestamp(@units.fit_timestamp(1154688006L)),
    Some("2026-08-03T10:40:06Z"),
  )
  assert_eq(
    @units.iso8601_of_unix_second(@units.unix_second(631065600L)),
    Some("1989-12-31T00:00:00Z"),
  )
}

///|
test "iso8601 handles end of day and leap day" {
  assert_eq(
    @units.iso8601_of_unix_second(@units.unix_second(86399L)),
    Some("1970-01-01T23:59:59Z"),
  )
  assert_eq(
    @units.iso8601_of_unix_second(@units.unix_second(951782400L)),
    Some("2000-02-29T00:00:00Z"),
  )
}

///|
test "iso8601 covers the whole uint32 fit timestamp range" {
  assert_eq(
    @units.iso8601_of_fit_timestamp(@units.fit_timestamp(0L)),
    Some("1989-12-31T00:00:00Z"),
  )
  assert_eq(
    @units.iso8601_of_fit_timestamp(@units.fit_timestamp(4294967295L)),
    Some("2126-02-06T06:28:15Z"),
  )
}

///|
test "iso8601 uses floor division before the epoch" {
  // FIT timestamps are unsigned so this branch is unreachable from a real file.
  // It is covered anyway so the defensive path is not dead code.
  assert_eq(
    @units.iso8601_of_unix_second(@units.unix_second(-1L)),
    Some("1969-12-31T23:59:59Z"),
  )
}

///|
test "iso8601 refuses years the fixed width cannot hold" {
  assert_eq(
    @units.iso8601_of_unix_second(@units.unix_second(253402300799L)),
    Some("9999-12-31T23:59:59Z"),
  )
  assert_eq(
    @units.iso8601_of_unix_second(@units.unix_second(253402300800L)),
    None,
  )
}

///|
test "centimetre to metre" {
  assert_eq(
    @units.metre_value(@units.metre_of_centimetre(@units.centimetre(0L))),
    0.0,
  )
  assert_eq(
    @units.metre_value(@units.metre_of_centimetre(@units.centimetre(81703L))),
    817.03,
  )
  assert_eq(
    @units.metre_value(@units.metre_of_centimetre(@units.centimetre(3170445L))),
    31704.45,
  )
}

///|
test "altitude raw to decimetre is exact integer arithmetic" {
  // raw 2500 is the zero anchor: (0 m + 500) * 5.
  assert_eq(
    @units.decimetre_value(
      @units.decimetre_of_altitude_raw(@units.altitude_raw(2500L)),
    ),
    0L,
  )
  assert_eq(
    @units.decimetre_value(
      @units.decimetre_of_altitude_raw(@units.altitude_raw(2458L)),
    ),
    -84L,
  )
  assert_eq(
    @units.decimetre_value(
      @units.decimetre_of_altitude_raw(@units.altitude_raw(2439L)),
    ),
    -122L,
  )
  assert_eq(
    @units.decimetre_value(
      @units.decimetre_of_altitude_raw(@units.altitude_raw(2668L)),
    ),
    336L,
  )
  assert_eq(
    @units.decimetre_value(
      @units.decimetre_of_altitude_raw(@units.altitude_raw(0L)),
    ),
    -5000L,
  )
  assert_eq(
    @units.decimetre_value(
      @units.decimetre_of_altitude_raw(@units.altitude_raw(65535L)),
    ),
    126070L,
  )
}

///|
test "altitude float path is not the naive one" {
  // Documents why the decimetre representation exists: the naive float
  // decoding of the same raw value does not equal the exact one.
  let exact = @units.metre_value(
    @units.metre_of_decimetre(
      @units.decimetre_of_altitude_raw(@units.altitude_raw(2458L)),
    ),
  )
  assert_eq(exact, -8.4)
  let naive = 2458.0 / 5.0 - 500.0
  assert_eq(naive, -8.399999999999977)
  assert_true(exact != naive)
}

///|
test "decimetre to metre" {
  assert_eq(
    @units.metre_value(@units.metre_of_decimetre(@units.decimetre(0L))),
    0.0,
  )
  assert_eq(
    @units.metre_value(@units.metre_of_decimetre(@units.decimetre(-84L))),
    -8.4,
  )
  assert_eq(
    @units.metre_value(@units.metre_of_decimetre(@units.decimetre(-122L))),
    -12.2,
  )
  assert_eq(
    @units.metre_value(@units.metre_of_decimetre(@units.decimetre(336L))),
    33.6,
  )
}

///|
test "altitude raw and decimetre round-trip" {
  for raw in [0L, 1L, 2439L, 2458L, 2500L, 2668L, 65535L] {
    let dm = @units.decimetre_of_altitude_raw(@units.altitude_raw(raw))
    match @units.altitude_raw_of_decimetre(dm) {
      Some(back) => assert_eq(@units.altitude_raw_value(back), raw)
      None => fail("expected an exact inverse")
    }
  }
}

///|
test "odd decimetre has no exact altitude raw" {
  assert_eq(@units.altitude_raw_of_decimetre(@units.decimetre(-83L)), None)
  assert_eq(@units.altitude_raw_of_decimetre(@units.decimetre(1L)), None)
  assert_eq(
    @units.altitude_raw_of_decimetre(@units.decimetre(-84L)),
    Some(@units.altitude_raw(2458L)),
  )
}

///|
test "millimetre per second to metre per second" {
  assert_eq(
    @units.metre_per_second_value(
      @units.metre_per_second_of_millimetre_per_second(
        @units.millimetre_per_second(0L),
      ),
    ),
    0.0,
  )
  assert_eq(
    @units.metre_per_second_value(
      @units.metre_per_second_of_millimetre_per_second(
        @units.millimetre_per_second(6964L),
      ),
    ),
    6.964,
  )
  assert_eq(
    @units.metre_per_second_value(
      @units.metre_per_second_of_millimetre_per_second(
        @units.millimetre_per_second(12959L),
      ),
    ),
    12.959,
  )
}

///|
test "millisecond to second" {
  assert_eq(
    @units.second_value(@units.second_of_millisecond(@units.millisecond(0L))),
    0.0,
  )
  assert_eq(
    @units.second_value(
      @units.second_of_millisecond(@units.millisecond(4310000L)),
    ),
    4310.0,
  )
  assert_eq(
    @units.second_value(
      @units.second_of_millisecond(@units.millisecond(4681000L)),
    ),
    4681.0,
  )
  assert_eq(
    @units.second_value(
      @units.second_of_millisecond(@units.millisecond(5355000L)),
    ),
    5355.0,
  )
}

///|
test "centi percent to percent" {
  assert_eq(
    @units.percent_value(
      @units.percent_of_centi_percent(@units.centi_percent(0L)),
    ),
    0.0,
  )
  assert_eq(
    @units.percent_value(
      @units.percent_of_centi_percent(@units.centi_percent(515L)),
    ),
    5.15,
  )
  assert_eq(
    @units.percent_value(
      @units.percent_of_centi_percent(@units.centi_percent(-421L)),
    ),
    -4.21,
  )
}

///|
test "marker units keep their payload and stay distinct" {
  assert_eq(@units.bpm_value(@units.bpm(156L)), 156L)
  assert_eq(@units.rpm_value(@units.rpm(90L)), 90L)
  assert_eq(@units.watt_value(@units.watt(250L)), 250L)
  assert_eq(@units.celsius_value(@units.celsius(21L)), 21L)
  assert_eq(@units.celsius_value(@units.celsius(-5L)), -5L)
  // Bpm and Rpm are both Int64 on the wire but must not be interchangeable.
  let heart_rate : @units.Bpm = @units.bpm(90L)
  let cadence : @units.Rpm = @units.rpm(90L)
  assert_eq(@units.bpm_value(heart_rate), @units.rpm_value(cadence))
}
