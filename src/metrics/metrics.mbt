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
  gps_avg_speed_mps : Double
  avg_pace_min_per_km : Double
  device_ascent_m : Double
  device_descent_m : Double
  computed_ascent_m : Double
  hr_zones : Array[ZoneTime]
  splits : Array[Split]
  split_basis : String
  splits_truncated : Bool
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
  let raw_a = s1 * s1 +
    @math.cos(lat1 * deg_to_rad) * @math.cos(lat2 * deg_to_rad) * s2 * s2
  // Clamp to [0, 1]: near antipodes raw_a can overshoot 1.0 (or undershoot
  // 0.0) in floating point, which would make (1 - a).sqrt() NaN (P1-1).
  let a = if raw_a < 0.0 { 0.0 } else if raw_a > 1.0 { 1.0 } else { raw_a }
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
  let prefix : Array[Double] = [0.0]
  for altitude in alts {
    prefix.push(prefix[prefix.length() - 1] + altitude)
  }
  let smooth : Array[Double] = []
  let mut i = 0
  while i < alts.length() {
    let start = if i - win + 1 > 0 { i - win + 1 } else { 0 }
    let n = i - start + 1
    smooth.push((prefix[i + 1] - prefix[start]) / n.to_double())
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
fn round_i64(x : Double) -> Int64 {
  @math.floor(x + 0.5).to_int64()
}

///|
// Per-km splits with linear interpolation between adjacent valid points.
// Starts at the first valid distance (so a trimmed track does not backfill
// kilometres 1..N), and uses the previous *boundary* time as the next split's
// start. Splits are elapsed-time (wall clock) basis: they include auto-pause;
// see split_basis and docs/metrics.md.
let max_total_distance_m : Double = 1000000.0

///|
let max_jump_m : Double = 100000.0

///|
// Per-km splits with linear interpolation; see docs/metrics.md. Returns splits
// plus a truncation flag: distance beyond max_total_distance_m or a single jump
// beyond max_jump_m stops generation and sets the flag (never silent), bounding
// work so a hostile uint32 distance cannot cause O(distance) objects.
fn splits(points : Array[@model.TrackPoint]) -> (Array[Split], Bool) {
  let out : Array[Split] = []
  let mut truncated = false
  let mut initialized = false
  let mut prev_d = 0.0
  let mut prev_t = 0L
  let mut next_km = 0
  let mut last_boundary_t = 0L
  for p in points {
    match p.distance_m {
      Some(d) => {
        if d > max_total_distance_m {
          truncated = true
          break
        }
        if !initialized {
          prev_d = d
          prev_t = p.timestamp
          next_km = @math.floor(d / 1000.0).to_int() + 1
          last_boundary_t = p.timestamp
          initialized = true
        } else if d < prev_d || p.timestamp < prev_t {
          // A reset or clock reversal cannot be interpolated against the old
          // segment. Start a new local segment at the current observation.
          prev_d = d
          prev_t = p.timestamp
          next_km = @math.floor(d / 1000.0).to_int() + 1
          last_boundary_t = p.timestamp
        } else if d == prev_d {
          // A distance plateau belongs to the latest timestamp. If the next
          // point crosses a boundary, interpolation starts at this point.
          prev_t = p.timestamp
        } else if d - prev_d > max_jump_m {
          truncated = true
          break
        } else {
          while next_km.to_double() * 1000.0 <= d {
            let ratio = (next_km.to_double() * 1000.0 - prev_d) / (d - prev_d)
            let boundary_t = prev_t +
              round_i64(ratio * (p.timestamp - prev_t).to_double())
            let split_time = boundary_t - last_boundary_t
            if split_time < 0L {
              truncated = true
              break
            }
            out.push({
              index: next_km,
              end_distance_m: next_km.to_double() * 1000.0,
              time_s: split_time,
            })
            last_boundary_t = boundary_t
            next_km = next_km + 1
          }
          if truncated {
            break
          }
          prev_d = d
          prev_t = p.timestamp
        }
      }
      None => ()
    }
  }
  (out, truncated)
}

///|
pub fn compute(
  act : @model.Activity,
  hr_bounds : Array[Int32],
  ascent_window : Int32,
) -> Metrics {
  let gps = gps_distance(act.points)
  let avg_speed = if act.timer_s > 0.0 {
    act.device_distance_m / act.timer_s
  } else {
    0.0
  }
  let gps_avg_speed = if act.timer_s > 0.0 { gps / act.timer_s } else { 0.0 }
  let pace = if avg_speed > 0.0 { 1000.0 / avg_speed / 60.0 } else { 0.0 }
  let (sp, sp_trunc) = splits(act.points)
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
    gps_avg_speed_mps: gps_avg_speed,
    avg_pace_min_per_km: pace,
    device_ascent_m: act.device_ascent_m,
    device_descent_m: act.device_descent_m,
    computed_ascent_m: computed_ascent(alts, ascent_window),
    hr_zones: hr_zones(act.points, hr_bounds),
    splits: sp,
    split_basis: "elapsed",
    splits_truncated: sp_trunc,
  }
} ///|

///|
pub fn to_json(m : Metrics) -> String {
  let zparts : Array[String] = []
  for z in m.hr_zones {
    let lo = match z.lower {
      Some(v) => v.to_string()
      None => "null"
    }
    let hi = match z.upper {
      Some(v) => v.to_string()
      None => "null"
    }
    zparts.push(
      "{\"lower\":" +
      lo +
      ",\"upper\":" +
      hi +
      ",\"seconds\":" +
      z.seconds.to_string() +
      "}",
    )
  }
  let sparts : Array[String] = []
  for s in m.splits {
    sparts.push(
      "{\"index\":" +
      s.index.to_string() +
      ",\"end_distance_m\":" +
      @json.json_double(s.end_distance_m) +
      ",\"time_s\":" +
      s.time_s.to_string() +
      "}",
    )
  }
  "{\"device_distance_m\":" +
  @json.json_double(m.device_distance_m) +
  ",\"gps_distance_m\":" +
  @json.json_double(m.gps_distance_m) +
  ",\"elapsed_s\":" +
  @json.json_double(m.elapsed_s) +
  ",\"timer_s\":" +
  @json.json_double(m.timer_s) +
  ",\"moving_s\":" +
  @json.json_double(m.moving_s) +
  ",\"avg_speed_mps\":" +
  @json.json_double(m.avg_speed_mps) +
  ",\"gps_avg_speed_mps\":" +
  @json.json_double(m.gps_avg_speed_mps) +
  ",\"avg_pace_min_per_km\":" +
  @json.json_double(m.avg_pace_min_per_km) +
  ",\"device_ascent_m\":" +
  @json.json_double(m.device_ascent_m) +
  ",\"device_descent_m\":" +
  @json.json_double(m.device_descent_m) +
  ",\"computed_ascent_m\":" +
  @json.json_double(m.computed_ascent_m) +
  ",\"hr_zones\":[" +
  zparts.join(",") +
  "]" +
  ",\"splits\":[" +
  sparts.join(",") +
  "]" +
  ",\"split_basis\":\"" +
  m.split_basis +
  "\"" +
  ",\"splits_truncated\":" +
  (if m.splits_truncated { "true" } else { "false" }) +
  "}"
}
