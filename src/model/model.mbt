///|
// The canonical activity model. Every value is extracted from the FIT record
// stream into native units (metres, seconds, m/s, degrees) with invalid fields
// represented as None, so downstream metrics never see a sentinel. Provenance
// is kept by construction: each field maps to a fixed (global, def_num) pair,
// documented beside the extractor.

///|
#derive(Eq, Debug)
pub(all) struct TrackPoint {
  timestamp : Int64
  lat : Double?
  lon : Double?
  altitude_m : Double?
  distance_m : Double?
  speed_mps : Double?
  heart_rate : Int32?
  cadence : Int32?
  temperature : Int32?
}

///|
pub extend TrackPoint with Eq::{not_equal, equal}

///|
pub extend TrackPoint with @debug.Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Lap {
  start_time : Int64
  elapsed_s : Double
  timer_s : Double
  distance_m : Double
  ascent_m : Double
  descent_m : Double
  avg_hr : Int32?
  max_hr : Int32?
}

///|
pub extend Lap with Eq::{not_equal, equal}

///|
pub extend Lap with @debug.Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Activity {
  sport : String
  sub_sport : String
  start_time : Int64
  points : Array[TrackPoint]
  laps : Array[Lap]
  device_distance_m : Double
  elapsed_s : Double
  timer_s : Double
  moving_s : Double
  device_ascent_m : Double
  device_descent_m : Double
  avg_hr : Int32?
  max_hr : Int32?
}

///|
pub extend Activity with Eq::{not_equal, equal}

///|
pub extend Activity with @debug.Debug::{to_repr}

///|
fn fv(m : @fit.DataMessage, def : Int32) -> @fit.FieldValue? {
  for f in m.fields {
    if f.def_num == def {
      return Some(f)
    }
  }
  None
}

///|
fn int_opt(m : @fit.DataMessage, def : Int32) -> Int64? {
  match fv(m, def) {
    Some(f) =>
      if f.invalid {
        None
      } else {
        match f.value {
          @fit.Signed(v) => Some(v)
          @fit.Unsigned(v) => Some(v.reinterpret_as_int64())
          _ => None
        }
      }
    None => None
  }
}

///|
fn i32_opt(m : @fit.DataMessage, def : Int32) -> Int32? {
  match int_opt(m, def) {
    Some(v) => Some(v.to_int())
    None => None
  }
}

///|
fn degrees_opt(m : @fit.DataMessage, def : Int32) -> Double? {
  match int_opt(m, def) {
    Some(v) =>
      Some(
        @units.degrees_value(@units.degrees_of_semicircle(@units.semicircle(v))),
      )
    None => None
  }
}

///|
fn altitude_opt(m : @fit.DataMessage, def : Int32) -> Double? {
  match int_opt(m, def) {
    Some(v) =>
      Some(
        @units.metre_value(
          @units.metre_of_decimetre(
            @units.decimetre_of_altitude_raw(@units.altitude_raw(v)),
          ),
        ),
      )
    None => None
  }
}

///|
fn metres_opt(m : @fit.DataMessage, def : Int32) -> Double? {
  match int_opt(m, def) {
    Some(v) =>
      Some(@units.metre_value(@units.metre_of_centimetre(@units.centimetre(v))))
    None => None
  }
}

///|
fn speed_opt(m : @fit.DataMessage, def : Int32) -> Double? {
  match int_opt(m, def) {
    Some(v) =>
      Some(
        @units.metre_per_second_value(
          @units.metre_per_second_of_millimetre_per_second(
            @units.millimetre_per_second(v),
          ),
        ),
      )
    None => None
  }
}

///|
fn seconds(m : @fit.DataMessage, def : Int32) -> Double {
  match int_opt(m, def) {
    Some(v) =>
      @units.second_value(@units.second_of_millisecond(@units.millisecond(v)))
    None => 0.0
  }
}

///|
fn sport_name(code : Int64) -> String {
  match code {
    0L => "generic"
    1L => "running"
    2L => "cycling"
    5L => "swimming"
    11L => "walking"
    17L => "hiking"
    _ => "sport(\{code})"
  }
}

///|
fn sub_sport_name(code : Int64) -> String {
  match code {
    0L => "generic"
    1L => "treadmill"
    2L => "street"
    3L => "trail"
    4L => "track"
    5L => "spin"
    6L => "indoor_cycling"
    7L => "road"
    8L => "mountain"
    9L => "downhill"
    10L => "recumbent"
    11L => "cyclocross"
    12L => "hand_cycling"
    13L => "track_cycling"
    14L => "indoor_rowing"
    15L => "elliptical"
    _ => "other"
  }
}

///|
fn track_point(m : @fit.DataMessage) -> TrackPoint {
  {
    timestamp: match m.timestamp {
      Some(v) => v
      None =>
        match int_opt(m, 253) {
          Some(v) => v
          None => 0L
        }
    },
    lat: degrees_opt(m, 0),
    lon: degrees_opt(m, 1),
    altitude_m: altitude_opt(m, 2),
    distance_m: metres_opt(m, 5),
    speed_mps: speed_opt(m, 6),
    heart_rate: i32_opt(m, 3),
    cadence: i32_opt(m, 4),
    temperature: i32_opt(m, 13),
  }
}

///|
fn lap(m : @fit.DataMessage) -> Lap {
  {
    start_time: match int_opt(m, 2) {
      Some(v) => v
      None => 0L
    },
    elapsed_s: seconds(m, 7),
    timer_s: seconds(m, 8),
    distance_m: match metres_opt(m, 9) {
      Some(v) => v
      None => 0.0
    },
    ascent_m: match int_opt(m, 21) {
      Some(v) => v.to_double()
      None => 0.0
    },
    descent_m: match int_opt(m, 22) {
      Some(v) => v.to_double()
      None => 0.0
    },
    avg_hr: i32_opt(m, 15),
    max_hr: i32_opt(m, 16),
  }
}

///|
pub fn from_fit(msgs : Array[@fit.Message]) -> Activity raise @fit.FitError {
  let data = @fit.data_messages(msgs)
  let mut session : @fit.DataMessage? = None
  let points : Array[TrackPoint] = []
  let laps : Array[Lap] = []
  for m in data {
    match m.global {
      18 => if session == None { session = Some(m) }
      20 => points.push(track_point(m))
      19 => laps.push(lap(m))
      _ => ()
    }
  }
  let s = match session {
    Some(v) => v
    None => raise @fit.FitError::Truncated("activity has no session message")
  }
  {
    sport: sport_name(
      match int_opt(s, 5) {
        Some(v) => v
        None => 0L
      },
    ),
    sub_sport: sub_sport_name(
      match int_opt(s, 6) {
        Some(v) => v
        None => 0L
      },
    ),
    start_time: match int_opt(s, 2) {
      Some(v) => v
      None => 0L
    },
    points,
    laps,
    device_distance_m: match metres_opt(s, 9) {
      Some(v) => v
      None => 0.0
    },
    elapsed_s: seconds(s, 7),
    timer_s: seconds(s, 8),
    moving_s: seconds(s, 59),
    device_ascent_m: match int_opt(s, 22) {
      Some(v) => v.to_double()
      None => 0.0
    },
    device_descent_m: match int_opt(s, 23) {
      Some(v) => v.to_double()
      None => 0.0
    },
    avg_hr: i32_opt(s, 16),
    max_hr: i32_opt(s, 17),
  }
}
