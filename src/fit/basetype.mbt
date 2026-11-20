///|
// The sixteen FIT base types, their wire codes, element sizes and invalid
// values, plus endian-aware readers and writers.
//
// Invalid-value conventions (FIT protocol):
//   * signed integers use the maximum positive value (0x7F, 0x7FFF, ...);
//   * unsigned non-zero-terminated types and floats use all-ones (0xFF...);
//   * the `z` (zero-terminated) unsigned types use 0;
//   * a string is invalid when its first byte is 0.
// These are compared on the decoded unsigned bit pattern, so the check is
// endian-correct without inspecting individual bytes.

///|
#derive(Eq, Debug)
pub(all) enum Endian {
  Little
  Big
}

///|
pub extend Endian with Eq::{not_equal, equal}

///|
pub extend Endian with @debug.Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum BaseType {
  Enum
  Sint8
  Uint8
  Sint16
  Uint16
  Sint32
  Uint32
  Str
  Float32
  Float64
  Uint8z
  Uint16z
  Uint32z
  Byte
  Sint64
  Uint64
  Uint64z
}

///|
pub extend BaseType with Eq::{not_equal, equal}

///|
pub extend BaseType with @debug.Debug::{to_repr}

///|
// FIT definition messages carry an architecture byte: 0 = little, 1 = big.
pub fn endian_from_byte(b : Int32) -> Endian {
  if b == 0 {
    Little
  } else {
    Big
  }
}

///|
pub fn BaseType::from_code(code : Int32) -> BaseType? {
  match code {
    0x00 => Some(Enum)
    0x01 => Some(Sint8)
    0x02 => Some(Uint8)
    0x83 => Some(Sint16)
    0x84 => Some(Uint16)
    0x85 => Some(Sint32)
    0x86 => Some(Uint32)
    0x07 => Some(Str)
    0x88 => Some(Float32)
    0x89 => Some(Float64)
    0x0A => Some(Uint8z)
    0x8B => Some(Uint16z)
    0x8C => Some(Uint32z)
    0x0D => Some(Byte)
    0x8E => Some(Sint64)
    0x8F => Some(Uint64)
    0x90 => Some(Uint64z)
    _ => None
  }
}

///|
pub fn BaseType::code(t : BaseType) -> Int32 {
  match t {
    Enum => 0x00
    Sint8 => 0x01
    Uint8 => 0x02
    Sint16 => 0x83
    Uint16 => 0x84
    Sint32 => 0x85
    Uint32 => 0x86
    Str => 0x07
    Float32 => 0x88
    Float64 => 0x89
    Uint8z => 0x0A
    Uint16z => 0x8B
    Uint32z => 0x8C
    Byte => 0x0D
    Sint64 => 0x8E
    Uint64 => 0x8F
    Uint64z => 0x90
  }
}

///|
pub fn BaseType::size(t : BaseType) -> Int32 {
  match t {
    Sint16 | Uint16 | Uint16z => 2
    Sint32 | Uint32 | Uint32z | Float32 => 4
    Sint64 | Uint64 | Uint64z | Float64 => 8
    _ => 1
  }
}

///|
#derive(Eq, Debug)
pub(all) enum BaseValue {
  Signed(Int64)
  Unsigned(UInt64)
  Real(Double)
  Text(String)
  Array(Array[BaseValue])
  Raw(Bytes)
}

///|
pub extend BaseValue with Eq::{not_equal, equal}

///|
pub extend BaseValue with @debug.Debug::{to_repr}

///|
fn byte_at(data : Bytes, index : Int32) -> Int32 raise FitError {
  match data.get(index) {
    Some(b) => b.to_int()
    None => raise FitError::Truncated("byte index \{index} out of range")
  }
}

///|
pub fn read_uint(
  data : Bytes,
  off : Int32,
  size : Int32,
  endian : Endian,
) -> UInt64 raise FitError {
  let mut value : UInt64 = 0UL
  let mut k = 0
  while k < size {
    let index = off +
      (match endian {
        Little => k
        Big => size - 1 - k
      })
    let b = byte_at(data, index).to_int64().reinterpret_as_uint64()
    value = value.lor(b << (8 * k))
    k = k + 1
  }
  value
}

///|
pub fn write_uint(value : UInt64, size : Int32, endian : Endian) -> Bytes {
  let out : Array[Byte] = []
  let mut k = 0
  while k < size {
    let shift = 8 *
      (match endian {
        Little => k
        Big => size - 1 - k
      })
    out.push((value >> shift).land(0xFFUL).reinterpret_as_int64().to_byte())
    k = k + 1
  }
  Bytes::from_array(out)
}

///|
pub fn read_base(
  t : BaseType,
  data : Bytes,
  off : Int32,
  endian : Endian,
) -> BaseValue raise FitError {
  match t {
    Str => {
      let out : Array[Byte] = []
      let mut i = off
      while i < data.length() {
        let b = byte_at(data, i)
        if b == 0 {
          break
        }
        out.push(b.to_int64().to_byte())
        i = i + 1
      }
      Text(@utf8.decode_lossy(Bytes::from_array(out).clamped_view()))
    }
    Float32 => {
      let bits = read_uint(data, off, 4, endian).to_uint()
      Real(Float::reinterpret_from_uint(bits).to_double())
    }
    Float64 => Real(read_uint(data, off, 8, endian).reinterpret_as_double())
    Sint8 | Sint16 | Sint32 | Sint64 => {
      let size = t.size()
      let u = read_uint(data, off, size, endian)
      if size == 8 {
        Signed(u.reinterpret_as_int64())
      } else {
        // Sign-extend from the type's own width, not from 64 bits.
        let bits = 8 * size
        let half = 1L << (bits - 1)
        let full = 1L << bits
        let uu = u.reinterpret_as_int64()
        Signed(if uu >= half { uu - full } else { uu })
      }
    }
    _ => Unsigned(read_uint(data, off, t.size(), endian))
  }
}

///|
fn invalid_bits(t : BaseType) -> UInt64 {
  match t {
    Sint8 => 0x7FUL
    Sint16 => 0x7FFFUL
    Sint32 => 0x7FFFFFFFUL
    Sint64 => 0x7FFFFFFFFFFFFFFFUL
    Uint8z | Uint16z | Uint32z | Uint64z => 0UL
    Uint16 => 0xFFFFUL
    Uint32 | Float32 => 0xFFFFFFFFUL
    Uint64 | Float64 => 0xFFFFFFFFFFFFFFFFUL
    _ => 0xFFUL
  }
}

///|
pub fn is_invalid(
  t : BaseType,
  data : Bytes,
  off : Int32,
  endian : Endian,
) -> Bool raise FitError {
  match t {
    Str => byte_at(data, off) == 0
    _ => read_uint(data, off, t.size(), endian) == invalid_bits(t)
  }
}

///|
pub fn encode_base(
  t : BaseType,
  value : BaseValue,
  endian : Endian,
) -> Bytes raise FitError {
  match (t, value) {
    (Str, Text(s)) =>
      Bytes::add(@utf8.encode(s), Bytes::from_array([0L.to_byte()]))
    (Float64, Real(d)) => write_uint(d.reinterpret_as_uint64(), 8, endian)
    (Float32, Real(d)) =>
      write_uint(
        Float::from_double(d).reinterpret_as_uint().to_uint64(),
        4,
        endian,
      )
    (Sint8 | Sint16 | Sint32 | Sint64, Signed(v)) =>
      write_uint(v.reinterpret_as_uint64(), t.size(), endian)
    (_, Array(elems)) => {
      let mut acc = Bytes::from_array([])
      for e in elems {
        acc = Bytes::add(acc, encode_base(t, e, endian))
      }
      acc
    }
    (_, Raw(b)) => b
    (_, Unsigned(v)) => write_uint(v, t.size(), endian)
    _ => raise FitError::BaseValueMismatch("value does not match base type")
  }
}

///|
pub fn base_type(code : Int32) -> BaseType raise FitError {
  match BaseType::from_code(code) {
    Some(t) => t
    None => raise FitError::UnknownBaseType(code)
  }
}
