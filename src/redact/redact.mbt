///|
// Native FIT redaction: zero the device serial, shift coordinates by an exact
// integer number of semicircles, and optionally trim leading/trailing record
// messages. Operates on the parsed structure and re-encodes, so CRCs and the
// data-size header are recomputed. With trim=0 and the corpus shift values this
// reproduces the committed redacted corpus byte-for-byte from the raw export.
//
// session.swc_lat/swc_long are deliberately NOT shifted: they are 0 in the raw
// export (defect B1) and that contradiction is evidence a gate asserts.

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
pub fn redact(
  data : Bytes,
  trim : Int32,
  dlat : Int64,
  dlon : Int64,
) -> Bytes raise @fit.FitError {
  let h = @fit.parse_header(data)
  let msgs = @fit.parse_messages(data)
  // Track the currently-effective definition per local id as we walk, so a
  // local type redefined with a different architecture uses the endian that
  // was in force at each data message (not the last definition).
  let defs : Array[@fit.Definition?] = Array::make(16, None)
  let total_records = @fit.count_global(msgs, 20)
  let out : Array[@fit.Message] = []
  let mut rec_idx = 0
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
          let e = match defs[dm.local_id] {
            Some(d) => d.endian
            None => @fit.Little
          }
          let nf : Array[@fit.FieldValue] = []
          for f in dm.fields {
            let mut raw = f.raw
            if (dm.global == 0 || dm.global == 23) && f.def_num == 3 {
              raw = Bytes::make(f.raw.length(), 0L.to_byte())
            } else if !f.invalid &&
              (is_lat(dm.global, f.def_num) || is_lon(dm.global, f.def_num)) {
              let delta = if is_lat(dm.global, f.def_num) { dlat } else { dlon }
              let v = @fit.read_uint(raw, 0, 4, e).reinterpret_as_int64()
              raw = @fit.write_uint(
                wrap32(v + delta).reinterpret_as_uint64(),
                4,
                e,
              )
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
  @fit.encode(h, out)
}
