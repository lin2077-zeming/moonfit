///|
fn pbb(x : Int32) -> Byte {
  x.to_int64().to_byte()
}

///|
fn pu32(acc : Array[Byte], v : Int32) -> Unit {
  acc.push(pbb(v & 0xFF))
  acc.push(pbb((v >> 8) & 0xFF))
  acc.push(pbb((v >> 16) & 0xFF))
  acc.push(pbb((v >> 24) & 0xFF))
}

///|
fn pu16(acc : Array[Byte], v : Int32) -> Unit {
  acc.push(pbb(v & 0xFF))
  acc.push(pbb((v >> 8) & 0xFF))
}

///|
fn pcompressed_fit() -> Bytes {
  let body : Array[Byte] = []
  for x in [0x40, 0, 0, 20, 0, 3, 253, 4, 0x86, 5, 4, 0x86, 3, 1, 0x02] {
    body.push(pbb(x))
  }
  body.push(pbb(0x00))
  pu32(body, 1000)
  pu32(body, 0)
  body.push(pbb(110))
  for x in [0x41, 0, 0, 20, 0, 2, 5, 4, 0x86, 3, 1, 0x02] {
    body.push(pbb(x))
  }
  body.push(pbb(0x80 | (1 << 5) | 18))
  pu32(body, 100000)
  body.push(pbb(120))
  for
    x in [
      0x42, 0, 0, 18, 0, 5, 2, 4, 0x86, 5, 1, 0x02, 7, 4, 0x86, 8, 4, 0x86, 9, 4,
      0x86,
    ] {
    body.push(pbb(x))
  }
  body.push(pbb(0x02))
  pu32(body, 1000)
  body.push(pbb(2))
  pu32(body, 20000)
  pu32(body, 10000)
  pu32(body, 100000)
  let hdr : Array[Byte] = [pbb(14), pbb(0x10), pbb(0xEA), pbb(0x07)]
  pu32(hdr, body.length())
  for x in [0x2E, 0x46, 0x49, 0x54] {
    hdr.push(pbb(x))
  }
  pu16(hdr, @fit.crc16(Bytes::from_array(hdr).clamped_view()))
  let full : Array[Byte] = []
  for x in hdr {
    full.push(x)
  }
  for x in body {
    full.push(x)
  }
  pu16(full, @fit.crc16(Bytes::from_array(full).clamped_view()))
  Bytes::from_array(full)
}

///|
test "P0-1: compressed-timestamp splits and HR zones are non-negative" {
  let act = @model.from_fit(@fit.parse_messages(pcompressed_fit()))
  let m = @metrics.compute(act, [115], 1)
  assert_true(m.splits.length() >= 1)
  assert_eq(m.splits[0].time_s, 10L)
  assert_eq(m.hr_zones[0].seconds, 10L)
}
