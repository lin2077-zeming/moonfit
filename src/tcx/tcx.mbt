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
fn str_slice(s : String, a : Int32, b : Int32) -> String {
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

///|
fn is_digit_at(s : String, i : Int32) -> Bool {
  if i < 0 || i >= s.length() {
    false
  } else {
    let c = str_slice(s, i, i + 1)
    c >= "0" && c <= "9"
  }
}

///|
fn days_in_month(y : Int64, m : Int64) -> Int64 {
  match m {
    2L =>
      if y % 400L == 0L || (y % 4L == 0L && y % 100L != 0L) {
        29L
      } else {
        28L
      }
    4L | 6L | 9L | 11L => 30L
    _ => 31L
  }
}

///|
// Parse "YYYY-MM-DDThh:mm:ss[.fff](Z|+hh:mm|-hh:mm)" to FIT-epoch seconds
// (UTC). Invalid calendar and timezone values are rejected instead of being
// normalised into a different timestamp.
fn parse_iso(s : String) -> Int64 raise TcxError {
  if s.length() < 20 ||
    str_slice(s, 4, 5) != "-" ||
    str_slice(s, 7, 8) != "-" ||
    str_slice(s, 10, 11) != "T" ||
    str_slice(s, 13, 14) != ":" ||
    str_slice(s, 16, 17) != ":" {
    raise TcxError::Malformed("invalid ISO-8601 timestamp: " + s)
  }
  let y = parse_i64_strict(str_slice(s, 0, 4))
  let mo = parse_i64_strict(str_slice(s, 5, 7))
  let d = parse_i64_strict(str_slice(s, 8, 10))
  let h = parse_i64_strict(str_slice(s, 11, 13))
  let mi = parse_i64_strict(str_slice(s, 14, 16))
  let se = parse_i64_strict(str_slice(s, 17, 19))
  if mo < 1L ||
    mo > 12L ||
    d < 1L ||
    d > days_in_month(y, mo) ||
    h < 0L ||
    h > 23L ||
    mi < 0L ||
    mi > 59L ||
    se < 0L ||
    se > 59L {
    raise TcxError::Malformed("timestamp component out of range: " + s)
  }
  let mut k = 19
  if str_slice(s, k, k + 1) == "." {
    k = k + 1
    let start = k
    while k < s.length() && is_digit_at(s, k) {
      k = k + 1
    }
    if k == start {
      raise TcxError::Malformed("timestamp fraction is empty: " + s)
    }
  }
  if k >= s.length() {
    raise TcxError::Malformed("timestamp timezone is missing: " + s)
  }
  let zone = str_slice(s, k, k + 1)
  let mut offset_s = 0L
  if zone == "Z" {
    if k + 1 != s.length() {
      raise TcxError::Malformed("trailing data after timestamp: " + s)
    }
  } else if zone == "+" || zone == "-" {
    if k + 6 != s.length() ||
      str_slice(s, k + 3, k + 4) != ":" ||
      !is_digit_at(s, k + 1) ||
      !is_digit_at(s, k + 2) ||
      !is_digit_at(s, k + 4) ||
      !is_digit_at(s, k + 5) {
      raise TcxError::Malformed("invalid timestamp timezone: " + s)
    }
    let oh = parse_i64_strict(str_slice(s, k + 1, k + 3))
    let om = parse_i64_strict(str_slice(s, k + 4, k + 6))
    if oh > 23L || om > 59L {
      raise TcxError::Malformed("timestamp timezone out of range: " + s)
    }
    offset_s = (if zone == "+" { 1L } else { -1L }) * (oh * 3600L + om * 60L)
  } else {
    raise TcxError::Malformed("invalid timestamp timezone: " + s)
  }
  let unix = days_from_civil(y, mo, d) * 86400L + h * 3600L + mi * 60L + se
  unix - 631065600L - offset_s
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
  let mut lap_time_opt : Double? = None
  let mut lap_dist_opt : Double? = None
  let mut lap_first_ts : Int64? = None
  let mut lap_last_ts : Int64? = None
  let mut lap_first_dist : Double? = None
  let mut lap_last_dist : Double? = None
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
            lap_time_opt = None
            lap_dist_opt = None
            lap_first_ts = None
            lap_last_ts = None
            lap_first_dist = None
            lap_last_dist = None
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
            if lap_first_ts == None {
              lap_first_ts = Some(tp_time)
            }
            lap_last_ts = Some(tp_time)
            match tp_dist {
              Some(d) => {
                if lap_first_dist == None {
                  lap_first_dist = Some(d)
                }
                lap_last_dist = Some(d)
              }
              None => ()
            }
            in_tp = false
          }
          "Lap" => {
            let ldist = match lap_dist_opt {
              Some(d) => d
              None =>
                match (lap_first_dist, lap_last_dist) {
                  (Some(first), Some(last)) =>
                    if last >= first {
                      last - first
                    } else {
                      0.0
                    }
                  (None, Some(last)) => last
                  _ => 0.0
                }
            }
            let ltime = match lap_time_opt {
              Some(t) => t
              None =>
                match (lap_first_ts, lap_last_ts) {
                  (Some(a), Some(b)) => (b - a).to_double()
                  _ => 0.0
                }
            }
            laps.push({
              start_time: lap_start,
              elapsed_s: ltime,
              timer_s: ltime,
              distance_m: ldist,
              ascent_m: 0.0,
              descent_m: 0.0,
              avg_hr: lap_avghr,
              max_hr: lap_maxhr,
            })
          }
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
              "TotalTimeSeconds" => lap_time_opt = Some(parse_time(txt))
              "DistanceMeters" => lap_dist_opt = Some(parse_dist(txt))
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
  if activity_count != 1 {
    raise TcxError::Malformed("exactly one Activity element is required")
  }
  if laps.length() == 0 {
    raise TcxError::Malformed("at least one Lap element is required")
  }
  let (sport, nonstandard) = norm_sport(sport_raw)
  let mut total_dist = 0.0
  let mut total_time = 0.0
  for l in laps {
    total_dist = total_dist + l.distance_m
    total_time = total_time + l.timer_s
  }
  // Multi-lap HR: max over all laps; average weighted by lap timer time.
  let mut act_maxhr : Int32? = None
  let mut hr_weight = 0.0
  let mut hr_time = 0.0
  for l in laps {
    match l.max_hr {
      Some(v) =>
        act_maxhr = match act_maxhr {
          Some(m) => Some(if v > m { v } else { m })
          None => Some(v)
        }
      None => ()
    }
    match l.avg_hr {
      Some(v) => {
        hr_weight = hr_weight + v.to_double() * l.timer_s
        hr_time = hr_time + l.timer_s
      }
      None => ()
    }
  }
  let act_avghr : Int32? = if hr_time > 0.0 {
    Some((hr_weight / hr_time + 0.5).floor().to_int())
  } else if laps.length() > 0 {
    laps[0].avg_hr
  } else {
    None
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
      avg_hr: act_avghr,
      max_hr: act_maxhr,
      swc_lat: None,
      swc_long: None,
      nec_lat: None,
      nec_long: None,
    },
    sport_raw,
    sport_nonstandard: nonstandard,
  }
}
