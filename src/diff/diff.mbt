///|
// FIT vs TCX divergence report for the same activity.
//
// Encodes the measured cross-format laws as checkable facts: L1 (TCX point count
// equals FIT record count), L6 (TCX TotalTimeSeconds equals FIT timer_time, so
// the FIT elapsed-minus-timer pause is lost in TCX), plus altitude/HR presence,
// distance agreement, sport normalisation and timestamp alignment.

///|
#derive(Eq, Debug)
pub(all) struct Divergence {
  fit_points : Int32
  tcx_points : Int32
  points_equal : Bool
  fit_timer_s : Double
  tcx_timer_s : Double
  timer_equal : Bool
  fit_elapsed_s : Double
  tcx_elapsed_s : Double
  pause_lost_s : Double
  fit_distance_m : Double
  tcx_distance_m : Double
  distance_delta_m : Double
  fit_alt : Int32
  tcx_alt : Int32
  fit_hr : Int32
  tcx_hr : Int32
  sport_fit : String
  sport_tcx : String
  sport_equal : Bool
  tcx_sport_nonstandard : Bool
  first_ts_equal : Bool
  last_ts_equal : Bool
  swc_zero : Bool
  ne_swc_contradiction : Bool
}

///|
pub extend Divergence with Eq::{not_equal, equal}

///|
pub extend Divergence with @debug.Debug::{to_repr}

///|
fn count_alt(points : Array[@model.TrackPoint]) -> Int32 {
  let mut n = 0
  for p in points {
    if p.altitude_m != None {
      n = n + 1
    }
  }
  n
}

///|
fn count_hr(points : Array[@model.TrackPoint]) -> Int32 {
  let mut n = 0
  for p in points {
    if p.heart_rate != None {
      n = n + 1
    }
  }
  n
}

///|
fn first_ts(a : @model.Activity) -> Int64 {
  if a.points.length() > 0 {
    a.points[0].timestamp
  } else {
    0L
  }
}

///|
fn last_ts(a : @model.Activity) -> Int64 {
  if a.points.length() > 0 {
    a.points[a.points.length() - 1].timestamp
  } else {
    0L
  }
}

///|
fn nonzero(o : Double?) -> Bool {
  match o {
    Some(v) => v != 0.0
    None => false
  }
}

///|
pub fn compare(
  fit : @model.Activity,
  tcx : @model.Activity,
  tcx_nonstandard : Bool,
) -> Divergence {
  {
    fit_points: fit.points.length(),
    tcx_points: tcx.points.length(),
    points_equal: fit.points.length() == tcx.points.length(),
    fit_timer_s: fit.timer_s,
    tcx_timer_s: tcx.timer_s,
    timer_equal: fit.timer_s == tcx.timer_s,
    fit_elapsed_s: fit.elapsed_s,
    tcx_elapsed_s: tcx.elapsed_s,
    pause_lost_s: fit.elapsed_s - fit.timer_s,
    fit_distance_m: fit.device_distance_m,
    tcx_distance_m: tcx.device_distance_m,
    distance_delta_m: fit.device_distance_m - tcx.device_distance_m,
    fit_alt: count_alt(fit.points),
    tcx_alt: count_alt(tcx.points),
    fit_hr: count_hr(fit.points),
    tcx_hr: count_hr(tcx.points),
    sport_fit: fit.sport,
    sport_tcx: tcx.sport,
    sport_equal: fit.sport == tcx.sport,
    tcx_sport_nonstandard: tcx_nonstandard,
    first_ts_equal: first_ts(fit) == first_ts(tcx),
    last_ts_equal: last_ts(fit) == last_ts(tcx),
    swc_zero: fit.swc_lat == Some(0.0) && fit.swc_long == Some(0.0),
    ne_swc_contradiction: fit.swc_lat == Some(0.0) &&
    fit.swc_long == Some(0.0) &&
    (nonzero(fit.nec_lat) || nonzero(fit.nec_long)),
  }
}

///|
fn b(v : Bool) -> String {
  if v {
    "true"
  } else {
    "false"
  }
}

///|
pub fn to_json(d : Divergence) -> String {
  "{\"fit_points\":" +
  d.fit_points.to_string() +
  ",\"tcx_points\":" +
  d.tcx_points.to_string() +
  ",\"points_equal\":" +
  b(d.points_equal) +
  ",\"fit_timer_s\":" +
  @json.json_double(d.fit_timer_s) +
  ",\"tcx_timer_s\":" +
  @json.json_double(d.tcx_timer_s) +
  ",\"timer_equal\":" +
  b(d.timer_equal) +
  ",\"fit_elapsed_s\":" +
  @json.json_double(d.fit_elapsed_s) +
  ",\"tcx_elapsed_s\":" +
  @json.json_double(d.tcx_elapsed_s) +
  ",\"pause_lost_s\":" +
  @json.json_double(d.pause_lost_s) +
  ",\"fit_distance_m\":" +
  @json.json_double(d.fit_distance_m) +
  ",\"tcx_distance_m\":" +
  @json.json_double(d.tcx_distance_m) +
  ",\"distance_delta_m\":" +
  @json.json_double(d.distance_delta_m) +
  ",\"fit_alt\":" +
  d.fit_alt.to_string() +
  ",\"tcx_alt\":" +
  d.tcx_alt.to_string() +
  ",\"fit_hr\":" +
  d.fit_hr.to_string() +
  ",\"tcx_hr\":" +
  d.tcx_hr.to_string() +
  ",\"sport_fit\":\"" +
  d.sport_fit +
  "\"" +
  ",\"sport_tcx\":\"" +
  d.sport_tcx +
  "\"" +
  ",\"sport_equal\":" +
  b(d.sport_equal) +
  ",\"tcx_sport_nonstandard\":" +
  b(d.tcx_sport_nonstandard) +
  ",\"first_ts_equal\":" +
  b(d.first_ts_equal) +
  ",\"last_ts_equal\":" +
  b(d.last_ts_equal) +
  ",\"swc_zero\":" +
  b(d.swc_zero) +
  ",\"ne_swc_contradiction\":" +
  b(d.ne_swc_contradiction) +
  "}"
}
