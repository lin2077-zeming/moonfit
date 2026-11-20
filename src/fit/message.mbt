///|
// The FIT record-stream walker: definition messages, normal data messages and
// compressed-timestamp data messages. Ported from the byte-level reference
// walker validated against all 42 corpus files, reusing the base-type readers.
// A local message type may be redefined; the latest definition wins.
//
// Array fields are decoded element-wise into BaseValue::Array. Developer data
// is carried through untouched as a raw blob so the stream advances exactly
// (needed for byte-exact re-encoding); its semantics are out of scope.
//
// Each data message carries an absolute `timestamp`: taken from its timestamp
// field when present, or reconstructed from a compressed 5-bit offset against
// the previous absolute timestamp (with 0x20 roll-over).

///|
#derive(Eq, Debug)
pub(all) struct FieldDef {
  def_num : Int32
  size : Int32
  base : BaseType
}

///|
pub extend FieldDef with Eq::{not_equal, equal}

///|
pub extend FieldDef with @debug.Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Definition {
  local_id : Int32
  global : Int32
  endian : Endian
  has_dev : Bool
  fields : Array[FieldDef]
  dev_fields : Array[FieldDef]
}

///|
pub extend Definition with Eq::{not_equal, equal}

///|
pub extend Definition with @debug.Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct FieldValue {
  def_num : Int32
  value : BaseValue
  invalid : Bool
  raw : Bytes
}

///|
pub extend FieldValue with Eq::{not_equal, equal}

///|
pub extend FieldValue with @debug.Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct DataMessage {
  local_id : Int32
  global : Int32
  fields : Array[FieldValue]
  dev_data : Bytes
  ts_offset : Int32?
  timestamp : Int64?
}

///|
pub extend DataMessage with Eq::{not_equal, equal}

///|
pub extend DataMessage with @debug.Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Message {
  Def(Definition)
  Data(DataMessage)
}

///|
pub extend Message with Eq::{not_equal, equal}

///|
pub extend Message with @debug.Debug::{to_repr}

///|
fn require_def(
  defs : Array[Definition?],
  local_id : Int32,
) -> Definition raise FitError {
  match defs[local_id] {
    Some(d) => d
    None => raise FitError::NoDefinition(local_id)
  }
}

///|
// Strings are bounded by the declared field size, not by the rest of the file.
// Fixed-size fields whose declared size is a whole multiple of the element
// size are arrays and are decoded element-wise.
fn read_field(
  base : BaseType,
  size : Int32,
  data : Bytes,
  off : Int32,
  endian : Endian,
) -> BaseValue raise FitError {
  if base != Str && size != BaseType::size(base) {
    if off + size > data.length() {
      raise FitError::Truncated("array field exceeds file length")
    }
    let elem = BaseType::size(base)
    if size % elem != 0 {
      raise FitError::Truncated("array size is not a multiple of the element")
    }
    let n = size / elem
    let elems : Array[BaseValue] = []
    let mut k = 0
    while k < n {
      elems.push(read_base(base, data, off + k * elem, endian))
      k = k + 1
    }
    return Array(elems)
  }
  match base {
    Str => {
      let out : Array[Byte] = []
      let mut i = 0
      while i < size {
        let b = byte_at(data, off + i)
        if b == 0 {
          break
        }
        out.push(b.to_int64().to_byte())
        i = i + 1
      }
      Text(@utf8.decode_lossy(Bytes::from_array(out).clamped_view()))
    }
    _ => read_base(base, data, off, endian)
  }
}

///|
fn read_data(
  data : Bytes,
  start : Int32,
  d : Definition,
) -> (Array[FieldValue], Bytes, Int32) raise FitError {
  let mut cur = start
  let fields : Array[FieldValue] = []
  for f in d.fields {
    let value = read_field(f.base, f.size, data, cur, d.endian)
    let invalid = is_invalid(f.base, data, cur, d.endian)
    let raw = data.exact_view(start=cur, end=cur + f.size).to_owned()
    fields.push({ def_num: f.def_num, value, invalid, raw, })
    cur = cur + f.size
  }
  let mut dev_total = 0
  for f in d.dev_fields {
    dev_total = dev_total + f.size
  }
  if cur + dev_total > data.length() {
    raise FitError::Truncated("developer data exceeds file length")
  }
  let dev = if dev_total > 0 {
    data.exact_view(start=cur, end=cur + dev_total).to_owned()
  } else {
    Bytes::from_array([])
  }
  cur = cur + dev_total
  (fields, dev, cur)
}

///|
fn field_timestamp(fields : Array[FieldValue]) -> Int64? {
  for f in fields {
    if f.def_num == 253 && !f.invalid {
      match f.value {
        Signed(v) => return Some(v)
        Unsigned(v) => return Some(v.reinterpret_as_int64())
        _ => ()
      }
    }
  }
  None
}

///|
// Reconstruct an absolute timestamp from a compressed 5-bit offset. The offset
// replaces the low five bits of the previous timestamp and rolls over by 0x20
// when it wraps below the previous low bits.
fn reconstruct_ts(last : Int64?, offset : Int32) -> Int64? {
  match last {
    None => None
    Some(l) => {
      let off = Int64::from_int(offset)
      let mut ts = (l & -32L) + off
      if off < (l & 31L) {
        ts = ts + 0x20L
      }
      Some(ts)
    }
  }
}

///|
pub fn parse_messages(data : Bytes) -> Array[Message] raise FitError {
  let h = parse_header(data)
  let end = h.header_size + h.data_size.to_int()
  let defs : Array[Definition?] = Array::make(16, None)
  let out : Array[Message] = []
  let mut last_ts : Int64? = None
  let mut off = h.header_size
  while off < end {
    let hb = byte_at(data, off)
    if (hb & 0x80) != 0 {
      let local_id = (hb >> 5) & 0x3
      let toff = hb & 0x1F
      let d = require_def(defs, local_id)
      let (fields, dev, next) = read_data(data, off + 1, d)
      let ts = reconstruct_ts(last_ts, toff)
      last_ts = ts
      out.push(
        Data({
          local_id,
          global: d.global,
          fields,
          dev_data: dev,
          ts_offset: Some(toff),
          timestamp: ts,
        }),
      )
      off = next
    } else if (hb & 0x40) != 0 {
      let local_id = hb & 0x0F
      let has_dev = (hb & 0x20) != 0
      let arch = byte_at(data, off + 2)
      let endian = endian_from_byte(arch)
      let global = read_uint(data, off + 3, 2, endian)
        .reinterpret_as_int64()
        .to_int()
      let count = byte_at(data, off + 5)
      let mut cur = off + 6
      let fields : Array[FieldDef] = []
      let mut i = 0
      while i < count {
        let dn = byte_at(data, cur)
        let sz = byte_at(data, cur + 1)
        let bc = byte_at(data, cur + 2)
        fields.push({ def_num: dn, size: sz, base: base_type(bc), })
        cur = cur + 3
        i = i + 1
      }
      let dev_fields : Array[FieldDef] = []
      if has_dev {
        let dc = byte_at(data, cur)
        cur = cur + 1
        let mut j = 0
        while j < dc {
          let dn = byte_at(data, cur)
          let sz = byte_at(data, cur + 1)
          let bc = byte_at(data, cur + 2)
          dev_fields.push({ def_num: dn, size: sz, base: base_type(bc), })
          cur = cur + 3
          j = j + 1
        }
      }
      let d = { local_id, global, endian, has_dev, fields, dev_fields, }
      defs[local_id] = Some(d)
      out.push(Def(d))
      off = cur
    } else {
      let local_id = hb & 0x0F
      let d = require_def(defs, local_id)
      let (fields, dev, next) = read_data(data, off + 1, d)
      let ts = field_timestamp(fields)
      if ts != None {
        last_ts = ts
      }
      out.push(
        Data({
          local_id,
          global: d.global,
          fields,
          dev_data: dev,
          ts_offset: None,
          timestamp: ts,
        }),
      )
      off = next
    }
  }
  if off != end {
    raise FitError::Truncated("record stream did not consume the data section")
  }
  out
}

///|
pub fn data_messages(msgs : Array[Message]) -> Array[DataMessage] {
  let out : Array[DataMessage] = []
  for m in msgs {
    match m {
      Data(d) => out.push(d)
      Def(_) => ()
    }
  }
  out
}

///|
pub fn count_global(msgs : Array[Message], global : Int32) -> Int32 {
  let mut n = 0
  for m in data_messages(msgs) {
    if m.global == global {
      n = n + 1
    }
  }
  n
}
