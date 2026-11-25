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
  (global == 18 && (def == 3 || def == 29 || def == 31)) ||
  (global == 19 && (def == 3 || def == 5))
}

///|
fn is_lon(global : Int32, def : Int32) -> Bool {
  (global == 20 && def == 1) ||
  (global == 18 && (def == 4 || def == 30 || def == 32)) ||
  (global == 19 && (def == 4 || def == 6))
}

///|
fn is_swc(global : Int32, def : Int32) -> Bool {
  global == 18 && (def == 31 || def == 32)
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
  swc_zero_preserved : Int32
  swc_nonzero_shifted : Int32
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
  ",\"swc_zero_preserved\":" +
  r.swc_zero_preserved.to_string() +
  ",\"swc_nonzero_shifted\":" +
  r.swc_nonzero_shifted.to_string() +
  ",\"lat_delta\":" +
  r.lat_delta.to_string() +
  ",\"lon_delta\":" +
  r.lon_delta.to_string() +
  "}"
}

///|
fn absolute_timestamp_fields(
  defs : @fit.Definition,
  fields : Array[@fit.FieldValue],
  timestamp : Int64,
) -> Array[@fit.FieldValue]? {
  let out : Array[@fit.FieldValue] = []
  let mut found = false
  for d in defs.fields {
    if d.def_num == 253 {
      if d.size != 4 {
        return None
      }
      out.push({
        def_num: 253,
        value: @fit.Unsigned(timestamp.reinterpret_as_uint64()),
        invalid: false,
        raw: @fit.write_uint(timestamp.reinterpret_as_uint64(), 4, defs.endian),
      })
      found = true
    } else {
      let mut copied : @fit.FieldValue? = None
      for f in fields {
        if f.def_num == d.def_num {
          copied = Some({
            def_num: f.def_num,
            value: f.value,
            invalid: f.invalid,
            raw: f.raw,
          })
        }
      }
      match copied {
        Some(f) => out.push(f)
        None => return None
      }
    }
  }
  if found {
    Some(out)
  } else {
    None
  }
}

///|
fn has_timestamp_field(definition : @fit.Definition) -> Bool {
  for f in definition.fields {
    if f.def_num == 253 {
      return true
    }
  }
  false
}

///|
fn timestamp_definition(
  definition : @fit.Definition,
  local_id : Int32,
) -> @fit.Definition {
  let fields : Array[@fit.FieldDef] = [
    { def_num: 253, size: 4, base: @fit.Uint32, },
  ]
  for f in definition.fields {
    fields.push(f)
  }
  {
    local_id,
    global: definition.global,
    endian: definition.endian,
    has_dev: definition.has_dev,
    fields,
    dev_fields: definition.dev_fields,
  }
}

///|
fn free_local_id(msgs : Array[@fit.Message]) -> Int32? {
  let used : Array[Bool] = Array::make(16, false)
  for m in msgs {
    match m {
      @fit.Def(d) => used[d.local_id] = true
      @fit.Data(_) => ()
    }
  }
  let mut i = 0
  while i < used.length() {
    if !used[i] {
      return Some(i)
    }
    i = i + 1
  }
  None
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
  let mut swc_zero_preserved = 0
  let mut swc_nonzero_shifted = 0
  let mut output_ts : Int64? = None
  let anchor_local_id : Int32? = if trim > 0 {
    free_local_id(msgs)
  } else {
    None
  }
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
          let definition = match defs[dm.local_id] {
            Some(d) => d
            None => raise @fit.FitError::NoDefinition(dm.local_id)
          }
          let e = definition.endian
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
              if is_swc(dm.global, f.def_num) && v == 0L {
                // The corpus contains a vendor-written zero SWC value. Keep
                // that known sentinel and report it, while shifting valid SWC.
                swc_zero_preserved = swc_zero_preserved + 1
              } else {
                raw = @fit.write_uint(
                  wrap32(v + delta).reinterpret_as_uint64(),
                  4,
                  e,
                )
                if is_swc(dm.global, f.def_num) && delta != 0L {
                  swc_nonzero_shifted = swc_nonzero_shifted + 1
                }
                if is_lat(dm.global, f.def_num) {
                  if dlat != 0L {
                    lat_shifted = lat_shifted + 1
                  }
                } else if dlon != 0L {
                  lon_shifted = lon_shifted + 1
                }
              }
            }
            nf.push({
              def_num: f.def_num,
              value: f.value,
              invalid: f.invalid,
              raw,
            })
          }
          let mut final_local_id = dm.local_id
          let needs_anchor = trim > 0 &&
            dm.ts_offset != None &&
            output_ts == None
          let final_fields = if needs_anchor {
            match dm.timestamp {
              Some(ts) => {
                let anchored_definition = if has_timestamp_field(definition) {
                  definition
                } else {
                  match anchor_local_id {
                    Some(local_id) => {
                      let d = timestamp_definition(definition, local_id)
                      out.push(@fit.Def(d))
                      final_local_id = local_id
                      d
                    }
                    None =>
                      raise @fit.FitError::Truncated(
                        "no free local message id for timestamp anchor",
                      )
                  }
                }
                match absolute_timestamp_fields(anchored_definition, nf, ts) {
                  Some(fs) => fs
                  None =>
                    raise @fit.FitError::Truncated(
                      "cannot anchor compressed timestamp after trim",
                    )
                }
              }
              None =>
                raise @fit.FitError::Truncated(
                  "compressed record has no absolute timestamp",
                )
            }
          } else {
            nf
          }
          let final_offset = if needs_anchor { None } else { dm.ts_offset }
          match dm.timestamp {
            Some(ts) => output_ts = Some(ts)
            None => ()
          }
          out.push(
            @fit.Data({
              local_id: final_local_id,
              global: dm.global,
              fields: final_fields,
              dev_data: dm.dev_data,
              ts_offset: final_offset,
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
    swc_zero_preserved,
    swc_nonzero_shifted,
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
