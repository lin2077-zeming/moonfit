///|
// Gate G1 (CRC) plus header and base-type gates. The smallest redacted corpus
// file is embedded verbatim so these run on every backend without filesystem
// access. Expected checksums were produced by the independent Python walker.

///|
let corpus0 : Bytes = Bytes::from_array([
  14, 16, 26, 8, 164, 8, 0, 0, 46, 70, 73, 84, 167, 187, 70, 0, 0, 0, 0, 5, 3, 32,
  140, 4, 4, 134, 1, 2, 132, 2, 2, 132, 0, 1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 36, 211, 68,
  115, 0, 103, 0, 4, 71, 0, 0, 49, 0, 2, 0, 2, 132, 1, 1, 2, 7, 100, 0, 100, 65,
  0, 0, 23, 0, 8, 253, 4, 134, 3, 32, 140, 2, 2, 132, 4, 2, 132, 5, 2, 132, 0, 1,
  2, 1, 1, 2, 6, 1, 2, 1, 5, 36, 211, 68, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 115, 0, 103, 0, 128, 0,
  255, 0, 100, 64, 0, 0, 21, 0, 4, 253, 4, 134, 3, 4, 134, 0, 1, 0, 1, 1, 0, 69,
  0, 0, 20, 0, 10, 253, 4, 134, 0, 4, 133, 1, 4, 133, 5, 4, 134, 2, 2, 132, 6, 2,
  132, 7, 2, 132, 3, 1, 2, 4, 1, 2, 13, 1, 1, 66, 0, 0, 19, 0, 48, 253, 4, 134, 2,
  4, 134, 3, 4, 133, 4, 4, 133, 5, 4, 133, 6, 4, 133, 7, 4, 134, 8, 4, 134, 9, 4,
  134, 52, 4, 134, 254, 2, 132, 11, 2, 132, 13, 2, 132, 14, 2, 132, 19, 2, 132, 20,
  2, 132, 21, 2, 132, 22, 2, 132, 33, 2, 132, 34, 2, 132, 42, 2, 132, 43, 2, 132,
  45, 2, 131, 46, 2, 131, 47, 2, 131, 48, 2, 131, 49, 2, 131, 53, 2, 131, 54, 2,
  131, 55, 2, 131, 56, 2, 131, 62, 2, 132, 0, 1, 0, 1, 1, 0, 15, 1, 2, 16, 1, 2,
  17, 1, 2, 18, 1, 2, 24, 1, 0, 25, 1, 0, 39, 1, 0, 50, 1, 1, 51, 1, 1, 63, 1, 2,
  91, 1, 2, 92, 1, 2, 93, 1, 2, 94, 1, 2, 0, 5, 36, 211, 68, 255, 255, 255, 255,
  0, 0, 5, 6, 36, 211, 68, 180, 141, 241, 15, 150, 51, 24, 80, 0, 0, 0, 0, 154, 9,
  52, 15, 255, 255, 255, 255, 25, 5, 7, 36, 211, 68, 208, 140, 241, 15, 20, 50, 24,
  80, 138, 1, 0, 0, 154, 9, 112, 15, 255, 255, 255, 255, 25, 5, 8, 36, 211, 68, 230,
  139, 241, 15, 150, 48, 24, 80, 20, 3, 0, 0, 154, 9, 139, 15, 255, 255, 255, 255,
  25, 5, 9, 36, 211, 68, 248, 138, 241, 15, 18, 47, 24, 80, 164, 4, 0, 0, 154, 9,
  19, 16, 255, 255, 255, 255, 25, 5, 10, 36, 211, 68, 22, 138, 241, 15, 121, 45,
  24, 80, 62, 6, 0, 0, 154, 9, 140, 16, 255, 255, 255, 255, 25, 5, 11, 36, 211, 68,
  53, 137, 241, 15, 197, 43, 24, 80, 235, 7, 0, 0, 154, 9, 112, 17, 255, 255, 255,
  255, 25, 5, 12, 36, 211, 68, 72, 136, 241, 15, 2, 42, 24, 80, 169, 9, 0, 0, 154,
  9, 32, 18, 255, 255, 255, 255, 26, 5, 13, 36, 211, 68, 71, 135, 241, 15, 53, 40,
  24, 80, 120, 11, 0, 0, 154, 9, 160, 18, 255, 255, 255, 255, 25, 5, 14, 36, 211,
  68, 54, 134, 241, 15, 93, 38, 24, 80, 87, 13, 0, 0, 154, 9, 226, 18, 255, 255,
  255, 255, 26, 5, 17, 36, 211, 68, 17, 131, 241, 15, 161, 32, 24, 80, 19, 19, 0,
  0, 154, 9, 27, 19, 255, 255, 255, 255, 25, 5, 19, 36, 211, 68, 253, 128, 241, 15,
  192, 28, 24, 80, 238, 22, 0, 0, 154, 9, 84, 19, 255, 255, 255, 255, 26, 5, 27,
  36, 211, 68, 83, 120, 241, 15, 209, 13, 24, 80, 26, 38, 0, 0, 154, 9, 190, 17,
  255, 255, 255, 255, 25, 5, 31, 36, 211, 68, 246, 116, 241, 15, 234, 6, 24, 80,
  214, 44, 0, 0, 154, 9, 225, 15, 255, 255, 255, 255, 25, 5, 33, 36, 211, 68, 13,
  117, 241, 15, 89, 3, 24, 80, 240, 47, 0, 0, 154, 9, 132, 16, 255, 255, 255, 255,
  25, 5, 36, 36, 211, 68, 41, 120, 241, 15, 82, 254, 23, 80, 57, 53, 0, 0, 154, 9,
  111, 16, 255, 255, 255, 255, 25, 5, 38, 36, 211, 68, 212, 123, 241, 15, 253, 251,
  23, 80, 47, 57, 0, 0, 154, 9, 189, 19, 255, 255, 255, 255, 25, 5, 39, 36, 211,
  68, 226, 125, 241, 15, 228, 250, 23, 80, 81, 59, 0, 0, 154, 9, 90, 20, 255, 255,
  255, 255, 25, 5, 40, 36, 211, 68, 11, 128, 241, 15, 192, 249, 23, 80, 141, 61,
  0, 0, 154, 9, 246, 20, 255, 255, 255, 255, 25, 5, 48, 36, 211, 68, 39, 143, 241,
  15, 207, 240, 23, 80, 147, 77, 0, 0, 154, 9, 33, 17, 255, 255, 255, 255, 25, 5,
  56, 36, 211, 68, 40, 157, 241, 15, 68, 232, 23, 80, 139, 92, 0, 0, 154, 9, 150,
  16, 255, 255, 255, 255, 25, 5, 64, 36, 211, 68, 200, 166, 241, 15, 248, 225, 23,
  80, 8, 103, 0, 0, 153, 9, 165, 14, 255, 255, 255, 255, 26, 5, 72, 36, 211, 68,
  102, 176, 241, 15, 222, 216, 23, 80, 238, 114, 0, 0, 153, 9, 242, 13, 255, 255,
  255, 255, 25, 5, 80, 36, 211, 68, 66, 183, 241, 15, 155, 204, 23, 80, 72, 127,
  0, 0, 153, 9, 183, 15, 255, 255, 255, 255, 25, 5, 86, 36, 211, 68, 247, 189, 241,
  15, 28, 195, 23, 80, 150, 137, 0, 0, 153, 9, 64, 18, 255, 255, 255, 255, 25, 5,
  90, 36, 211, 68, 15, 196, 241, 15, 58, 188, 23, 80, 202, 145, 0, 0, 153, 9, 148,
  21, 255, 255, 255, 255, 25, 5, 95, 36, 211, 68, 9, 204, 241, 15, 32, 179, 23, 80,
  148, 156, 0, 0, 154, 9, 179, 21, 255, 255, 255, 255, 25, 5, 104, 36, 211, 68, 248,
  217, 241, 15, 37, 163, 23, 80, 123, 175, 0, 0, 154, 9, 160, 22, 255, 255, 255,
  255, 25, 5, 112, 36, 211, 68, 54, 231, 241, 15, 30, 148, 23, 80, 88, 193, 0, 0,
  154, 9, 135, 22, 255, 255, 255, 255, 25, 5, 118, 36, 211, 68, 194, 240, 241, 15,
  77, 137, 23, 80, 59, 206, 0, 0, 154, 9, 23, 21, 255, 255, 255, 255, 25, 5, 125,
  36, 211, 68, 248, 251, 241, 15, 197, 126, 23, 80, 18, 220, 0, 0, 155, 9, 162, 19,
  255, 255, 255, 255, 25, 5, 133, 36, 211, 68, 28, 8, 242, 15, 247, 112, 23, 80,
  120, 236, 0, 0, 155, 9, 98, 19, 255, 255, 255, 255, 25, 5, 140, 36, 211, 68, 223,
  16, 242, 15, 225, 103, 23, 80, 205, 247, 0, 0, 155, 9, 183, 14, 255, 255, 255,
  255, 25, 5, 146, 36, 211, 68, 103, 21, 242, 15, 240, 99, 23, 80, 204, 252, 0, 0,
  154, 9, 0, 0, 255, 255, 255, 255, 25, 0, 147, 36, 211, 68, 1, 0, 0, 0, 0, 1, 0,
  155, 36, 211, 68, 255, 255, 255, 255, 0, 0, 5, 160, 36, 211, 68, 165, 17, 242,
  15, 214, 93, 23, 80, 10, 255, 0, 0, 155, 9, 0, 0, 255, 255, 255, 255, 25, 0, 160,
  36, 211, 68, 1, 0, 0, 0, 0, 1, 0, 231, 36, 211, 68, 255, 255, 255, 255, 0, 0, 5,
  233, 36, 211, 68, 199, 14, 242, 15, 24, 91, 23, 80, 91, 0, 1, 0, 154, 9, 3, 6,
  255, 255, 255, 255, 25, 5, 238, 36, 211, 68, 220, 15, 242, 15, 221, 88, 23, 80,
  80, 2, 1, 0, 154, 9, 88, 2, 255, 255, 255, 255, 25, 5, 246, 36, 211, 68, 141, 24,
  242, 15, 154, 83, 23, 80, 151, 11, 1, 0, 155, 9, 65, 18, 255, 255, 255, 255, 25,
  5, 254, 36, 211, 68, 114, 39, 242, 15, 114, 74, 23, 80, 137, 27, 1, 0, 155, 9,
  71, 17, 255, 255, 255, 255, 25, 5, 2, 37, 211, 68, 27, 43, 242, 15, 233, 70, 23,
  80, 44, 32, 1, 0, 155, 9, 72, 9, 255, 255, 255, 255, 25, 5, 6, 37, 211, 68, 129,
  42, 242, 15, 190, 65, 23, 80, 185, 36, 1, 0, 155, 9, 226, 15, 255, 255, 255, 255,
  25, 5, 14, 37, 211, 68, 42, 35, 242, 15, 137, 52, 23, 80, 253, 49, 1, 0, 156, 9,
  222, 13, 255, 255, 255, 255, 25, 5, 17, 37, 211, 68, 21, 34, 242, 15, 238, 48,
  23, 80, 83, 53, 1, 0, 155, 9, 135, 9, 255, 255, 255, 255, 25, 5, 21, 37, 211, 68,
  166, 37, 242, 15, 249, 45, 23, 80, 155, 57, 1, 0, 155, 9, 167, 10, 255, 255, 255,
  255, 25, 5, 26, 37, 211, 68, 78, 41, 242, 15, 66, 42, 23, 80, 87, 62, 1, 0, 155,
  9, 76, 5, 255, 255, 255, 255, 25, 5, 30, 37, 211, 68, 237, 40, 242, 15, 89, 41,
  23, 80, 197, 62, 1, 0, 156, 9, 0, 0, 255, 255, 255, 255, 25, 0, 30, 37, 211, 68,
  1, 0, 0, 0, 0, 1, 0, 34, 37, 211, 68, 255, 255, 255, 255, 0, 0, 2, 35, 37, 211,
  68, 6, 36, 211, 68, 180, 141, 241, 15, 150, 51, 24, 80, 175, 40, 242, 15, 205,
  39, 23, 80, 72, 89, 4, 0, 88, 9, 3, 0, 39, 63, 1, 0, 88, 9, 3, 0, 1, 0, 18, 0,
  9, 16, 160, 22, 255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255, 154, 9, 156,
  9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 152, 9, 9, 1, 255, 255,
  255, 255, 7, 2, 7, 25, 26, 255, 255, 255, 255, 255, 0, 35, 37, 211, 68, 255, 255,
  255, 255, 0, 4, 0, 35, 37, 211, 68, 255, 255, 255, 255, 8, 9, 67, 0, 0, 18, 0,
  56, 253, 4, 134, 2, 4, 134, 3, 4, 133, 4, 4, 133, 7, 4, 134, 8, 4, 134, 9, 4, 134,
  29, 4, 133, 30, 4, 133, 31, 4, 133, 32, 4, 133, 59, 4, 134, 65, 20, 134, 67, 24,
  134, 68, 28, 134, 254, 2, 132, 11, 2, 132, 14, 2, 132, 15, 2, 132, 20, 2, 132,
  21, 2, 132, 22, 2, 132, 23, 2, 132, 25, 2, 132, 26, 2, 132, 34, 2, 132, 35, 2,
  132, 36, 2, 132, 37, 2, 132, 49, 2, 132, 50, 2, 132, 52, 2, 131, 53, 2, 131, 54,
  2, 131, 55, 2, 131, 56, 2, 131, 60, 2, 131, 61, 2, 131, 62, 2, 131, 63, 2, 131,
  71, 2, 132, 0, 1, 0, 1, 1, 0, 5, 1, 0, 6, 1, 0, 16, 1, 2, 17, 1, 2, 18, 1, 2, 19,
  1, 2, 57, 1, 1, 58, 1, 1, 64, 1, 2, 101, 1, 2, 102, 1, 2, 103, 1, 2, 104, 1, 2,
  3, 35, 37, 211, 68, 6, 36, 211, 68, 180, 141, 241, 15, 150, 51, 24, 80, 72, 89,
  4, 0, 88, 9, 3, 0, 39, 63, 1, 0, 55, 43, 242, 15, 150, 51, 24, 80, 0, 0, 0, 0,
  0, 0, 0, 0, 88, 9, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  1, 0, 18, 0, 9, 16, 160, 22, 255, 255, 255, 255, 0, 0, 0, 0, 0, 0, 1, 0, 255, 255,
  255, 255, 255, 255, 255, 255, 154, 9, 156, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 152, 9, 8, 1, 2, 7, 255, 255, 255, 255, 25, 26, 255, 255,
  255, 255, 255, 65, 0, 0, 23, 0, 8, 253, 4, 134, 3, 32, 140, 2, 2, 132, 4, 2, 132,
  5, 2, 132, 0, 1, 2, 1, 1, 2, 6, 1, 2, 1, 35, 37, 211, 68, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 115,
  0, 103, 0, 128, 0, 255, 0, 100, 68, 0, 0, 34, 0, 7, 253, 4, 134, 0, 4, 134, 5,
  4, 134, 1, 2, 132, 2, 1, 0, 3, 1, 0, 4, 1, 0, 4, 35, 37, 211, 68, 88, 9, 3, 0,
  163, 149, 211, 68, 0, 0, 0, 26, 1, 30, 163,
])

///|
test "crc16 matches the standard ARC check value" {
  assert_eq(
    @fit.crc16(
      Bytes::from_array([0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39]).clamped_view(),
    ),
    0xBB3D,
  )
  assert_eq(@fit.crc16(Bytes::from_array([]).clamped_view()), 0)
  assert_eq(@fit.crc16(Bytes::from_array([0xFF]).clamped_view()), 0x4040)
}

///|
test "G1: corpus file CRC and header CRC reproduce" {
  let len = corpus0.length()
  assert_eq(@fit.crc16(corpus0.clamped_view(end=len - 2)), 0xa31e)
  assert_eq(@fit.crc16(corpus0.clamped_view(end=12)), 0xbba7)
  assert_true(@fit.file_crc_ok(corpus0))
}

///|
test "G1: header parses to the measured profile" {
  let h = @fit.parse_header(corpus0)
  assert_eq(h.header_size, 14)
  assert_eq(h.protocol, 0x10)
  assert_eq(h.profile, 2074)
  assert_eq(h.data_size, 2212L)
  assert_true(h.has_header_crc)
  assert_eq(@fit.protocol_major(h), 1)
  assert_eq(@fit.protocol_minor(h), 0)
}

///|
test "header rejects truncation, bad size and bad signature" {
  try @fit.parse_header(Bytes::from_array([14, 0x10, 0, 0])) catch {
    @fit.Truncated(_) => ()
    _ => fail("expected Truncated")
  } noraise {
    _ => fail("expected Truncated")
  }
  let bad_size = Bytes::from_array([
    13, 0x10, 0, 0, 0, 0, 0, 0, 0x2E, 0x46, 0x49, 0x54,
  ])
  try @fit.parse_header(bad_size) catch {
    @fit.BadHeaderSize(13) => ()
    _ => fail("expected BadHeaderSize")
  } noraise {
    _ => fail("expected BadHeaderSize")
  }
  let bad_sig = Bytes::from_array([
    12, 0x10, 0, 0, 0, 0, 0, 0, 0x2E, 0x46, 0x49, 0x55, 0, 0,
  ])
  try @fit.parse_header(bad_sig) catch {
    @fit.BadSignature => ()
    _ => fail("expected BadSignature")
  } noraise {
    _ => fail("expected BadSignature")
  }
}

///|
test "header rejects a wrong header CRC" {
  // 14-byte header, data_size 0, so a valid file is 16 bytes; store a bad CRC.
  let b = Bytes::from_array([
    14, 0x10, 0xEA, 0x07, 0, 0, 0, 0, 0x2E, 0x46, 0x49, 0x54, 0x00, 0x00, 0, 0,
  ])
  try @fit.parse_header(b) catch {
    @fit.HeaderCrcMismatch(_, _) => ()
    _ => fail("expected HeaderCrcMismatch")
  } noraise {
    _ => fail("expected HeaderCrcMismatch")
  }
}

///|
test "read_uint respects endianness" {
  let b = Bytes::from_array([0x12, 0x34])
  assert_eq(@fit.read_uint(b, 0, 2, @fit.Little), 0x3412UL)
  assert_eq(@fit.read_uint(b, 0, 2, @fit.Big), 0x1234UL)
}

///|
test "base types round-trip in both endiannesses" {
  let cases : Array[(@fit.BaseType, @fit.BaseValue)] = [
    (@fit.Enum, @fit.Unsigned(5UL)),
    (@fit.Sint8, @fit.Signed(-3L)),
    (@fit.Uint8, @fit.Unsigned(200UL)),
    (@fit.Sint16, @fit.Signed(-1234L)),
    (@fit.Uint16, @fit.Unsigned(60000UL)),
    (@fit.Sint32, @fit.Signed(-123456789L)),
    (@fit.Uint32, @fit.Unsigned(4000000000UL)),
    (@fit.Str, @fit.Text("hi")),
    (@fit.Float32, @fit.Real(1.5)),
    (@fit.Float64, @fit.Real(-2.25)),
    (@fit.Uint8z, @fit.Unsigned(7UL)),
    (@fit.Uint16z, @fit.Unsigned(700UL)),
    (@fit.Uint32z, @fit.Unsigned(70000UL)),
    (@fit.Byte, @fit.Unsigned(0xABUL)),
    (@fit.Sint64, @fit.Signed(-1234567890123L)),
    (@fit.Uint64, @fit.Unsigned(12345678901234567890UL)),
    (@fit.Uint64z, @fit.Unsigned(12345678901234567890UL)),
  ]
  for (t, v) in cases {
    for e in [@fit.Little, @fit.Big] {
      let enc = @fit.encode_base(t, v, e)
      let back = @fit.read_base(t, enc, 0, e)
      assert_eq(back, v)
    }
  }
}

///|
test "base type codes and sizes match the wire table" {
  for
    t in [
      @fit.Enum,
      @fit.Sint8,
      @fit.Uint8,
      @fit.Sint16,
      @fit.Uint16,
      @fit.Sint32,
      @fit.Uint32,
      @fit.Str,
      @fit.Float32,
      @fit.Float64,
      @fit.Uint8z,
      @fit.Uint16z,
      @fit.Uint32z,
      @fit.Byte,
      @fit.Sint64,
      @fit.Uint64,
      @fit.Uint64z,
    ] {
    assert_eq(@fit.BaseType::from_code(@fit.BaseType::code(t)), Some(t))
  }
  assert_eq(@fit.BaseType::size(@fit.Uint16), 2)
  assert_eq(@fit.BaseType::size(@fit.Uint32), 4)
  assert_eq(@fit.BaseType::size(@fit.Uint64), 8)
  assert_eq(@fit.BaseType::size(@fit.Str), 1)
  assert_eq(@fit.BaseType::from_code(0x99), None)
}

///|
test "invalid detection follows the per-type convention" {
  assert_true(
    @fit.is_invalid(
      @fit.Uint16,
      Bytes::from_array([0xFF, 0xFF]),
      0,
      @fit.Little,
    ),
  )
  assert_true(
    !@fit.is_invalid(
      @fit.Uint16,
      Bytes::from_array([0x01, 0x00]),
      0,
      @fit.Little,
    ),
  )
  assert_true(
    @fit.is_invalid(
      @fit.Sint32,
      Bytes::from_array([0xFF, 0xFF, 0xFF, 0x7F]),
      0,
      @fit.Little,
    ),
  )
  assert_true(
    @fit.is_invalid(
      @fit.Sint32,
      Bytes::from_array([0x7F, 0xFF, 0xFF, 0xFF]),
      0,
      @fit.Big,
    ),
  )
  assert_true(
    @fit.is_invalid(
      @fit.Uint32z,
      Bytes::from_array([0, 0, 0, 0]),
      0,
      @fit.Little,
    ),
  )
  assert_true(@fit.is_invalid(@fit.Str, Bytes::from_array([0]), 0, @fit.Little))
  assert_true(
    !@fit.is_invalid(@fit.Str, Bytes::from_array([0x61, 0]), 0, @fit.Little),
  )
}

///|
let synth : Bytes = Bytes::from_array([
  14, 16, 26, 8, 44, 0, 0, 0, 46, 70, 73, 84, 39, 189, 64, 0, 0, 20, 0, 2, 253, 4,
  134, 0, 4, 133, 0, 232, 3, 0, 0, 251, 255, 255, 255, 0, 233, 3, 0, 0, 250, 255,
  255, 255, 65, 0, 0, 20, 0, 1, 0, 4, 133, 167, 249, 255, 255, 255, 32, 123,
])

///|
test "walker: corpus0 message and record counts" {
  let msgs = @fit.parse_messages(corpus0)
  let data = @fit.data_messages(msgs)
  assert_eq(data.length(), 61)
  assert_eq(@fit.count_global(msgs, 20), 45)
  assert_eq(@fit.count_global(msgs, 18), 1)
  assert_eq(@fit.count_global(msgs, 0), 1)
  let mut defs1 = 0
  for m in msgs {
    match m {
      @fit.Def(d) => if d.local_id == 1 { defs1 = defs1 + 1 }
      _ => ()
    }
  }
  assert_eq(defs1, 2)
}

///|
test "walker: session distance is read as raw centimetres" {
  let msgs = @fit.parse_messages(corpus0)
  let mut found = false
  for m in @fit.data_messages(msgs) {
    if m.global == 18 {
      for f in m.fields {
        if f.def_num == 9 {
          assert_eq(f.value, @fit.Unsigned(81703UL))
          assert_true(!f.invalid)
          found = true
        }
      }
    }
  }
  assert_true(found)
}

///|
test "walker: array fields decode element-wise" {
  let msgs = @fit.parse_messages(corpus0)
  let data = @fit.data_messages(msgs)
  // file_id.serial_number is uint32z[8], redacted to zero.
  match data[0].fields[0].value {
    @fit.Array(elems) => assert_eq(elems.length(), 8)
    _ => fail("expected serial_number to be an array")
  }
  // session.time_in_hr_zone is uint32[5].
  let mut zone_ok = false
  for m in data {
    if m.global == 18 {
      for f in m.fields {
        if f.def_num == 65 {
          match f.value {
            @fit.Array(e) => {
              assert_eq(e.length(), 5)
              zone_ok = true
            }
            _ => fail("expected time_in_hr_zone array")
          }
        }
      }
    }
  }
  assert_true(zone_ok)
}

///|
test "walker: normal messages carry their timestamp field" {
  let msgs = @fit.parse_messages(synth)
  let data = @fit.data_messages(msgs)
  assert_eq(data[0].timestamp, Some(1000L))
  assert_eq(data[1].timestamp, Some(1001L))
}

///|
test "walker: compressed timestamp reconstructs with roll-over" {
  let msgs = @fit.parse_messages(synth)
  let data = @fit.data_messages(msgs)
  assert_eq(data.length(), 3)
  assert_eq(data[2].ts_offset, Some(7))
  // last=1001 (low bits 9); offset 7 < 9 rolls over by 0x20 -> 1031.
  assert_eq(data[2].timestamp, Some(1031L))
  assert_eq(data[2].fields.length(), 1)
  assert_eq(data[2].fields[0].value, @fit.Signed(-7L))
  let mut defs = 0
  for m in msgs {
    match m {
      @fit.Def(_) => defs = defs + 1
      _ => ()
    }
  }
  assert_eq(defs, 2)
}

///|
test "walker: data message without a definition is rejected" {
  let b = Bytes::from_array([
    12, 0x10, 0xEA, 0x07, 1, 0, 0, 0, 0x2E, 0x46, 0x49, 0x54, 0x00, 0, 0,
  ])
  try @fit.parse_messages(b) catch {
    @fit.NoDefinition(0) => ()
    _ => fail("expected NoDefinition")
  } noraise {
    _ => fail("expected NoDefinition")
  }
}

///|
test "G2: decode->encode is byte-exact on the embedded corpus file" {
  assert_eq(@fit.encode_fit(corpus0), corpus0)
}

///|
test "G2: decode->encode is byte-exact on the synthetic stream" {
  assert_eq(@fit.encode_fit(synth), synth)
}

///|
test "G2: re-encoding a corrupted CRC is rejected, not silently fixed" {
  // Flip a data byte; parse still succeeds (CRC not checked by walker) but the
  // re-encoded file recomputes a correct CRC, so it must differ from input.
  let arr = corpus0.to_array()
  arr[20] = arr[20].lxor(b'\xff')
  let bad = Bytes::from_array(arr)
  let re = @fit.encode_fit(bad)
  assert_true(re != bad)
  assert_true(@fit.file_crc_ok(re))
}

///|
fn bb(x : Int32) -> Byte {
  x.to_int64().to_byte()
}

///|
fn wrap12(body : Array[Byte]) -> Bytes {
  let n = body.length()
  let hdr : Array[Byte] = [
    bb(12),
    bb(0x10),
    bb(0xEA),
    bb(0x07),
    bb(n & 0xFF),
    bb((n >> 8) & 0xFF),
    bb((n >> 16) & 0xFF),
    bb((n >> 24) & 0xFF),
    b'.',
    b'F',
    b'I',
    b'T',
  ]
  for x in body {
    hdr.push(x)
  }
  hdr.push(bb(0))
  hdr.push(bb(0))
  Bytes::from_array(hdr)
}

///|
test "G6: verify accepts the pristine corpus file" {
  assert_true(@fit.verify(corpus0))
}

///|
test "G6: every single-byte mutation of the corpus is rejected" {
  let base = corpus0.to_array()
  let mut i = 0
  while i < base.length() {
    let mut_arr = base.copy()
    mut_arr[i] = mut_arr[i].lxor(b'\xff')
    assert_true(!@fit.verify(Bytes::from_array(mut_arr)))
    i = i + 1
  }
}

///|
test "G6: truncated and empty inputs are typed errors, not panics" {
  assert_true(!@fit.verify(Bytes::from_array([])))
  assert_true(!@fit.verify(Bytes::from_array([14, 0x10, 0, 0])))
  try @fit.parse_header(Bytes::from_array([14, 0x10, 0, 0])) catch {
    @fit.Truncated(_) => ()
    _ => fail("expected Truncated")
  } noraise {
    _ => fail("expected Truncated")
  }
}

///|
test "G6: bad signature / header size / header CRC are typed errors" {
  let bad_sig = Bytes::from_array([
    12, 0x10, 0xEA, 0x07, 0, 0, 0, 0, b'.', b'F', b'I', b'X', 0, 0,
  ])
  try @fit.parse_header(bad_sig) catch {
    @fit.BadSignature => ()
    _ => fail("expected BadSignature")
  } noraise {
    _ => fail("expected BadSignature")
  }
  let bad_size = Bytes::from_array([
    13, 0x10, 0xEA, 0x07, 0, 0, 0, 0, b'.', b'F', b'I', b'T', 0, 0,
  ])
  try @fit.parse_header(bad_size) catch {
    @fit.BadHeaderSize(13) => ()
    _ => fail("expected BadHeaderSize")
  } noraise {
    _ => fail("expected BadHeaderSize")
  }
}

///|
test "G6: data message without definition is a typed error" {
  let b = wrap12([bb(0)])
  try @fit.parse_messages(b) catch {
    @fit.NoDefinition(0) => ()
    _ => fail("expected NoDefinition")
  } noraise {
    _ => fail("expected NoDefinition")
  }
}

///|
test "G6: unknown base type is a typed error" {
  let body = [
    bb(0x40),
    bb(0),
    bb(0),
    bb(20),
    bb(0),
    bb(1),
    bb(0),
    bb(4),
    bb(0x99),
  ]
  try @fit.parse_messages(wrap12(body)) catch {
    @fit.UnknownBaseType(0x99) => ()
    _ => fail("expected UnknownBaseType")
  } noraise {
    _ => fail("expected UnknownBaseType")
  }
}

///|
test "G6: overlong field is a typed error" {
  let body = [
    bb(0x40),
    bb(0),
    bb(0),
    bb(20),
    bb(0),
    bb(1),
    bb(0),
    bb(252),
    bb(0x86),
    bb(0),
  ]
  try @fit.parse_messages(wrap12(body)) catch {
    @fit.Truncated(_) => ()
    _ => fail("expected Truncated")
  } noraise {
    _ => fail("expected Truncated")
  }
}
