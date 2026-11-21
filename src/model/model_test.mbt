///|
fn bb(x : Int32) -> Byte {
  x.to_int64().to_byte()
}

///|
fn u32le(acc : Array[Byte], v : Int32) -> Unit {
  acc.push(bb(v & 0xFF))
  acc.push(bb((v >> 8) & 0xFF))
  acc.push(bb((v >> 16) & 0xFF))
  acc.push(bb((v >> 24) & 0xFF))
}

///|
fn u16le(acc : Array[Byte], v : Int32) -> Unit {
  acc.push(bb(v & 0xFF))
  acc.push(bb((v >> 8) & 0xFF))
}

///|
// A FIT with an absolute-timestamp record (ts=1000) followed by a
// compressed-timestamp record (offset=10 -> absolute 1010) that carries no 253
// field. The walker reconstructs 1010; the model must use it.
fn compressed_fit() -> Bytes {
  let body : Array[Byte] = []
  // def local0: timestamp(253,u32) distance(5,u32) hr(3,u8)
  for x in [0x40, 0, 0, 20, 0, 3, 253, 4, 0x86, 5, 4, 0x86, 3, 1, 0x02] {
    body.push(bb(x))
  }
  body.push(bb(0x00))
  u32le(body, 1000)
  u32le(body, 0)
  body.push(bb(110))
  // def local1: distance(5,u32) hr(3,u8)  (no timestamp)
  for x in [0x41, 0, 0, 20, 0, 2, 5, 4, 0x86, 3, 1, 0x02] {
    body.push(bb(x))
  }
  body.push(bb(0x80 | (1 << 5) | 18))
  u32le(body, 100000)
  body.push(bb(120))
  // session local2: start_time(2,u32) sport(5,u8) elapsed(7,u32) timer(8,u32) distance(9,u32)
  for
    x in [
      0x42, 0, 0, 18, 0, 5, 2, 4, 0x86, 5, 1, 0x02, 7, 4, 0x86, 8, 4, 0x86, 9, 4,
      0x86,
    ] {
    body.push(bb(x))
  }
  body.push(bb(0x02))
  u32le(body, 1000)
  body.push(bb(2))
  u32le(body, 20000)
  u32le(body, 10000)
  u32le(body, 100000)
  let hdr : Array[Byte] = [bb(14), bb(0x10), bb(0xEA), bb(0x07)]
  u32le(hdr, body.length())
  for x in [0x2E, 0x46, 0x49, 0x54] {
    hdr.push(bb(x))
  }
  let hcrc = @fit.crc16(Bytes::from_array(hdr).clamped_view())
  u16le(hdr, hcrc)
  let full : Array[Byte] = []
  for x in hdr {
    full.push(x)
  }
  for x in body {
    full.push(x)
  }
  let fcrc = @fit.crc16(Bytes::from_array(full).clamped_view())
  u16le(full, fcrc)
  Bytes::from_array(full)
}

///|
test "P0-1: model uses reconstructed compressed timestamp" {
  let act = @model.from_fit(@fit.parse_messages(compressed_fit()))
  assert_eq(act.points.length(), 2)
  assert_eq(act.points[0].timestamp, 1000L)
  assert_eq(act.points[1].timestamp, 1010L)
}
