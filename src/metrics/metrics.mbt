///|
// Derived metrics over the canonical activity model.
//
// Distance: the device-reported cumulative distance is authoritative for splits
// and totals; a separate GPS-derived distance (spherical haversine) is provided
// as an independent cross-check (Gate G4 compares it against Karney geodesics
// with a documented sphere-vs-ellipsoid tolerance).
//
// Ascent: device total plus a computed value from the altitude series using a
// trailing moving-average window (explicit parameter), so the smoothing is
// reproducible and testable.
//
// Heart-rate zones: boundaries are supplied by the caller; time in each zone is
// accumulated from consecutive timestamp deltas. No built-in "recommended"
// zones, keeping this a measurement rather than advice.

///|
#derive(Eq, Debug)
pub(all) struct ZoneTime {
  lower : Int32?
  upper : Int32?
  seconds : Int64
}

///|
pub extend ZoneTime with Eq::{not_equal, equal}

///|
pub extend ZoneTime with @debug.Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Split {
  index : Int32
  end_distance_m : Double
  time_s : Int64
}

///|
pub extend Split with Eq::{not_equal, equal}

///|
pub extend Split with @debug.Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Metrics {
  device_distance_m : Double
  gps_distance_m : Double
  elapsed_s : Double
  timer_s : Double
  moving_s : Double
  avg_speed_mps : Double
  avg_pace_min_per_km : Double
  device_ascent_m : Double
  device_descent_m : Double
  computed_ascent_m : Double
  hr_zones : Array[ZoneTime]
  splits : Array[Split]
}

///|
pub extend Metrics with Eq::{not_equal, equal}

///|
pub extend Metrics with @debug.Debug::{to_repr}

///|
let earth_radius_m : Double = 6371000.0

///|
let deg_to_rad : Double = 3.141592653589793 / 180.0

///|
pub fn haversine(
  lat1 : Double,
  lon1 : Double,
  lat2 : Double,
  lon2 : Double,
) -> Double {
  let dlat = (lat2 - lat1) * deg_to_rad
  let dlon = (lon2 - lon1) * deg_to_rad
  let s1 = @math.sin(dlat / 2.0)
  let s2 = @math.sin(dlon / 2.0)
  let a = s1 * s1 +
    @math.cos(lat1 * deg_to_rad) * @math.cos(lat2 * deg_to_rad) * s2 * s2
  let c = 2.0 * @math.atan2(a.sqrt(), (1.0 - a).sqrt())
  earth_radius_m * c
}

///|
fn gps_distance(points : Array[@model.TrackPoint]) -> Double {
  let mut total = 0.0
  let mut i = 1
  while i < points.length() {
    let p = points[i - 1]
    let q = points[i]
    match (p.lat, p.lon, q.lat, q.lon) {
      (Some(a), Some(b), Some(c), Some(d)) =>
        total = total + haversine(a, b, c, d)
      _ => ()
    }
    i = i + 1
  }
  total
}

///|
fn computed_ascent(alts : Array[Double], window : Int32) -> Double {
  if alts.length() < 2 {
    return 0.0
  }
  let win = if window < 1 { 1 } else { window }
  let smooth : Array[Double] = []
  let mut i = 0
  while i < alts.length() {
    let start = if i - win + 1 > 0 { i - win + 1 } else { 0 }
    let mut sum = 0.0
    let mut n = 0
    let mut j = start
    while j <= i {
      sum = sum + alts[j]
      n = n + 1
      j = j + 1
    }
    smooth.push(sum / n.to_double())
    i = i + 1
  }
  let mut asc = 0.0
  let mut k = 1
  while k < smooth.length() {
    let d = smooth[k] - smooth[k - 1]
    if d > 0.0 {
      asc = asc + d
    }
    k = k + 1
  }
  asc
}

///|
fn hr_zones(
  points : Array[@model.TrackPoint],
  bounds : Array[Int32],
) -> Array[ZoneTime] {
  let secs : Array[Int64] = Array::make(bounds.length() + 1, 0L)
  let mut i = 0
  while i + 1 < points.length() {
    let p = points[i]
    let q = points[i + 1]
    match p.heart_rate {
      Some(hr) => {
        let dt = q.timestamp - p.timestamp
        if dt > 0L {
          let mut idx = 0
          for bnd in bounds {
            if hr >= bnd {
              idx = idx + 1
            }
          }
          secs[idx] = secs[idx] + dt
        }
      }
      None => ()
    }
    i = i + 1
  }
  let out : Array[ZoneTime] = []
  let mut z = 0
  while z < secs.length() {
    out.push({
      lower: if z == 0 {
        None
      } else {
        Some(bounds[z - 1])
      },
      upper: if z == bounds.length() {
        None
      } else {
        Some(bounds[z])
      },
      seconds: secs[z],
    })
    z = z + 1
  }
  out
}

///|
fn splits(points : Array[@model.TrackPoint], start : Int64) -> Array[Split] {
  let out : Array[Split] = []
  let mut last_km = 0
  let mut last_ts = start
  for p in points {
    match p.distance_m {
      Some(d) => {
        let km = @math.floor(d / 1000.0).to_int()
        if km > last_km {
          let mut k = last_km + 1
          while k <= km {
            out.push({
              index: k,
              end_distance_m: k.to_double() * 1000.0,
              time_s: p.timestamp - last_ts,
            })
            k = k + 1
          }
          last_ts = p.timestamp
          last_km = km
        }
      }
      None => ()
    }
  }
  out
}

///|
pub fn compute(
  act : @model.Activity,
  hr_bounds : Array[Int32],
  ascent_window : Int32,
) -> Metrics {
  let gps = gps_distance(act.points)
  let avg_speed = if act.timer_s > 0.0 { gps / act.timer_s } else { 0.0 }
  let pace = if avg_speed > 0.0 { 1000.0 / avg_speed / 60.0 } else { 0.0 }
  let alts : Array[Double] = []
  for p in act.points {
    match p.altitude_m {
      Some(a) => alts.push(a)
      None => ()
    }
  }
  {
    device_distance_m: act.device_distance_m,
    gps_distance_m: gps,
    elapsed_s: act.elapsed_s,
    timer_s: act.timer_s,
    moving_s: act.moving_s,
    avg_speed_mps: avg_speed,
    avg_pace_min_per_km: pace,
    device_ascent_m: act.device_ascent_m,
    device_descent_m: act.device_descent_m,
    computed_ascent_m: computed_ascent(alts, ascent_window),
    hr_zones: hr_zones(act.points, hr_bounds),
    splits: splits(act.points, act.start_time),
  }
} ///|

///|
pub fn to_json(m : Metrics) -> String {
  let mut zones = ""
  let mut i = 0
  for z in m.hr_zones {
    if i > 0 {
      zones = zones + ","
    }
    let lo = match z.lower {
      Some(v) => v.to_string()
      None => "null"
    }
    let hi = match z.upper {
      Some(v) => v.to_string()
      None => "null"
    }
    zones = zones +
      "{\"lower\":" +
      lo +
      ",\"upper\":" +
      hi +
      ",\"seconds\":" +
      z.seconds.to_string() +
      "}"
    i = i + 1
  }
  let mut sp = ""
  let mut j = 0
  for s in m.splits {
    if j > 0 {
      sp = sp + ","
    }
    sp = sp +
      "{\"index\":" +
      s.index.to_string() +
      ",\"end_distance_m\":" +
      s.end_distance_m.to_string() +
      ",\"time_s\":" +
      s.time_s.to_string() +
      "}"
    j = j + 1
  }
  "{\"device_distance_m\":" +
  m.device_distance_m.to_string() +
  ",\"gps_distance_m\":" +
  m.gps_distance_m.to_string() +
  ",\"elapsed_s\":" +
  m.elapsed_s.to_string() +
  ",\"timer_s\":" +
  m.timer_s.to_string() +
  ",\"moving_s\":" +
  m.moving_s.to_string() +
  ",\"avg_speed_mps\":" +
  m.avg_speed_mps.to_string() +
  ",\"avg_pace_min_per_km\":" +
  m.avg_pace_min_per_km.to_string() +
  ",\"device_ascent_m\":" +
  m.device_ascent_m.to_string() +
  ",\"device_descent_m\":" +
  m.device_descent_m.to_string() +
  ",\"computed_ascent_m\":" +
  m.computed_ascent_m.to_string() +
  ",\"hr_zones\":[" +
  zones +
  "]" +
  ",\"splits\":[" +
  sp +
  "]}"
}
