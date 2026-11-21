///|
test "haversine: one degree of latitude on the sphere" {
  let d = @metrics.haversine(0.0, 0.0, 1.0, 0.0)
  assert_true((d - 111194.92664455873).abs() < 0.000001)
}

///|
test "metrics: synthetic activity splits, zones and ascent" {
  let act : @model.Activity = {
    sport: "cycling",
    sub_sport: "road",
    start_time: 0L,
    points: [
      {
        timestamp: 0L,
        lat: None,
        lon: None,
        altitude_m: Some(0.0),
        distance_m: Some(0.0),
        speed_mps: None,
        heart_rate: Some(110),
        cadence: None,
        temperature: None,
      },
      {
        timestamp: 10L,
        lat: None,
        lon: None,
        altitude_m: Some(10.0),
        distance_m: Some(1000.0),
        speed_mps: None,
        heart_rate: Some(130),
        cadence: None,
        temperature: None,
      },
      {
        timestamp: 20L,
        lat: None,
        lon: None,
        altitude_m: Some(20.0),
        distance_m: Some(2000.0),
        speed_mps: None,
        heart_rate: Some(150),
        cadence: None,
        temperature: None,
      },
    ],
    laps: [],
    device_distance_m: 2000.0,
    elapsed_s: 20.0,
    timer_s: 20.0,
    moving_s: 20.0,
    device_ascent_m: 20.0,
    device_descent_m: 0.0,
    avg_hr: None,
    max_hr: None,
  }
  let m = @metrics.compute(act, [120, 140], 1)
  assert_eq(m.computed_ascent_m, 20.0)
  assert_eq(m.gps_distance_m, 0.0)
  assert_eq(m.hr_zones.length(), 3)
  assert_eq(m.hr_zones[0].seconds, 10L)
  assert_eq(m.hr_zones[1].seconds, 10L)
  assert_eq(m.hr_zones[2].seconds, 0L)
  assert_eq(m.splits.length(), 2)
  assert_eq(m.splits[0].time_s, 10L)
  assert_eq(m.splits[1].time_s, 10L)
}

///|
test "P0-2: no-GPS activity uses device distance for avg speed/pace" {
  let act : @model.Activity = {
    sport: "running",
    sub_sport: "treadmill",
    start_time: 0L,
    points: [
      {
        timestamp: 0L,
        lat: None,
        lon: None,
        altitude_m: None,
        distance_m: Some(0.0),
        speed_mps: None,
        heart_rate: None,
        cadence: None,
        temperature: None,
      },
      {
        timestamp: 20L,
        lat: None,
        lon: None,
        altitude_m: None,
        distance_m: Some(1000.0),
        speed_mps: None,
        heart_rate: None,
        cadence: None,
        temperature: None,
      },
    ],
    laps: [],
    device_distance_m: 1000.0,
    elapsed_s: 20.0,
    timer_s: 20.0,
    moving_s: 20.0,
    device_ascent_m: 0.0,
    device_descent_m: 0.0,
    avg_hr: None,
    max_hr: None,
  }
  let m = @metrics.compute(act, [], 1)
  assert_eq(m.gps_distance_m, 0.0)
  assert_eq(m.avg_speed_mps, 50.0)
  assert_eq(m.avg_pace_min_per_km, 1000.0 / 50.0 / 60.0)
}

///|
fn pt(ts : Int64, d : Double) -> @model.TrackPoint {
  {
    timestamp: ts,
    lat: None,
    lon: None,
    altitude_m: None,
    distance_m: Some(d),
    speed_mps: None,
    heart_rate: None,
    cadence: None,
    temperature: None,
  }
}

///|
fn act_of(
  points : Array[@model.TrackPoint],
  dist : Double,
  timer : Double,
) -> @model.Activity {
  {
    sport: "cycling",
    sub_sport: "road",
    start_time: 0L,
    points,
    laps: [],
    device_distance_m: dist,
    elapsed_s: timer,
    timer_s: timer,
    moving_s: timer,
    device_ascent_m: 0.0,
    device_descent_m: 0.0,
    avg_hr: None,
    max_hr: None,
  }
}

///|
test "P0-3: single km split interpolated" {
  let m = @metrics.compute(
    act_of([pt(0L, 0.0), pt(10L, 1000.0)], 1000.0, 10.0),
    [],
    1,
  )
  assert_eq(m.splits.length(), 1)
  assert_eq(m.splits[0].time_s, 10L)
  assert_eq(m.split_basis, "elapsed")
}

///|
test "P0-3: multi-km jump gets distinct interpolated times" {
  let m = @metrics.compute(
    act_of([pt(0L, 0.0), pt(30L, 3000.0)], 3000.0, 30.0),
    [],
    1,
  )
  assert_eq(m.splits.length(), 3)
  assert_eq(m.splits[0].time_s, 10L)
  assert_eq(m.splits[1].time_s, 10L)
  assert_eq(m.splits[2].time_s, 10L)
}

///|
test "P0-3: trimmed track does not backfill leading kilometres" {
  let m = @metrics.compute(
    act_of([pt(30L, 3000.0), pt(40L, 4000.0)], 4000.0, 40.0),
    [],
    1,
  )
  assert_eq(m.splits.length(), 1)
  assert_eq(m.splits[0].index, 4)
  assert_eq(m.splits[0].time_s, 10L)
}

///|
test "P0-5: hostile uint32 distance truncates splits instead of DoS" {
  let m = @metrics.compute(
    act_of([pt(0L, 0.0), pt(1L, 4294967295.0)], 4294967295.0, 1.0),
    [],
    1,
  )
  assert_true(m.splits_truncated)
  assert_eq(m.splits.length(), 0)
}

///|
test "P0-5: single jump beyond 100 km truncates" {
  let m = @metrics.compute(
    act_of([pt(0L, 0.0), pt(10L, 200000.0)], 200000.0, 10.0),
    [],
    1,
  )
  assert_true(m.splits_truncated)
  assert_eq(m.splits.length(), 0)
}

///|
test "P0-5: normal track is not truncated" {
  let m = @metrics.compute(
    act_of([pt(0L, 0.0), pt(30L, 3000.0)], 3000.0, 30.0),
    [],
    1,
  )
  assert_true(!m.splits_truncated)
  assert_eq(m.splits.length(), 3)
}
