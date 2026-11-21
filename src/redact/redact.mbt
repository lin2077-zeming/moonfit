///|
// Native FIT redaction: zero the device serial, shift coordinates by an exact
// integer number of semicircles, optionally trim leading/trailing record
// messages, and optionally strip heart rate. Operates on the parsed structure
// and re-encodes, so CRCs and the data-size header are recomputed. With trim=0,
// strip_hr=false and the corpus shift values this reproduces the committed
// redacted corpus byte-for-byte from the raw export.
//
// session.swc_lat/swc_long are deliberately NOT shifted: they are 0 in the raw
// export (defect B1) and that contradiction is evidence a gate asserts.
//
// redact_ex also returns a machine-readable report of what changed (P0-7).

///|
fn wrap32(v : Int64) -> Int64 {
  let m = v % 4294967296L
  let mm = if m < 0L { m + 4294967296L } else { m }
  if mm >= 2147483648L {
    mm - 4294967296L
  } else {
    mm
  }
}

///|
fn is_lat(global : Int32, def : Int32) -> Bool {
  (global == 20 && def == 0) ||
  (global == 18 && (def == 3 || def == 29)) ||
  (global == 19 && (def == 3 || def == 5))
}

///|
fn is_lon(global : Int32, def : Int32) -> Bool {
  (global == 20 && def == 1) ||
  (global == 18 && (def == 4 || def == 30)) ||
  (global == 19 && (def == 4 || def == 6))
}

///|
fn is_hr(global : Int32, def : Int32) -> Bool {
  (global == 20 && def == 3) ||
  (global == 18 && (def == 16 || def == 17 || def == 64)) ||
  (global == 19 && (def == 15 || def == 16 || def == 63))
}

///|
#derive(Eq, Debug)
pub(all) struct RedactReport {
  serial_zeroed : Int32
  lat_shifted : Int32
  lon_shifted : Int32
  hr_stripped : Int32
  trimmed_records : Int32
  fields_changed : Int32
  lat_delta : Int64
  lon_delta : Int64
}

///|
pub extend RedactReport with Eq::{not_equal, equal}

///|
pub extend RedactReport with @debug.Debug::{to_repr}

///|
pub fn report_json(r : RedactReport) -> String {
  "{\"serial_zeroed\":" +
  r.serial_zeroed.to_string() +
  ",\"lat_shifted\":" +
  r.lat_shifted.to_string() +
  ",\"lon_shifted\":" +
  r.lon_shifted.to_string() +
  ",\"hr_stripped\":" +
  r.hr_stripped.to_string() +
  ",\"trimmed_records\":" +
  r.trimmed_records.to_string() +
  ",\"fields_changed\":" +
  r.fields_changed.to_string() +
  ",\"lat_delta\":" +
  r.lat_delta.to_string() +
  ",\"lon_delta\":" +
  r.lon_delta.to_string() +
  "}"
}

///|
pub fn redact_ex(
  data : Bytes,
  trim : Int32,
  dlat : Int64,
  dlon : Int64,
  strip_hr : Bool,
) -> (Bytes, RedactReport) raise @fit.FitError {
  let h = @fit.parse_header(data)
  let msgs = @fit.parse_messages(data)
  let defs : Array[@fit.Definition?] = Array::make(16, None)
  let total_records = @fit.count_global(msgs, 20)
  let out : Array[@fit.Message] = []
  let mut rec_idx = 0
  let mut kept = 0
  let mut serial_zeroed = 0
  let mut lat_shifted = 0
  let mut lon_shifted = 0
  let mut hr_stripped = 0
  for m in msgs {
    match m {
      @fit.Def(d) => {
        defs[d.local_id] = Some(d)
        out.push(m)
      }
      @fit.Data(dm) => {
        let mut keep = true
        if dm.global == 20 {
          keep = rec_idx >= trim && rec_idx < total_records - trim
          rec_idx = rec_idx + 1
        }
        if keep {
          if dm.global == 20 {
            kept = kept + 1
          }
          let e = match defs[dm.local_id] {
            Some(d) => d.endian
            None => @fit.Little
          }
          let nf : Array[@fit.FieldValue] = []
          for f in dm.fields {
            let mut raw = f.raw
            if (dm.global == 0 || dm.global == 23) && f.def_num == 3 {
              raw = Bytes::make(f.raw.length(), 0L.to_byte())
              serial_zeroed = serial_zeroed + 1
            } else if strip_hr && !f.invalid && is_hr(dm.global, f.def_num) {
              raw = Bytes::make(f.raw.length(), b'\xff')
              hr_stripped = hr_stripped + 1
            } else if !f.invalid &&
              (is_lat(dm.global, f.def_num) || is_lon(dm.global, f.def_num)) {
              let delta = if is_lat(dm.global, f.def_num) { dlat } else { dlon }
              let v = @fit.read_uint(raw, 0, 4, e).reinterpret_as_int64()
              raw = @fit.write_uint(
                wrap32(v + delta).reinterpret_as_uint64(),
                4,
                e,
              )
              if is_lat(dm.global, f.def_num) {
                if dlat != 0L {
                  lat_shifted = lat_shifted + 1
                }
              } else if dlon != 0L {
                lon_shifted = lon_shifted + 1
              }
            }
            nf.push({
              def_num: f.def_num,
              value: f.value,
              invalid: f.invalid,
              raw,
            })
          }
          out.push(
            @fit.Data({
              local_id: dm.local_id,
              global: dm.global,
              fields: nf,
              dev_data: dm.dev_data,
              ts_offset: dm.ts_offset,
              timestamp: dm.timestamp,
            }),
          )
        }
      }
    }
  }
  let report : RedactReport = {
    serial_zeroed,
    lat_shifted,
    lon_shifted,
    hr_stripped,
    trimmed_records: total_records - kept,
    fields_changed: serial_zeroed + lat_shifted + lon_shifted + hr_stripped,
    lat_delta: dlat,
    lon_delta: dlon,
  }
  (@fit.encode(h, out), report)
}

///|
pub fn redact(
  data : Bytes,
  trim : Int32,
  dlat : Int64,
  dlon : Int64,
) -> Bytes raise @fit.FitError {
  let (b, _) = redact_ex(data, trim, dlat, dlon, false)
  b
}
