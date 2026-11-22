///|
// TCX decoding into the canonical activity model.
//
// Tolerates a UTF-8 BOM and arbitrary namespace prefixes (matching on local
// names). Handles both vendor variants observed in the corpus: the rich
// iGPSPORT export (altitude/distance/TPX speed per trackpoint) and the minimal
// Huawei export (time+position only). The TCX schema defines Sport as
// Running|Biking|Other, but Huawei writes free text ("户外跑步"); such values are
// normalised to a canonical sport and flagged non-standard rather than rejected.
//
// Per the measured cross-format law L6, TCX Lap/TotalTimeSeconds equals the FIT
// total_timer_time (not elapsed); it is mapped to timer_s, and elapsed/moving
// are set equal because TCX carries no separate elapsed/pause information.

///|
pub(all) suberror TcxError {
  Malformed(String)
}

///|
#derive(Eq, Debug)
pub(all) struct TcxActivity {
  activity : @model.Activity
  sport_raw : String
  sport_nonstandard : Bool
}

///|
pub extend TcxActivity with Eq::{not_equal, equal}

///|
pub extend TcxActivity with @debug.Debug::{to_repr}

///|
fn local_name(q : String) -> String {
  let mut i = 0
  let mut start = 0
  for c in q {
    if c == ':' {
      start = i + 1
    }
    i = i + 1
  }
  let mut out = ""
  let mut j = 0
  for c in q {
    if j >= start {
      out = out + c.to_string()
    }
    j = j + 1
  }
  out
}

///|
fn to_int(s : String) -> Int64 {
  @string.parse_int64(s) catch {
    _ => 0L
  }
}

///|
fn parse_i64_strict(s : String) -> Int64 raise TcxError {
  @string.parse_int64(s) catch {
    _ => raise TcxError::Malformed("invalid integer: " + s)
  }
}

///|
fn parse_f64_strict(s : String) -> Double raise TcxError {
  let d = @string.parse_double(s) catch {
    _ => raise TcxError::Malformed("invalid number: " + s)
  }
  let inf = 1.0 / 0.0
  if d != d || d == inf || d == -inf {
    raise TcxError::Malformed("non-finite number: " + s)
  }
  d
}

///|
fn parse_i32_strict(s : String) -> Int32 raise TcxError {
  let v = parse_i64_strict(s)
  if v < -2147483648L || v > 2147483647L {
    raise TcxError::Malformed("integer out of int32 range: " + s)
  }
  v.to_int()
}

///|
fn parse_dist(s : String) -> Double raise TcxError {
  let d = parse_f64_strict(s)
  if d < 0.0 || d > 100000000.0 {
    raise TcxError::Malformed("distance out of range: " + s)
  }
  d
}

///|
fn parse_time(s : String) -> Double raise TcxError {
  let d = parse_f64_strict(s)
  if d < 0.0 || d > 1000000000.0 {
    raise TcxError::Malformed("time out of range: " + s)
  }
  d
}

///|
fn parse_lat(s : String) -> Double raise TcxError {
  let d = parse_f64_strict(s)
  if d < -90.0 || d > 90.0 {
    raise TcxError::Malformed("latitude out of range: " + s)
  }
  d
}

///|
fn parse_lon(s : String) -> Double raise TcxError {
  let d = parse_f64_strict(s)
  if d < -180.0 || d > 180.0 {
    raise TcxError::Malformed("longitude out of range: " + s)
  }
  d
}

///|
fn days_from_civil(y : Int64, m : Int64, d : Int64) -> Int64 {
  let yy = if m <= 2L { y - 1L } else { y }
  let era = (if yy >= 0L { yy } else { yy - 399L }) / 400L
  let yoe = yy - era * 400L
  let mp = if m > 2L { m - 3L } else { m + 9L }
  let doy = (153L * mp + 2L) / 5L + d - 1L
  let doe = yoe * 365L + yoe / 4L - yoe / 100L + doy
  era * 146097L + doe - 719468L
}

///|
// Parse "YYYY-MM-DDThh:mm:ss[.fff]Z" to FIT-epoch seconds.
fn parse_iso(s : String) -> Int64 {
  if s.length() < 19 {
    return 0L
  }
  let sub = fn(a : Int32, b : Int32) -> String {
    let mut out = ""
    let mut i = 0
    for c in s {
      if i >= a && i < b {
        out = out + c.to_string()
      }
      i = i + 1
    }
    out
  }
  let y = to_int(sub(0, 4))
  let mo = to_int(sub(5, 7))
  let d = to_int(sub(8, 10))
  let h = to_int(sub(11, 13))
  let mi = to_int(sub(14, 16))
  let se = to_int(sub(17, 19))
  let unix = days_from_civil(y, mo, d) * 86400L + h * 3600L + mi * 60L + se
  unix - 631065600L
}

///|
fn norm_sport(raw : String) -> (String, Bool) {
  match raw {
    "Biking" => ("cycling", false)
    "Running" => ("running", false)
    "Other" => ("other", false)
    "户外跑步" => ("running", true)
    "户外骑行" => ("cycling", true)
    _ => ("other", true)
  }
}

///|
pub fn parse(data : Bytes) -> TcxActivity raise TcxError {
  let view = if data.length() >= 3 &&
    data.at(0).to_int() == 0xEF &&
    data.at(1).to_int() == 0xBB &&
    data.at(2).to_int() == 0xBF {
    data.clamped_view(start=3)
  } else {
    data.clamped_view()
  }
  let text = @utf8.decode_lossy(view)
  let events = @xml.Reader::from_string(text).read_events_until_eof() catch {
    e => raise TcxError::Malformed(e.to_string())
  }
  let stack : Array[String] = []
  let mut sport_raw = ""
  let points : Array[@model.TrackPoint] = []
  let laps : Array[@model.Lap] = []
  let mut lap_start = 0L
  let mut lap_time = 0.0
  let mut lap_dist = 0.0
  let mut lap_avghr : Int32? = None
  let mut lap_maxhr : Int32? = None
  let mut tp_time = 0L
  let mut tp_lat : Double? = None
  let mut tp_lon : Double? = None
  let mut tp_alt : Double? = None
  let mut tp_dist : Double? = None
  let mut tp_speed : Double? = None
  let mut tp_hr : Int32? = None
  let mut tp_cad : Int32? = None
  let mut in_tp = false
  let mut activity_count = 0
  for e in events {
    match e.kind {
      @xml.Start(el) => {
        let ln = local_name(el.name)
        stack.push(ln)
        match ln {
          "Activity" => {
            activity_count = activity_count + 1
            if activity_count > 1 {
              raise TcxError::Malformed(
                "multiple Activity elements are not supported",
              )
            }
            sport_raw = match el.get("Sport") {
              Some(v) => v
              None => ""
            }
          }
          "Lap" => {
            lap_start = parse_iso(
              match el.get("StartTime") {
                Some(v) => v
                None => ""
              },
            )
            lap_time = 0.0
            lap_dist = 0.0
            lap_avghr = None
            lap_maxhr = None
          }
          "Trackpoint" => {
            in_tp = true
            tp_time = 0L
            tp_lat = None
            tp_lon = None
            tp_alt = None
            tp_dist = None
            tp_speed = None
            tp_hr = None
            tp_cad = None
          }
          _ => ()
        }
      }
      @xml.End(name) => {
        let ln = local_name(name)
        match ln {
          "Trackpoint" => {
            points.push({
              timestamp: tp_time,
              lat: tp_lat,
              lon: tp_lon,
              altitude_m: tp_alt,
              distance_m: tp_dist,
              speed_mps: tp_speed,
              heart_rate: tp_hr,
              cadence: tp_cad,
              temperature: None,
            })
            in_tp = false
          }
          "Lap" =>
            laps.push({
              start_time: lap_start,
              elapsed_s: lap_time,
              timer_s: lap_time,
              distance_m: lap_dist,
              ascent_m: 0.0,
              descent_m: 0.0,
              avg_hr: lap_avghr,
              max_hr: lap_maxhr,
            })
          _ => ()
        }
        let _ = stack.pop()
      }
      @xml.Text(t) => {
        let txt = t.trim().to_owned()
        if txt != "" && stack.length() > 0 {
          let top = stack[stack.length() - 1]
          let parent = if stack.length() > 1 {
            stack[stack.length() - 2]
          } else {
            ""
          }
          if in_tp {
            match top {
              "Time" => tp_time = parse_iso(txt)
              "LatitudeDegrees" => tp_lat = Some(parse_lat(txt))
              "LongitudeDegrees" => tp_lon = Some(parse_lon(txt))
              "AltitudeMeters" => tp_alt = Some(parse_f64_strict(txt))
              "DistanceMeters" => tp_dist = Some(parse_dist(txt))
              "Cadence" => tp_cad = Some(parse_i32_strict(txt))
              "Speed" => tp_speed = Some(parse_f64_strict(txt))
              "Value" =>
                if parent == "HeartRateBpm" {
                  tp_hr = Some(parse_i32_strict(txt))
                }
              _ => ()
            }
          } else {
            match top {
              "TotalTimeSeconds" => lap_time = parse_time(txt)
              "DistanceMeters" => lap_dist = parse_dist(txt)
              "Value" =>
                if parent == "AverageHeartRateBpm" {
                  lap_avghr = Some(parse_i32_strict(txt))
                } else if parent == "MaximumHeartRateBpm" {
                  lap_maxhr = Some(parse_i32_strict(txt))
                }
              _ => ()
            }
          }
        }
      }
      _ => ()
    }
  }
  let (sport, nonstandard) = norm_sport(sport_raw)
  let mut total_dist = 0.0
  let mut total_time = 0.0
  for l in laps {
    total_dist = total_dist + l.distance_m
    total_time = total_time + l.timer_s
  }
  let start = if laps.length() > 0 {
    laps[0].start_time
  } else if points.length() > 0 {
    points[0].timestamp
  } else {
    0L
  }
  {
    activity: {
      sport,
      sub_sport: "generic",
      start_time: start,
      points,
      laps,
      device_distance_m: total_dist,
      elapsed_s: total_time,
      timer_s: total_time,
      moving_s: total_time,
      device_ascent_m: 0.0,
      device_descent_m: 0.0,
      avg_hr: if laps.length() > 0 {
        laps[0].avg_hr
      } else {
        None
      },
      max_hr: if laps.length() > 0 {
        laps[0].max_hr
      } else {
        None
      },
    },
    sport_raw,
    sport_nonstandard: nonstandard,
  }
}
