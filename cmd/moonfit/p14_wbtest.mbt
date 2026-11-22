///|
fn ebb(x : Int32) -> Byte {
  x.to_int64().to_byte()
}

///|
fn eu32(acc : Array[Byte], v : Int32) -> Unit {
  acc.push(ebb(v & 0xFF))
  acc.push(ebb((v >> 8) & 0xFF))
  acc.push(ebb((v >> 16) & 0xFF))
  acc.push(ebb((v >> 24) & 0xFF))
}

///|
fn eu16(acc : Array[Byte], v : Int32) -> Unit {
  acc.push(ebb(v & 0xFF))
  acc.push(ebb((v >> 8) & 0xFF))
}

///|
// Records whose base altitude(2)/speed(6) are invalid (0xFFFF) but whose
// enhanced_altitude(78)/enhanced_speed(73) are valid uint32. Altitude climbs
// 100 -> 110 -> 120 m (raw = (m+500)*5), speed 5 m/s (raw = m/s*1000).
fn enhanced_fit() -> Bytes {
  let body : Array[Byte] = []
  for
    x in [
      0x40, 0, 0, 20, 0, 5, 253, 4, 0x86, 2, 2, 0x84, 78, 4, 0x86, 6, 2, 0x84, 73,
      4, 0x86,
    ] {
    body.push(ebb(x))
  }
  let mut ts = 1000
  for a in [3000, 3050, 3100] {
    body.push(ebb(0x00))
    eu32(body, ts)
    eu16(body, 0xFFFF)
    eu32(body, a)
    eu16(body, 0xFFFF)
    eu32(body, 5000)
    ts = ts + 10
  }
  for
    x in [
      0x41, 0, 0, 18, 0, 5, 2, 4, 0x86, 5, 1, 0x02, 7, 4, 0x86, 8, 4, 0x86, 9, 4,
      0x86,
    ] {
    body.push(ebb(x))
  }
  body.push(ebb(0x01))
  eu32(body, 1000)
  body.push(ebb(2))
  eu32(body, 20000)
  eu32(body, 20000)
  eu32(body, 200000)
  let hdr : Array[Byte] = [ebb(14), ebb(0x10), ebb(0xEA), ebb(0x07)]
  eu32(hdr, body.length())
  for x in [0x2E, 0x46, 0x49, 0x54] {
    hdr.push(ebb(x))
  }
  eu16(hdr, @fit.crc16(Bytes::from_array(hdr).clamped_view()))
  let full : Array[Byte] = []
  for x in hdr {
    full.push(x)
  }
  for x in body {
    full.push(x)
  }
  eu16(full, @fit.crc16(Bytes::from_array(full).clamped_view()))
  Bytes::from_array(full)
}

///|
test "P1-4: enhanced altitude/speed preferred over invalid base; ascent non-zero" {
  let act = @model.from_fit(@fit.parse_messages(enhanced_fit()))
  assert_eq(act.points.length(), 3)
  assert_eq(act.points[0].altitude_m, Some(100.0))
  assert_eq(act.points[2].altitude_m, Some(120.0))
  assert_eq(act.points[0].speed_mps, Some(5.0))
  let m = @metrics.compute(act, [120, 140], 1)
  assert_true(m.computed_ascent_m > 0.0)
}
