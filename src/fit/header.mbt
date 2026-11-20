///|
// FIT file header. Two legal sizes: 12 bytes (no header CRC) and 14 bytes
// (with a header CRC over bytes [0,12)). The trailing file CRC always covers
// [0, len-2). `header_size + data_size + 2 == file_size` must hold.
//
// data_size is Int64 because a uint32 payload can exceed the 32-bit Int range
// on the wasm and js targets.

///|
#derive(Eq, Debug)
pub(all) struct FitHeader {
  header_size : Int32
  protocol : Int32
  profile : Int32
  data_size : Int64
  has_header_crc : Bool
}

///|
pub extend FitHeader with Eq::{not_equal, equal}

///|
pub extend FitHeader with @debug.Debug::{to_repr}

///|
pub fn parse_header(data : Bytes) -> FitHeader raise FitError {
  let len = data.length()
  if len < 12 {
    raise FitError::Truncated("a FIT header needs at least 12 bytes")
  }
  let header_size = data.at(0).to_int()
  if header_size != 12 && header_size != 14 {
    raise FitError::BadHeaderSize(header_size)
  }
  if len < header_size {
    raise FitError::Truncated("declared header size exceeds file length")
  }
  if !(data.at(8).to_int() == 0x2E &&
    data.at(9).to_int() == 0x46 &&
    data.at(10).to_int() == 0x49 &&
    data.at(11).to_int() == 0x54) {
    raise FitError::BadSignature
  }
  let protocol = data.at(1).to_int()
  let profile = read_uint(data, 2, 2, Little).reinterpret_as_int64().to_int()
  let data_size = read_uint(data, 4, 4, Little).reinterpret_as_int64()
  let has_header_crc = header_size == 14
  if has_header_crc {
    let stored = read_uint(data, 12, 2, Little).reinterpret_as_int64().to_int()
    let computed = crc16(data.clamped_view(end=12))
    if stored != computed {
      raise FitError::HeaderCrcMismatch(stored, computed)
    }
  }
  let expected = Int64::from_int(header_size) + data_size + 2L
  if expected != Int64::from_int(len) {
    raise FitError::FileSizeMismatch(expected, Int64::from_int(len))
  }
  { header_size, protocol, profile, data_size, has_header_crc, }
}

///|
pub fn file_crc_ok(data : Bytes) -> Bool {
  let len = data.length()
  if len < 2 {
    return false
  }
  // Direct byte reads: no error path, so this stays a total predicate.
  let stored = data.at(len - 2).to_int() | (data.at(len - 1).to_int() << 8)
  let computed = crc16(data.clamped_view(end=len - 2))
  stored == computed
}

///|
// Protocol version byte packs major in the high nibble, minor in the low.
pub fn protocol_major(h : FitHeader) -> Int32 {
  h.protocol >> 4
}

///|
pub fn protocol_minor(h : FitHeader) -> Int32 {
  h.protocol & 0xF
}

///|
// Total validity check: header (signature/size/header-CRC), trailing file CRC and
// full record-stream structure must all pass. Returns false on any typed error;
// never panics. Because the file CRC covers every preceding byte, any single-byte
// mutation of a valid file is detected here (Gate G6 sweeps this property).
pub fn verify(data : Bytes) -> Bool {
  let _ = parse_header(data) catch { _ => return false }
  if !file_crc_ok(data) {
    return false
  }
  let _ = parse_messages(data) catch { _ => return false }
  true
}
