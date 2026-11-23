///|
// Spec-derived format fidelity model. For each target export format the
// capability matrix lists FIT semantics that the format's OWN schema cannot
// represent, or can only represent via an extension / at reduced precision.
// Every entry cites the format specification, not a vendor export observation:
// vendor-specific export behaviour (point subsampling, omitted heart rate, ...)
// is recorded separately in docs/spec-notes.md and is deliberately excluded
// here, because a vendor export choice is not a format limitation.

///|
#derive(Eq, Debug)
pub(all) struct Loss {
  semantic : String
  kind : String
  spec : String
}

///|
pub extend Loss with Eq::{not_equal, equal}

///|
pub extend Loss with @debug.Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct FidelityReport {
  target : String
  record_count : Int32
  pause_lost_s : Double
  losses : Array[Loss]
}

///|
pub extend FidelityReport with Eq::{not_equal, equal}

///|
pub extend FidelityReport with @debug.Debug::{to_repr}

///|
fn loss(semantic : String, kind : String, spec : String) -> Loss {
  { semantic, kind, spec, }
}

///|
pub fn losses(target : String) -> Array[Loss]? {
  match target {
    "tcx" =>
      Some([
        loss(
          "auto_pause", "unrepresentable", "TCX v2 XSD: no timer/pause event; Lap/TotalTimeSeconds is timer time",
        ),
        loss(
          "device_serial", "unrepresentable", "TCX v2 XSD: no device serial field",
        ),
        loss(
          "coord_precision", "degraded", "TCX v2 XSD: Position/LatitudeDegrees,LongitudeDegrees are decimal degrees",
        ),
        loss(
          "enhanced_altitude", "degraded", "TCX v2 XSD: AltitudeMeters only; no enhanced_altitude field",
        ),
        loss("speed", "extension_required", "TCX v2 TPX extension: Speed"),
        loss("power", "extension_required", "TCX v2 TPX extension: Watts"),
        loss(
          "temperature", "extension_required", "TCX v2 TPX extension: Temperature",
        ),
      ])
    "gpx" =>
      Some([
        loss(
          "auto_pause", "unrepresentable", "GPX 1.1 XSD: no timer/pause element",
        ),
        loss(
          "device_serial", "unrepresentable", "GPX 1.1 XSD: no device serial element",
        ),
        loss(
          "coord_precision", "degraded", "GPX 1.1 XSD: trkpt lat/lon are decimal-degree attributes",
        ),
        loss(
          "heart_rate", "extension_required", "GPX 1.1: gpxtpx TrackPointExtension hr",
        ),
        loss(
          "cadence", "extension_required", "GPX 1.1: gpxtpx TrackPointExtension cad",
        ),
        loss(
          "power", "extension_required", "GPX 1.1: gpxtpx TrackPointExtension power",
        ),
        loss(
          "speed", "extension_required", "GPX 1.1: gpxtpx TrackPointExtension speed",
        ),
        loss(
          "temperature", "extension_required", "GPX 1.1: gpxtpx TrackPointExtension atemp",
        ),
        loss(
          "distance", "unrepresentable", "GPX 1.1 XSD: no cumulative distance element",
        ),
      ])
    "kml" =>
      Some([
        loss("auto_pause", "unrepresentable", "KML 2.2: no timer/pause element"),
        loss(
          "device_serial", "unrepresentable", "KML 2.2: no device serial element",
        ),
        loss(
          "coord_precision", "degraded", "KML 2.2: coordinates are a decimal-degree tuple",
        ),
        loss(
          "heart_rate", "unrepresentable", "KML 2.2: no structured per-point heart rate (ExtendedData only)",
        ),
        loss(
          "cadence", "unrepresentable", "KML 2.2: no structured per-point cadence",
        ),
        loss(
          "power", "unrepresentable", "KML 2.2: no structured per-point power",
        ),
        loss(
          "speed", "unrepresentable", "KML 2.2: no structured per-point speed",
        ),
        loss(
          "distance", "unrepresentable", "KML 2.2: no cumulative distance element",
        ),
        loss(
          "temperature", "unrepresentable", "KML 2.2: no structured per-point temperature",
        ),
      ])
    _ => None
  }
}

///|
pub fn report(act : @model.Activity, target : String) -> FidelityReport? {
  match losses(target) {
    Some(ls) => {
      let pause = act.elapsed_s - act.timer_s
      Some({
        target,
        record_count: act.points.length(),
        pause_lost_s: if pause < 0.0 {
          0.0
        } else {
          pause
        },
        losses: ls,
      })
    }
    None => None
  }
}

///|
pub fn to_json(r : FidelityReport) -> String {
  let mut lj = ""
  let mut i = 0
  for l in r.losses {
    if i > 0 {
      lj = lj + ","
    }
    lj = lj +
      "{\"semantic\":" +
      @json.json_string(l.semantic) +
      ",\"kind\":" +
      @json.json_string(l.kind) +
      ",\"spec\":" +
      @json.json_string(l.spec) +
      "}"
    i = i + 1
  }
  "{\"target\":" +
  @json.json_string(r.target) +
  ",\"record_count\":" +
  r.record_count.to_string() +
  ",\"pause_lost_s\":" +
  @json.json_double(r.pause_lost_s) +
  ",\"losses\":[" +
  lj +
  "]}"
}
