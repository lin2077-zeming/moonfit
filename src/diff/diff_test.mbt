///|
test "diff: pause lost and law invariants on synthetic pair" {
  let fit : @model.Activity = {
    sport: "cycling",
    sub_sport: "road",
    start_time: 0L,
    points: [
      {
        timestamp: 0L,
        lat: Some(22.0),
        lon: Some(112.0),
        altitude_m: Some(1.0),
        distance_m: Some(0.0),
        speed_mps: None,
        heart_rate: Some(110),
        cadence: None,
        temperature: None,
      },
      {
        timestamp: 10L,
        lat: Some(22.001),
        lon: Some(112.001),
        altitude_m: Some(2.0),
        distance_m: Some(100.0),
        speed_mps: None,
        heart_rate: Some(120),
        cadence: None,
        temperature: None,
      },
    ],
    laps: [],
    device_distance_m: 100.0,
    elapsed_s: 20.0,
    timer_s: 10.0,
    moving_s: 10.0,
    device_ascent_m: 1.0,
    device_descent_m: 0.0,
    avg_hr: Some(115),
    max_hr: Some(120),
  }
  let tcx : @model.Activity = {
    sport: "cycling",
    sub_sport: "generic",
    start_time: 0L,
    points: fit.points,
    laps: [],
    device_distance_m: 100.0,
    elapsed_s: 10.0,
    timer_s: 10.0,
    moving_s: 10.0,
    device_ascent_m: 0.0,
    device_descent_m: 0.0,
    avg_hr: Some(115),
    max_hr: Some(120),
  }
  let d = @diff.compare(fit, tcx, false)
  assert_true(d.points_equal)
  assert_true(d.timer_equal)
  assert_eq(d.pause_lost_s, 10.0)
  assert_eq(d.distance_delta_m, 0.0)
  assert_eq(d.fit_alt, 2)
  assert_eq(d.tcx_alt, 2)
  assert_true(d.sport_equal)
  assert_true(d.first_ts_equal)
  assert_true(d.last_ts_equal)
}
