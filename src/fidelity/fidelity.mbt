///|
// Spec-derived format fidelity model. This package reports the expected result
// of a named conversion profile. It does not write TCX, GPX, or KML files.
// Vendor export behaviour is deliberately excluded from this model.

///|
#derive(Eq, Debug)
pub(all) struct Loss {
  semantic : String
  source_unit : String
  representation : String
  status : String
  policy : String
  max_error : Double
  reversible : Bool
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
  profile : String
  analysis_only : Bool
  writer_available : Bool
  record_count : Int32
  pause_lost_s : Double
  latitude_deg : Double
  coordinate_digits : Int32
  max_angle_error_deg : Double
  max_equator_error_m : Double
  max_longitude_error_m : Double
  losses : Array[Loss]
}

///|
pub extend FidelityReport with Eq::{not_equal, equal}

///|
pub extend FidelityReport with @debug.Debug::{to_repr}

///|
pub fn is_profile(profile : String) -> Bool {
  profile == "portable-core" ||
  profile == "standard-extended" ||
  profile == "loss-minimal"
}

///|
fn loss(
  semantic : String,
  source_unit : String,
  representation : String,
  status : String,
  policy : String,
  spec : String,
) -> Loss {
  {
    semantic,
    source_unit,
    representation,
    status,
    policy,
    max_error: 0.0,
    reversible: status == "exact" || status == "extension_preserved",
    spec,
  }
}

///|
fn coord_loss(target : String, profile : String) -> Loss {
  let extended = profile != "portable-core"
  let minimal = profile == "loss-minimal"
  loss(
    "coord_precision",
    "FIT semicircle",
    if minimal {
      "moonfit:raw_semicircle"
    } else {
      "LatitudeDegrees/LongitudeDegrees"
    },
    if minimal {
      "extension_preserved"
    } else {
      "rounded"
    },
    if minimal {
      "write raw semicircle in a named moonfit extension"
    } else if extended {
      "write decimal degrees with 9 fractional digits"
    } else {
      "write decimal degrees with 7 fractional digits"
    },
    match target {
      "tcx" => "TCX v2 XSD: Position/LatitudeDegrees and LongitudeDegrees"
      "gpx" => "GPX 1.1 XSD: trkpt lat/lon decimal-degree attributes"
      _ => "OGC KML 2.2 schema: coordinates are decimal-degree tuples"
    },
  )
}

///|
fn extended_status(profile : String) -> String {
  if profile == "portable-core" {
    "omitted"
  } else {
    "extension_preserved"
  }
}

///|
fn losses_for(target : String, profile : String) -> Array[Loss]? {
  if !is_profile(profile) {
    return None
  }
  let ext = extended_status(profile)
  let minimal = profile == "loss-minimal"
  match target {
    "tcx" => {
      let ls : Array[Loss] = [
        coord_loss(target, profile),
        loss(
          "auto_pause",
          "seconds",
          if minimal {
            "moonfit:auto_pause"
          } else {
            "TCX Lap/TotalTimeSeconds"
          },
          if minimal {
            "extension_preserved"
          } else {
            "omitted"
          },
          if minimal {
            "write pause intervals in a named moonfit extension"
          } else {
            "do not infer elapsed time from timer time"
          },
          "TCX v2 XSD: no pause event element",
        ),
        loss(
          "elapsed",
          "seconds",
          if minimal {
            "moonfit:elapsed_s"
          } else {
            "TCX Lap/TotalTimeSeconds"
          },
          if minimal {
            "extension_preserved"
          } else {
            "omitted"
          },
          "preserve wall-clock duration only in the loss-minimal profile",
          "TCX v2 XSD: Lap/TotalTimeSeconds is the available lap duration field",
        ),
        loss(
          "timer", "seconds", "Lap/TotalTimeSeconds", "exact", "write FIT timer seconds as the TCX lap duration",
          "TCX v2 XSD: Lap/TotalTimeSeconds",
        ),
        loss(
          "device_serial", "serial", "omitted", "omitted", "drop device identity for privacy",
          "TCX v2 XSD: no device serial element",
        ),
        loss(
          "enhanced_altitude", "metres", "AltitudeMeters", "exact", "convert FIT enhanced altitude metres to the TCX core altitude element",
          "TCX v2 XSD: AltitudeMeters is the core altitude element",
        ),
        loss(
          "heart_rate", "bpm", "HeartRateBpm/Value", "exact", "write the core heart-rate element",
          "TCX v2 XSD: HeartRateBpm/Value",
        ),
        loss(
          "speed", "m/s", "TPX/Speed", ext, "use the TCX TPX extension when enabled",
          "TCX v2 TPX extension: Speed",
        ),
        loss(
          "power", "watts", "TPX/Watts", ext, "use the TCX TPX extension when enabled",
          "TCX v2 TPX extension: Watts",
        ),
        loss(
          "temperature", "degrees", "TPX/Temperature", ext, "use the TCX TPX extension when enabled",
          "TCX v2 TPX extension: Temperature",
        ),
        loss(
          "distance", "metres", "Lap/DistanceMeters", "exact", "write the activity distance on the lap",
          "TCX v2 XSD: Lap/DistanceMeters",
        ),
      ]
      Some(ls)
    }
    "gpx" => {
      let ls : Array[Loss] = [
        coord_loss(target, profile),
        loss(
          "auto_pause",
          "seconds",
          if minimal {
            "moonfit:auto_pause"
          } else {
            "omitted"
          },
          if minimal {
            "extension_preserved"
          } else {
            "omitted"
          },
          "preserve pause intervals only in the named extension profile",
          "GPX 1.1 XSD: no timer/pause element",
        ),
        loss(
          "elapsed",
          "seconds",
          if minimal {
            "moonfit:elapsed_s"
          } else {
            "omitted"
          },
          if minimal {
            "extension_preserved"
          } else {
            "omitted"
          },
          "preserve elapsed time only in the named extension profile",
          "GPX 1.1 XSD: no activity duration element",
        ),
        loss(
          "timer",
          "seconds",
          if minimal {
            "moonfit:timer_s"
          } else {
            "omitted"
          },
          if minimal {
            "extension_preserved"
          } else {
            "omitted"
          },
          "preserve timer time only in the named extension profile",
          "GPX 1.1 XSD: no timer element",
        ),
        loss(
          "device_serial", "serial", "omitted", "omitted", "drop device identity for privacy",
          "GPX 1.1 XSD: no device serial element",
        ),
        loss(
          "enhanced_altitude", "metres", "ele", "exact", "convert FIT enhanced altitude metres to the GPX core ele element",
          "GPX 1.1 XSD: ele is the core elevation element",
        ),
        loss(
          "heart_rate", "bpm", "gpxtpx:hr", ext, "use TrackPointExtension when enabled",
          "GPX TrackPointExtension schema: hr",
        ),
        loss(
          "cadence", "rpm", "gpxtpx:cad", ext, "use TrackPointExtension when enabled",
          "GPX TrackPointExtension schema: cad",
        ),
        loss(
          "power", "watts", "gpxtpx:power", ext, "use TrackPointExtension when enabled",
          "GPX TrackPointExtension schema: power",
        ),
        loss(
          "speed", "m/s", "gpxtpx:speed", ext, "use TrackPointExtension when enabled",
          "GPX TrackPointExtension schema: speed",
        ),
        loss(
          "temperature", "degrees", "gpxtpx:atemp", ext, "use TrackPointExtension when enabled",
          "GPX TrackPointExtension schema: atemp",
        ),
        loss(
          "distance",
          "metres",
          if minimal {
            "moonfit:distance_m"
          } else if profile == "standard-extended" {
            "named:distance_m"
          } else {
            "omitted"
          },
          if profile == "portable-core" {
            "omitted"
          } else {
            "extension_preserved"
          },
          "retain cumulative distance through a named extension when enabled",
          "GPX 1.1 XSD: no cumulative distance element",
        ),
      ]
      Some(ls)
    }
    "kml" => {
      let ls : Array[Loss] = [
        coord_loss(target, profile),
        loss(
          "auto_pause",
          "seconds",
          if minimal {
            "moonfit:auto_pause"
          } else {
            "ExtendedData:auto_pause"
          },
          ext,
          "use an explicit ExtendedData key when enabled",
          "OGC KML 2.2 schema: ExtendedData is the application-data container",
        ),
        loss(
          "elapsed",
          "seconds",
          if minimal {
            "moonfit:elapsed_s"
          } else {
            "ExtendedData:elapsed_s"
          },
          ext,
          "use an explicit ExtendedData key when enabled",
          "OGC KML 2.2 schema: ExtendedData is the application-data container",
        ),
        loss(
          "timer",
          "seconds",
          if minimal {
            "moonfit:timer_s"
          } else {
            "ExtendedData:timer_s"
          },
          ext,
          "use an explicit ExtendedData key when enabled",
          "OGC KML 2.2 schema: ExtendedData is the application-data container",
        ),
        loss(
          "device_serial", "serial", "omitted", "omitted", "drop device identity for privacy",
          "OGC KML 2.2 schema: no structured device serial field",
        ),
        loss(
          "enhanced_altitude", "metres", "coordinates altitude tuple", "exact", "write enhanced altitude as the third KML coordinate value",
          "OGC KML 2.2 schema: altitude is part of the coordinate tuple",
        ),
        loss(
          "heart_rate", "bpm", "ExtendedData:heart_rate", ext, "use an explicit ExtendedData key when enabled",
          "OGC KML 2.2 schema: ExtendedData is the application-data container",
        ),
        loss(
          "cadence", "rpm", "ExtendedData:cadence", ext, "use an explicit ExtendedData key when enabled",
          "OGC KML 2.2 schema: ExtendedData is the application-data container",
        ),
        loss(
          "power", "watts", "ExtendedData:power", ext, "use an explicit ExtendedData key when enabled",
          "OGC KML 2.2 schema: ExtendedData is the application-data container",
        ),
        loss(
          "speed", "m/s", "ExtendedData:speed", ext, "use an explicit ExtendedData key when enabled",
          "OGC KML 2.2 schema: ExtendedData is the application-data container",
        ),
        loss(
          "distance", "metres", "ExtendedData:distance_m", ext, "use an explicit ExtendedData key when enabled",
          "OGC KML 2.2 schema: ExtendedData is the application-data container",
        ),
        loss(
          "temperature", "degrees", "ExtendedData:temperature", ext, "use an explicit ExtendedData key when enabled",
          "OGC KML 2.2 schema: ExtendedData is the application-data container",
        ),
      ]
      Some(ls)
    }
    _ => None
  }
}

///|
pub fn losses(target : String) -> Array[Loss]? {
  losses_for(target, "portable-core")
}

///|
fn mean_latitude(points : Array[@model.TrackPoint]) -> Double {
  let mut sum = 0.0
  let mut n = 0
  for p in points {
    match p.lat {
      Some(lat) => {
        sum = sum + lat
        n = n + 1
      }
      None => ()
    }
  }
  if n == 0 {
    0.0
  } else {
    sum / n.to_double()
  }
}

///|
fn coordinate_digits(profile : String) -> Int32 {
  match profile {
    "portable-core" => 7
    "standard-extended" => 9
    _ => 0
  }
}

///|
fn coordinate_error_deg(profile : String) -> Double {
  match profile {
    "portable-core" => 0.00000005
    "standard-extended" => 0.0000000005
    _ => 0.0
  }
}

///|
fn with_coordinate_error(
  ls : Array[Loss],
  profile : String,
  angle_error : Double,
) -> Array[Loss] {
  let out : Array[Loss] = []
  for l in ls {
    if l.semantic == "coord_precision" {
      out.push({
        ..l,
        max_error: angle_error,
        reversible: profile == "loss-minimal",
      })
    } else {
      out.push(l)
    }
  }
  out
}

///|
pub fn report_with_profile(
  act : @model.Activity,
  target : String,
  profile : String,
) -> FidelityReport? {
  match losses_for(target, profile) {
    Some(base) => {
      let pause = act.elapsed_s - act.timer_s
      let angle_error = coordinate_error_deg(profile)
      let lat = mean_latitude(act.points)
      let equator = angle_error * 111319.49079327357
      let longitude = equator * @math.cos(lat * 3.141592653589793 / 180.0)
      Some({
        target,
        profile,
        analysis_only: true,
        writer_available: false,
        record_count: act.points.length(),
        pause_lost_s: if pause < 0.0 {
          0.0
        } else {
          pause
        },
        latitude_deg: lat,
        coordinate_digits: coordinate_digits(profile),
        max_angle_error_deg: angle_error,
        max_equator_error_m: equator,
        max_longitude_error_m: longitude,
        losses: with_coordinate_error(base, profile, angle_error),
      })
    }
    None => None
  }
}

///|
pub fn report(act : @model.Activity, target : String) -> FidelityReport? {
  report_with_profile(act, target, "portable-core")
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
      ",\"source_unit\":" +
      @json.json_string(l.source_unit) +
      ",\"representation\":" +
      @json.json_string(l.representation) +
      ",\"status\":" +
      @json.json_string(l.status) +
      ",\"policy\":" +
      @json.json_string(l.policy) +
      ",\"max_error\":" +
      @json.json_double(l.max_error) +
      ",\"reversible\":" +
      (if l.reversible { "true" } else { "false" }) +
      ",\"spec\":" +
      @json.json_string(l.spec) +
      "}"
    i = i + 1
  }
  "{\"target\":" +
  @json.json_string(r.target) +
  ",\"profile\":" +
  @json.json_string(r.profile) +
  ",\"analysis_only\":" +
  (if r.analysis_only { "true" } else { "false" }) +
  ",\"writer_available\":" +
  (if r.writer_available { "true" } else { "false" }) +
  ",\"record_count\":" +
  r.record_count.to_string() +
  ",\"pause_lost_s\":" +
  @json.json_double(r.pause_lost_s) +
  ",\"latitude_deg\":" +
  @json.json_double(r.latitude_deg) +
  ",\"coordinate_digits\":" +
  r.coordinate_digits.to_string() +
  ",\"max_angle_error_deg\":" +
  @json.json_double(r.max_angle_error_deg) +
  ",\"max_equator_error_m\":" +
  @json.json_double(r.max_equator_error_m) +
  ",\"max_longitude_error_m\":" +
  @json.json_double(r.max_longitude_error_m) +
  ",\"losses\":[" +
  lj +
  "]}"
}
