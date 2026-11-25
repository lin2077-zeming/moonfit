///|
fn has_semantic(ls : Array[@fidelity.Loss], sem : String) -> Bool {
  for l in ls {
    if l.semantic == sem {
      return true
    }
  }
  false
}

///|
fn act_with_times(elapsed : Double, timer : Double) -> @model.Activity {
  {
    sport: "cycling",
    sub_sport: "road",
    start_time: 0L,
    points: [],
    laps: [],
    device_distance_m: 0.0,
    elapsed_s: elapsed,
    timer_s: timer,
    moving_s: timer,
    device_ascent_m: 0.0,
    device_descent_m: 0.0,
    avg_hr: None,
    max_hr: None,
    swc_lat: None,
    swc_long: None,
    nec_lat: None,
    nec_long: None,
  }
}

///|
test "fidelity: tcx matrix cites format spec and excludes vendor subsampling" {
  let ls = match @fidelity.losses("tcx") {
    Some(a) => a
    None => []
  }
  assert_true(has_semantic(ls, "auto_pause"))
  assert_true(has_semantic(ls, "device_serial"))
  assert_true(has_semantic(ls, "coord_precision"))
  assert_true(!has_semantic(ls, "point_halving"))
  assert_true(!has_semantic(ls, "point_count"))
  for l in ls {
    assert_true(l.spec != "")
  }
}

///|
test "fidelity: gpx and kml matrices present, heart rate differs by format" {
  let gpx = match @fidelity.losses("gpx") {
    Some(a) => a
    None => []
  }
  let kml = match @fidelity.losses("kml") {
    Some(a) => a
    None => []
  }
  assert_true(has_semantic(gpx, "heart_rate"))
  assert_true(has_semantic(kml, "heart_rate"))
  assert_true(has_semantic(gpx, "distance"))
  assert_true(has_semantic(kml, "distance"))
}

///|
test "fidelity: report quantifies pause from elapsed minus timer" {
  let r = match @fidelity.report(act_with_times(6268.0, 5355.0), "tcx") {
    Some(x) => x
    None => fail("tcx is a valid target")
  }
  assert_eq(r.pause_lost_s, 913.0)
  assert_eq(r.record_count, 0)
  assert_eq(r.target, "tcx")
}

///|
test "fidelity: pause clamped at zero and unknown target rejected" {
  let r = match @fidelity.report(act_with_times(100.0, 200.0), "gpx") {
    Some(x) => x
    None => fail("gpx is a valid target")
  }
  assert_eq(r.pause_lost_s, 0.0)
  assert_true(@fidelity.losses("bogus") == None)
  assert_true(@fidelity.report(act_with_times(0.0, 0.0), "bogus") == None)
}

///|
fn find_loss(ls : Array[@fidelity.Loss], semantic : String) -> @fidelity.Loss? {
  for l in ls {
    if l.semantic == semantic {
      return Some(l)
    }
  }
  None
}

///|
test "R10: fidelity profiles produce distinct coordinate and extension policies" {
  let act : @model.Activity = {
    ..act_with_times(600.0, 540.0),
    points: [
      {
        timestamp: 0L,
        lat: Some(85.0),
        lon: Some(120.0),
        altitude_m: None,
        distance_m: None,
        speed_mps: Some(3.2),
        heart_rate: Some(145),
        cadence: None,
        temperature: None,
      },
    ],
  }
  let portable = match
    @fidelity.report_with_profile(act, "tcx", "portable-core") {
    Some(r) => r
    None => fail("portable profile rejected")
  }
  let extended = match
    @fidelity.report_with_profile(act, "tcx", "standard-extended") {
    Some(r) => r
    None => fail("extended profile rejected")
  }
  let minimal = match
    @fidelity.report_with_profile(act, "tcx", "loss-minimal") {
    Some(r) => r
    None => fail("minimal profile rejected")
  }
  assert_true(portable.analysis_only)
  assert_eq(portable.coordinate_digits, 7)
  assert_eq(extended.coordinate_digits, 9)
  assert_eq(minimal.coordinate_digits, 0)
  assert_true(portable.max_angle_error_deg > extended.max_angle_error_deg)
  assert_true(extended.max_longitude_error_m < extended.max_equator_error_m)
  let pc = match find_loss(portable.losses, "coord_precision") {
    Some(x) => x
    None => fail("portable coordinate loss missing")
  }
  let mc = match find_loss(minimal.losses, "coord_precision") {
    Some(x) => x
    None => fail("minimal coordinate loss missing")
  }
  assert_eq(pc.status, "rounded")
  assert_true(!pc.reversible)
  assert_eq(mc.status, "extension_preserved")
  assert_true(mc.reversible)
  let speed = match find_loss(portable.losses, "speed") {
    Some(x) => x
    None => fail("speed loss missing")
  }
  assert_eq(speed.status, "omitted")
  let extended_speed = match find_loss(extended.losses, "speed") {
    Some(x) => x
    None => fail("extended speed loss missing")
  }
  assert_eq(extended_speed.status, "extension_preserved")
}

///|
test "R11: TCX and GPX core altitude is not a format loss" {
  let act = act_with_times(600.0, 540.0)
  for target in ["tcx", "gpx"] {
    for profile in ["portable-core", "standard-extended", "loss-minimal"] {
      let report = match @fidelity.report_with_profile(act, target, profile) {
        Some(r) => r
        None => fail("valid target/profile rejected")
      }
      let altitude = match find_loss(report.losses, "enhanced_altitude") {
        Some(x) => x
        None => fail("enhanced altitude loss missing")
      }
      assert_eq(altitude.status, "exact")
      assert_true(altitude.reversible)
      assert_true(
        altitude.representation == "AltitudeMeters" ||
        altitude.representation == "ele",
      )
      assert_eq(altitude.max_error, 0.0)
    }
  }
}

///|
test "R12: fidelity report declares that no target writer is available" {
  let report = match
    @fidelity.report_with_profile(
      act_with_times(600.0, 540.0),
      "tcx",
      "standard-extended",
    ) {
    Some(r) => r
    None => fail("valid target/profile rejected")
  }
  assert_true(report.analysis_only)
  assert_true(!report.writer_available)
}

///|
test "R10: core and extension profiles expose different consumer views" {
  let act = act_with_times(600.0, 540.0)
  let portable_kml = match
    @fidelity.report_with_profile(act, "kml", "portable-core") {
    Some(r) => r
    None => fail("portable KML profile rejected")
  }
  let extended_kml = match
    @fidelity.report_with_profile(act, "kml", "standard-extended") {
    Some(r) => r
    None => fail("extended KML profile rejected")
  }
  let portable_hr = match find_loss(portable_kml.losses, "heart_rate") {
    Some(x) => x
    None => fail("portable KML heart rate missing")
  }
  let extended_hr = match find_loss(extended_kml.losses, "heart_rate") {
    Some(x) => x
    None => fail("extended KML heart rate missing")
  }
  assert_eq(portable_hr.status, "omitted")
  assert_eq(extended_hr.status, "extension_preserved")

  let portable_gpx = match
    @fidelity.report_with_profile(act, "gpx", "portable-core") {
    Some(r) => r
    None => fail("portable GPX profile rejected")
  }
  let extended_gpx = match
    @fidelity.report_with_profile(act, "gpx", "standard-extended") {
    Some(r) => r
    None => fail("extended GPX profile rejected")
  }
  let portable_distance = match find_loss(portable_gpx.losses, "distance") {
    Some(x) => x
    None => fail("portable GPX distance missing")
  }
  let extended_distance = match find_loss(extended_gpx.losses, "distance") {
    Some(x) => x
    None => fail("extended GPX distance missing")
  }
  assert_eq(portable_distance.status, "omitted")
  assert_eq(extended_distance.status, "extension_preserved")
  let portable_tcx = match
    @fidelity.report_with_profile(act, "tcx", "portable-core") {
    Some(r) => r
    None => fail("portable TCX profile rejected")
  }
  let extended_tcx = match
    @fidelity.report_with_profile(act, "tcx", "standard-extended") {
    Some(r) => r
    None => fail("extended TCX profile rejected")
  }
  let portable_speed = match find_loss(portable_tcx.losses, "speed") {
    Some(x) => x
    None => fail("portable TCX speed missing")
  }
  let extended_speed = match find_loss(extended_tcx.losses, "speed") {
    Some(x) => x
    None => fail("extended TCX speed missing")
  }
  assert_eq(portable_speed.status, "omitted")
  assert_eq(extended_speed.status, "extension_preserved")
}
