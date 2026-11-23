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
