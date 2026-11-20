///|
// Structure-preserving re-encoding. The header and every definition message are
// rebuilt from the parsed structure; data messages replay each field's original
// bytes in definition order, followed by any developer blob. CRCs are
// recomputed. Because field bytes are replayed verbatim (not re-derived from
// scaled values), a decode->encode round trip is byte-exact by construction.
// This is what Gate G2 asserts against the real corpus.

///|
fn b(x : Int32) -> Byte {
  x.to_int64().to_byte()
}

///|
fn push_bytes(acc : Array[Byte], src : Bytes) -> Unit {
  for x in src {
    acc.push(x)
  }
}

///|
fn push_u16(acc : Array[Byte], v : Int32, endian : Endian) -> Unit {
  push_bytes(
    acc,
    write_uint(Int64::from_int(v).reinterpret_as_uint64(), 2, endian),
  )
}

///|
fn push_u32(acc : Array[Byte], v : Int64, endian : Endian) -> Unit {
  push_bytes(acc, write_uint(v.reinterpret_as_uint64(), 4, endian))
}

///|
fn push_field_def(acc : Array[Byte], f : FieldDef) -> Unit {
  acc.push(b(f.def_num))
  acc.push(b(f.size))
  acc.push(b(BaseType::code(f.base)))
}

///|
pub fn encode_fit(data : Bytes) -> Bytes raise FitError {
  let h = parse_header(data)
  let msgs = parse_messages(data)
  let body : Array[Byte] = []
  for m in msgs {
    match m {
      Def(d) => {
        let hb = 0x40 | (if d.has_dev { 0x20 } else { 0 }) | d.local_id
        body.push(b(hb))
        body.push(b(0))
        body.push(
          b(
            match d.endian {
              Big => 1
              Little => 0
            },
          ),
        )
        push_u16(body, d.global, d.endian)
        body.push(b(d.fields.length()))
        for f in d.fields {
          push_field_def(body, f)
        }
        if d.has_dev {
          body.push(b(d.dev_fields.length()))
          for f in d.dev_fields {
            push_field_def(body, f)
          }
        }
      }
      Data(dm) => {
        let hb = match dm.ts_offset {
          Some(o) => 0x80 | (dm.local_id << 5) | o
          None => dm.local_id
        }
        body.push(b(hb))
        for f in dm.fields {
          push_bytes(body, f.raw)
        }
        push_bytes(body, dm.dev_data)
      }
    }
  }
  if body.length() != h.data_size.to_int() {
    raise FitError::FileSizeMismatch(
      Int64::from_int(body.length()),
      h.data_size,
    )
  }
  let hdr : Array[Byte] = []
  hdr.push(b(h.header_size))
  hdr.push(b(h.protocol))
  push_u16(hdr, h.profile, Little)
  push_u32(hdr, h.data_size, Little)
  push_bytes(hdr, Bytes::from_array([b(0x2E), b(0x46), b(0x49), b(0x54)]))
  if h.header_size == 14 {
    let hc = crc16(Bytes::from_array(hdr).clamped_view())
    push_u16(hdr, hc, Little)
  }
  let full = Bytes::add(Bytes::from_array(hdr), Bytes::from_array(body))
  let fc = crc16(full.clamped_view())
  Bytes::add(
    full,
    write_uint(Int64::from_int(fc).reinterpret_as_uint64(), 2, Little),
  )
}
