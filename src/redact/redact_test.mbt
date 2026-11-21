///|
fn rbb(x : Int32) -> Byte {
  x.to_int64().to_byte()
}

///|
fn ri32le(acc : Array[Byte], v : Int32) -> Unit {
  acc.push(rbb(v & 0xFF))
  acc.push(rbb((v >> 8) & 0xFF))
  acc.push(rbb((v >> 16) & 0xFF))
  acc.push(rbb((v >> 24) & 0xFF))
}

///|
fn ri32be(acc : Array[Byte], v : Int32) -> Unit {
  acc.push(rbb((v >> 24) & 0xFF))
  acc.push(rbb((v >> 16) & 0xFF))
  acc.push(rbb((v >> 8) & 0xFF))
  acc.push(rbb(v & 0xFF))
}

///|
fn ru16(acc : Array[Byte], v : Int32) -> Unit {
  acc.push(rbb(v & 0xFF))
  acc.push(rbb((v >> 8) & 0xFF))
}

///|
fn redef_fit() -> Bytes {
  let body : Array[Byte] = []
  // local1 little-endian: lat(0,sint32) lon(1,sint32)
  for x in [0x41, 0, 0, 20, 0, 2, 0, 4, 0x85, 1, 4, 0x85] {
    body.push(rbb(x))
  }
  body.push(rbb(0x01))
  ri32le(body, 1000000)
  ri32le(body, 0)
  // local1 redefined big-endian
  for x in [0x41, 0, 1, 0, 20, 2, 0, 4, 0x85, 1, 4, 0x85] {
    body.push(rbb(x))
  }
  body.push(rbb(0x01))
  ri32be(body, 2000000)
  ri32be(body, 0)
  let hdr : Array[Byte] = [rbb(14), rbb(0x10), rbb(0xEA), rbb(0x07)]
  ri32le(hdr, body.length())
  for x in [0x2E, 0x46, 0x49, 0x54] {
    hdr.push(rbb(x))
  }
  ru16(hdr, @fit.crc16(Bytes::from_array(hdr).clamped_view()))
  let full : Array[Byte] = []
  for x in hdr {
    full.push(x)
  }
  for x in body {
    full.push(x)
  }
  ru16(full, @fit.crc16(Bytes::from_array(full).clamped_view()))
  Bytes::from_array(full)
}

///|
test "P0-4: redact uses per-message endian across little->big redefinition" {
  let orig = @fit.data_messages(@fit.parse_messages(redef_fit()))
  assert_true(!orig[1].fields[0].invalid)
  assert_eq(orig[1].fields[0].value, @fit.Signed(2000000L))
  let out = @redact.redact(redef_fit(), 0, 600000L, -800000L)
  let msgs = @fit.data_messages(@fit.parse_messages(out))
  assert_eq(msgs.length(), 2)
  assert_eq(msgs[0].fields[0].value, @fit.Signed(1600000L))
  assert_eq(msgs[0].fields[1].value, @fit.Signed(-800000L))
  assert_eq(msgs[1].fields[0].value, @fit.Signed(2600000L))
  assert_eq(msgs[1].fields[1].value, @fit.Signed(-800000L))
}
