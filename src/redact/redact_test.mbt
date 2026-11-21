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

///|
fn hr_fit() -> Bytes {
  let body : Array[Byte] = []
  for x in [0x40, 0, 0, 20, 0, 3, 253, 4, 0x86, 3, 1, 0x02, 5, 4, 0x86] {
    body.push(rbb(x))
  }
  body.push(rbb(0x00))
  ri32le(body, 1000)
  body.push(rbb(110))
  ri32le(body, 0)
  for x in [0x42, 0, 0, 18, 0, 3, 7, 4, 0x86, 8, 4, 0x86, 9, 4, 0x86] {
    body.push(rbb(x))
  }
  body.push(rbb(0x02))
  ri32le(body, 2000)
  ri32le(body, 1000)
  ri32le(body, 0)
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
test "P0-7: redact_ex report counts shifted fields and trim" {
  let (_, r) = @redact.redact_ex(redef_fit(), 0, 600000L, -800000L, false)
  assert_eq(r.lat_shifted, 2)
  assert_eq(r.lon_shifted, 2)
  assert_eq(r.serial_zeroed, 0)
  assert_eq(r.trimmed_records, 0)
  assert_eq(r.fields_changed, 4)
  let (out1, r2) = @redact.redact_ex(hr_fit(), 1, 0L, 0L, false)
  assert_eq(r2.trimmed_records, 1)
  assert_eq(@fit.count_global(@fit.parse_messages(out1), 20), 0)
  let (out0, r0) = @redact.redact_ex(hr_fit(), 0, 0L, 0L, false)
  assert_eq(r0.trimmed_records, 0)
  assert_eq(@fit.count_global(@fit.parse_messages(out0), 20), 1)
}

///|
test "P0-7: --strip-hr zeroes heart rate and reports it" {
  let (out, r) = @redact.redact_ex(hr_fit(), 0, 0L, 0L, true)
  assert_eq(r.hr_stripped, 1)
  let msgs = @fit.data_messages(@fit.parse_messages(out))
  assert_eq(msgs[0].fields[1].raw, Bytes::from_array([rbb(0xFF)]))
  assert_true(msgs[0].fields[1].invalid)
}

///|
test "P0-7: zero coordinate delta reports zero shifted fields" {
  let (_, r) = @redact.redact_ex(redef_fit(), 0, 0L, 0L, false)
  assert_eq(r.lat_shifted, 0)
  assert_eq(r.lon_shifted, 0)
  assert_eq(r.fields_changed, 0)
  assert_eq(r.lat_delta, 0L)
  assert_eq(r.lon_delta, 0L)
}
