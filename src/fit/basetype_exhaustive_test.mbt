///|
// Exhaustive base-type round-trip and invalid-value tests (Gate G8 companion).
// Generated: every base type x both endiannesses x representative values, plus
// per-type invalid detection. Each is an independent binary assertion.

///|
test "bt Enum Little v0" {
  let enc = @fit.encode_base(@fit.Enum, @fit.Unsigned(0UL), @fit.Little)
  assert_eq(@fit.read_base(@fit.Enum, enc, 0, @fit.Little), @fit.Unsigned(0UL))
}

///|
test "bt Enum Little v1" {
  let enc = @fit.encode_base(@fit.Enum, @fit.Unsigned(1UL), @fit.Little)
  assert_eq(@fit.read_base(@fit.Enum, enc, 0, @fit.Little), @fit.Unsigned(1UL))
}

///|
test "bt Enum Little v2" {
  let enc = @fit.encode_base(@fit.Enum, @fit.Unsigned(127UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Enum, enc, 0, @fit.Little),
    @fit.Unsigned(127UL),
  )
}

///|
test "bt Enum Little v3" {
  let enc = @fit.encode_base(@fit.Enum, @fit.Unsigned(128UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Enum, enc, 0, @fit.Little),
    @fit.Unsigned(128UL),
  )
}

///|
test "bt Enum Little v4" {
  let enc = @fit.encode_base(@fit.Enum, @fit.Unsigned(255UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Enum, enc, 0, @fit.Little),
    @fit.Unsigned(255UL),
  )
}

///|
test "bt Enum Little v5" {
  let enc = @fit.encode_base(@fit.Enum, @fit.Unsigned(42UL), @fit.Little)
  assert_eq(@fit.read_base(@fit.Enum, enc, 0, @fit.Little), @fit.Unsigned(42UL))
}

///|
test "bt Enum Big v0" {
  let enc = @fit.encode_base(@fit.Enum, @fit.Unsigned(0UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Enum, enc, 0, @fit.Big), @fit.Unsigned(0UL))
}

///|
test "bt Enum Big v1" {
  let enc = @fit.encode_base(@fit.Enum, @fit.Unsigned(1UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Enum, enc, 0, @fit.Big), @fit.Unsigned(1UL))
}

///|
test "bt Enum Big v2" {
  let enc = @fit.encode_base(@fit.Enum, @fit.Unsigned(127UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Enum, enc, 0, @fit.Big), @fit.Unsigned(127UL))
}

///|
test "bt Enum Big v3" {
  let enc = @fit.encode_base(@fit.Enum, @fit.Unsigned(128UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Enum, enc, 0, @fit.Big), @fit.Unsigned(128UL))
}

///|
test "bt Enum Big v4" {
  let enc = @fit.encode_base(@fit.Enum, @fit.Unsigned(255UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Enum, enc, 0, @fit.Big), @fit.Unsigned(255UL))
}

///|
test "bt Enum Big v5" {
  let enc = @fit.encode_base(@fit.Enum, @fit.Unsigned(42UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Enum, enc, 0, @fit.Big), @fit.Unsigned(42UL))
}

///|
test "bt Sint8 Little v0" {
  let enc = @fit.encode_base(@fit.Sint8, @fit.Signed(-128L), @fit.Little)
  assert_eq(@fit.read_base(@fit.Sint8, enc, 0, @fit.Little), @fit.Signed(-128L))
}

///|
test "bt Sint8 Little v1" {
  let enc = @fit.encode_base(@fit.Sint8, @fit.Signed(-1L), @fit.Little)
  assert_eq(@fit.read_base(@fit.Sint8, enc, 0, @fit.Little), @fit.Signed(-1L))
}

///|
test "bt Sint8 Little v2" {
  let enc = @fit.encode_base(@fit.Sint8, @fit.Signed(0L), @fit.Little)
  assert_eq(@fit.read_base(@fit.Sint8, enc, 0, @fit.Little), @fit.Signed(0L))
}

///|
test "bt Sint8 Little v3" {
  let enc = @fit.encode_base(@fit.Sint8, @fit.Signed(1L), @fit.Little)
  assert_eq(@fit.read_base(@fit.Sint8, enc, 0, @fit.Little), @fit.Signed(1L))
}

///|
test "bt Sint8 Little v4" {
  let enc = @fit.encode_base(@fit.Sint8, @fit.Signed(127L), @fit.Little)
  assert_eq(@fit.read_base(@fit.Sint8, enc, 0, @fit.Little), @fit.Signed(127L))
}

///|
test "bt Sint8 Little v5" {
  let enc = @fit.encode_base(@fit.Sint8, @fit.Signed(42L), @fit.Little)
  assert_eq(@fit.read_base(@fit.Sint8, enc, 0, @fit.Little), @fit.Signed(42L))
}

///|
test "bt Sint8 Big v0" {
  let enc = @fit.encode_base(@fit.Sint8, @fit.Signed(-128L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint8, enc, 0, @fit.Big), @fit.Signed(-128L))
}

///|
test "bt Sint8 Big v1" {
  let enc = @fit.encode_base(@fit.Sint8, @fit.Signed(-1L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint8, enc, 0, @fit.Big), @fit.Signed(-1L))
}

///|
test "bt Sint8 Big v2" {
  let enc = @fit.encode_base(@fit.Sint8, @fit.Signed(0L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint8, enc, 0, @fit.Big), @fit.Signed(0L))
}

///|
test "bt Sint8 Big v3" {
  let enc = @fit.encode_base(@fit.Sint8, @fit.Signed(1L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint8, enc, 0, @fit.Big), @fit.Signed(1L))
}

///|
test "bt Sint8 Big v4" {
  let enc = @fit.encode_base(@fit.Sint8, @fit.Signed(127L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint8, enc, 0, @fit.Big), @fit.Signed(127L))
}

///|
test "bt Sint8 Big v5" {
  let enc = @fit.encode_base(@fit.Sint8, @fit.Signed(42L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint8, enc, 0, @fit.Big), @fit.Signed(42L))
}

///|
test "bt Uint8 Little v0" {
  let enc = @fit.encode_base(@fit.Uint8, @fit.Unsigned(0UL), @fit.Little)
  assert_eq(@fit.read_base(@fit.Uint8, enc, 0, @fit.Little), @fit.Unsigned(0UL))
}

///|
test "bt Uint8 Little v1" {
  let enc = @fit.encode_base(@fit.Uint8, @fit.Unsigned(1UL), @fit.Little)
  assert_eq(@fit.read_base(@fit.Uint8, enc, 0, @fit.Little), @fit.Unsigned(1UL))
}

///|
test "bt Uint8 Little v2" {
  let enc = @fit.encode_base(@fit.Uint8, @fit.Unsigned(127UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint8, enc, 0, @fit.Little),
    @fit.Unsigned(127UL),
  )
}

///|
test "bt Uint8 Little v3" {
  let enc = @fit.encode_base(@fit.Uint8, @fit.Unsigned(128UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint8, enc, 0, @fit.Little),
    @fit.Unsigned(128UL),
  )
}

///|
test "bt Uint8 Little v4" {
  let enc = @fit.encode_base(@fit.Uint8, @fit.Unsigned(255UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint8, enc, 0, @fit.Little),
    @fit.Unsigned(255UL),
  )
}

///|
test "bt Uint8 Little v5" {
  let enc = @fit.encode_base(@fit.Uint8, @fit.Unsigned(42UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint8, enc, 0, @fit.Little),
    @fit.Unsigned(42UL),
  )
}

///|
test "bt Uint8 Big v0" {
  let enc = @fit.encode_base(@fit.Uint8, @fit.Unsigned(0UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint8, enc, 0, @fit.Big), @fit.Unsigned(0UL))
}

///|
test "bt Uint8 Big v1" {
  let enc = @fit.encode_base(@fit.Uint8, @fit.Unsigned(1UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint8, enc, 0, @fit.Big), @fit.Unsigned(1UL))
}

///|
test "bt Uint8 Big v2" {
  let enc = @fit.encode_base(@fit.Uint8, @fit.Unsigned(127UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint8, enc, 0, @fit.Big), @fit.Unsigned(127UL))
}

///|
test "bt Uint8 Big v3" {
  let enc = @fit.encode_base(@fit.Uint8, @fit.Unsigned(128UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint8, enc, 0, @fit.Big), @fit.Unsigned(128UL))
}

///|
test "bt Uint8 Big v4" {
  let enc = @fit.encode_base(@fit.Uint8, @fit.Unsigned(255UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint8, enc, 0, @fit.Big), @fit.Unsigned(255UL))
}

///|
test "bt Uint8 Big v5" {
  let enc = @fit.encode_base(@fit.Uint8, @fit.Unsigned(42UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint8, enc, 0, @fit.Big), @fit.Unsigned(42UL))
}

///|
test "bt Sint16 Little v0" {
  let enc = @fit.encode_base(@fit.Sint16, @fit.Signed(-32768L), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Sint16, enc, 0, @fit.Little),
    @fit.Signed(-32768L),
  )
}

///|
test "bt Sint16 Little v1" {
  let enc = @fit.encode_base(@fit.Sint16, @fit.Signed(-1L), @fit.Little)
  assert_eq(@fit.read_base(@fit.Sint16, enc, 0, @fit.Little), @fit.Signed(-1L))
}

///|
test "bt Sint16 Little v2" {
  let enc = @fit.encode_base(@fit.Sint16, @fit.Signed(0L), @fit.Little)
  assert_eq(@fit.read_base(@fit.Sint16, enc, 0, @fit.Little), @fit.Signed(0L))
}

///|
test "bt Sint16 Little v3" {
  let enc = @fit.encode_base(@fit.Sint16, @fit.Signed(1L), @fit.Little)
  assert_eq(@fit.read_base(@fit.Sint16, enc, 0, @fit.Little), @fit.Signed(1L))
}

///|
test "bt Sint16 Little v4" {
  let enc = @fit.encode_base(@fit.Sint16, @fit.Signed(32767L), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Sint16, enc, 0, @fit.Little),
    @fit.Signed(32767L),
  )
}

///|
test "bt Sint16 Little v5" {
  let enc = @fit.encode_base(@fit.Sint16, @fit.Signed(1234L), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Sint16, enc, 0, @fit.Little),
    @fit.Signed(1234L),
  )
}

///|
test "bt Sint16 Big v0" {
  let enc = @fit.encode_base(@fit.Sint16, @fit.Signed(-32768L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint16, enc, 0, @fit.Big), @fit.Signed(-32768L))
}

///|
test "bt Sint16 Big v1" {
  let enc = @fit.encode_base(@fit.Sint16, @fit.Signed(-1L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint16, enc, 0, @fit.Big), @fit.Signed(-1L))
}

///|
test "bt Sint16 Big v2" {
  let enc = @fit.encode_base(@fit.Sint16, @fit.Signed(0L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint16, enc, 0, @fit.Big), @fit.Signed(0L))
}

///|
test "bt Sint16 Big v3" {
  let enc = @fit.encode_base(@fit.Sint16, @fit.Signed(1L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint16, enc, 0, @fit.Big), @fit.Signed(1L))
}

///|
test "bt Sint16 Big v4" {
  let enc = @fit.encode_base(@fit.Sint16, @fit.Signed(32767L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint16, enc, 0, @fit.Big), @fit.Signed(32767L))
}

///|
test "bt Sint16 Big v5" {
  let enc = @fit.encode_base(@fit.Sint16, @fit.Signed(1234L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint16, enc, 0, @fit.Big), @fit.Signed(1234L))
}

///|
test "bt Uint16 Little v0" {
  let enc = @fit.encode_base(@fit.Uint16, @fit.Unsigned(0UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint16, enc, 0, @fit.Little),
    @fit.Unsigned(0UL),
  )
}

///|
test "bt Uint16 Little v1" {
  let enc = @fit.encode_base(@fit.Uint16, @fit.Unsigned(1UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint16, enc, 0, @fit.Little),
    @fit.Unsigned(1UL),
  )
}

///|
test "bt Uint16 Little v2" {
  let enc = @fit.encode_base(@fit.Uint16, @fit.Unsigned(32768UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint16, enc, 0, @fit.Little),
    @fit.Unsigned(32768UL),
  )
}

///|
test "bt Uint16 Little v3" {
  let enc = @fit.encode_base(@fit.Uint16, @fit.Unsigned(65535UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint16, enc, 0, @fit.Little),
    @fit.Unsigned(65535UL),
  )
}

///|
test "bt Uint16 Little v4" {
  let enc = @fit.encode_base(@fit.Uint16, @fit.Unsigned(1234UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint16, enc, 0, @fit.Little),
    @fit.Unsigned(1234UL),
  )
}

///|
test "bt Uint16 Little v5" {
  let enc = @fit.encode_base(@fit.Uint16, @fit.Unsigned(255UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint16, enc, 0, @fit.Little),
    @fit.Unsigned(255UL),
  )
}

///|
test "bt Uint16 Big v0" {
  let enc = @fit.encode_base(@fit.Uint16, @fit.Unsigned(0UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint16, enc, 0, @fit.Big), @fit.Unsigned(0UL))
}

///|
test "bt Uint16 Big v1" {
  let enc = @fit.encode_base(@fit.Uint16, @fit.Unsigned(1UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint16, enc, 0, @fit.Big), @fit.Unsigned(1UL))
}

///|
test "bt Uint16 Big v2" {
  let enc = @fit.encode_base(@fit.Uint16, @fit.Unsigned(32768UL), @fit.Big)
  assert_eq(
    @fit.read_base(@fit.Uint16, enc, 0, @fit.Big),
    @fit.Unsigned(32768UL),
  )
}

///|
test "bt Uint16 Big v3" {
  let enc = @fit.encode_base(@fit.Uint16, @fit.Unsigned(65535UL), @fit.Big)
  assert_eq(
    @fit.read_base(@fit.Uint16, enc, 0, @fit.Big),
    @fit.Unsigned(65535UL),
  )
}

///|
test "bt Uint16 Big v4" {
  let enc = @fit.encode_base(@fit.Uint16, @fit.Unsigned(1234UL), @fit.Big)
  assert_eq(
    @fit.read_base(@fit.Uint16, enc, 0, @fit.Big),
    @fit.Unsigned(1234UL),
  )
}

///|
test "bt Uint16 Big v5" {
  let enc = @fit.encode_base(@fit.Uint16, @fit.Unsigned(255UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint16, enc, 0, @fit.Big), @fit.Unsigned(255UL))
}

///|
test "bt Sint32 Little v0" {
  let enc = @fit.encode_base(
    @fit.Sint32,
    @fit.Signed(-2147483648L),
    @fit.Little,
  )
  assert_eq(
    @fit.read_base(@fit.Sint32, enc, 0, @fit.Little),
    @fit.Signed(-2147483648L),
  )
}

///|
test "bt Sint32 Little v1" {
  let enc = @fit.encode_base(@fit.Sint32, @fit.Signed(-1L), @fit.Little)
  assert_eq(@fit.read_base(@fit.Sint32, enc, 0, @fit.Little), @fit.Signed(-1L))
}

///|
test "bt Sint32 Little v2" {
  let enc = @fit.encode_base(@fit.Sint32, @fit.Signed(0L), @fit.Little)
  assert_eq(@fit.read_base(@fit.Sint32, enc, 0, @fit.Little), @fit.Signed(0L))
}

///|
test "bt Sint32 Little v3" {
  let enc = @fit.encode_base(@fit.Sint32, @fit.Signed(1L), @fit.Little)
  assert_eq(@fit.read_base(@fit.Sint32, enc, 0, @fit.Little), @fit.Signed(1L))
}

///|
test "bt Sint32 Little v4" {
  let enc = @fit.encode_base(@fit.Sint32, @fit.Signed(2147483647L), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Sint32, enc, 0, @fit.Little),
    @fit.Signed(2147483647L),
  )
}

///|
test "bt Sint32 Little v5" {
  let enc = @fit.encode_base(@fit.Sint32, @fit.Signed(123456L), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Sint32, enc, 0, @fit.Little),
    @fit.Signed(123456L),
  )
}

///|
test "bt Sint32 Big v0" {
  let enc = @fit.encode_base(@fit.Sint32, @fit.Signed(-2147483648L), @fit.Big)
  assert_eq(
    @fit.read_base(@fit.Sint32, enc, 0, @fit.Big),
    @fit.Signed(-2147483648L),
  )
}

///|
test "bt Sint32 Big v1" {
  let enc = @fit.encode_base(@fit.Sint32, @fit.Signed(-1L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint32, enc, 0, @fit.Big), @fit.Signed(-1L))
}

///|
test "bt Sint32 Big v2" {
  let enc = @fit.encode_base(@fit.Sint32, @fit.Signed(0L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint32, enc, 0, @fit.Big), @fit.Signed(0L))
}

///|
test "bt Sint32 Big v3" {
  let enc = @fit.encode_base(@fit.Sint32, @fit.Signed(1L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint32, enc, 0, @fit.Big), @fit.Signed(1L))
}

///|
test "bt Sint32 Big v4" {
  let enc = @fit.encode_base(@fit.Sint32, @fit.Signed(2147483647L), @fit.Big)
  assert_eq(
    @fit.read_base(@fit.Sint32, enc, 0, @fit.Big),
    @fit.Signed(2147483647L),
  )
}

///|
test "bt Sint32 Big v5" {
  let enc = @fit.encode_base(@fit.Sint32, @fit.Signed(123456L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint32, enc, 0, @fit.Big), @fit.Signed(123456L))
}

///|
test "bt Uint32 Little v0" {
  let enc = @fit.encode_base(@fit.Uint32, @fit.Unsigned(0UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint32, enc, 0, @fit.Little),
    @fit.Unsigned(0UL),
  )
}

///|
test "bt Uint32 Little v1" {
  let enc = @fit.encode_base(@fit.Uint32, @fit.Unsigned(1UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint32, enc, 0, @fit.Little),
    @fit.Unsigned(1UL),
  )
}

///|
test "bt Uint32 Little v2" {
  let enc = @fit.encode_base(
    @fit.Uint32,
    @fit.Unsigned(2147483648UL),
    @fit.Little,
  )
  assert_eq(
    @fit.read_base(@fit.Uint32, enc, 0, @fit.Little),
    @fit.Unsigned(2147483648UL),
  )
}

///|
test "bt Uint32 Little v3" {
  let enc = @fit.encode_base(
    @fit.Uint32,
    @fit.Unsigned(4294967295UL),
    @fit.Little,
  )
  assert_eq(
    @fit.read_base(@fit.Uint32, enc, 0, @fit.Little),
    @fit.Unsigned(4294967295UL),
  )
}

///|
test "bt Uint32 Little v4" {
  let enc = @fit.encode_base(@fit.Uint32, @fit.Unsigned(123456UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint32, enc, 0, @fit.Little),
    @fit.Unsigned(123456UL),
  )
}

///|
test "bt Uint32 Little v5" {
  let enc = @fit.encode_base(@fit.Uint32, @fit.Unsigned(255UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint32, enc, 0, @fit.Little),
    @fit.Unsigned(255UL),
  )
}

///|
test "bt Uint32 Big v0" {
  let enc = @fit.encode_base(@fit.Uint32, @fit.Unsigned(0UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint32, enc, 0, @fit.Big), @fit.Unsigned(0UL))
}

///|
test "bt Uint32 Big v1" {
  let enc = @fit.encode_base(@fit.Uint32, @fit.Unsigned(1UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint32, enc, 0, @fit.Big), @fit.Unsigned(1UL))
}

///|
test "bt Uint32 Big v2" {
  let enc = @fit.encode_base(@fit.Uint32, @fit.Unsigned(2147483648UL), @fit.Big)
  assert_eq(
    @fit.read_base(@fit.Uint32, enc, 0, @fit.Big),
    @fit.Unsigned(2147483648UL),
  )
}

///|
test "bt Uint32 Big v3" {
  let enc = @fit.encode_base(@fit.Uint32, @fit.Unsigned(4294967295UL), @fit.Big)
  assert_eq(
    @fit.read_base(@fit.Uint32, enc, 0, @fit.Big),
    @fit.Unsigned(4294967295UL),
  )
}

///|
test "bt Uint32 Big v4" {
  let enc = @fit.encode_base(@fit.Uint32, @fit.Unsigned(123456UL), @fit.Big)
  assert_eq(
    @fit.read_base(@fit.Uint32, enc, 0, @fit.Big),
    @fit.Unsigned(123456UL),
  )
}

///|
test "bt Uint32 Big v5" {
  let enc = @fit.encode_base(@fit.Uint32, @fit.Unsigned(255UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint32, enc, 0, @fit.Big), @fit.Unsigned(255UL))
}

///|
test "bt Uint8z Little v0" {
  let enc = @fit.encode_base(@fit.Uint8z, @fit.Unsigned(0UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint8z, enc, 0, @fit.Little),
    @fit.Unsigned(0UL),
  )
}

///|
test "bt Uint8z Little v1" {
  let enc = @fit.encode_base(@fit.Uint8z, @fit.Unsigned(1UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint8z, enc, 0, @fit.Little),
    @fit.Unsigned(1UL),
  )
}

///|
test "bt Uint8z Little v2" {
  let enc = @fit.encode_base(@fit.Uint8z, @fit.Unsigned(127UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint8z, enc, 0, @fit.Little),
    @fit.Unsigned(127UL),
  )
}

///|
test "bt Uint8z Little v3" {
  let enc = @fit.encode_base(@fit.Uint8z, @fit.Unsigned(128UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint8z, enc, 0, @fit.Little),
    @fit.Unsigned(128UL),
  )
}

///|
test "bt Uint8z Little v4" {
  let enc = @fit.encode_base(@fit.Uint8z, @fit.Unsigned(255UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint8z, enc, 0, @fit.Little),
    @fit.Unsigned(255UL),
  )
}

///|
test "bt Uint8z Little v5" {
  let enc = @fit.encode_base(@fit.Uint8z, @fit.Unsigned(42UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint8z, enc, 0, @fit.Little),
    @fit.Unsigned(42UL),
  )
}

///|
test "bt Uint8z Big v0" {
  let enc = @fit.encode_base(@fit.Uint8z, @fit.Unsigned(0UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint8z, enc, 0, @fit.Big), @fit.Unsigned(0UL))
}

///|
test "bt Uint8z Big v1" {
  let enc = @fit.encode_base(@fit.Uint8z, @fit.Unsigned(1UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint8z, enc, 0, @fit.Big), @fit.Unsigned(1UL))
}

///|
test "bt Uint8z Big v2" {
  let enc = @fit.encode_base(@fit.Uint8z, @fit.Unsigned(127UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint8z, enc, 0, @fit.Big), @fit.Unsigned(127UL))
}

///|
test "bt Uint8z Big v3" {
  let enc = @fit.encode_base(@fit.Uint8z, @fit.Unsigned(128UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint8z, enc, 0, @fit.Big), @fit.Unsigned(128UL))
}

///|
test "bt Uint8z Big v4" {
  let enc = @fit.encode_base(@fit.Uint8z, @fit.Unsigned(255UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint8z, enc, 0, @fit.Big), @fit.Unsigned(255UL))
}

///|
test "bt Uint8z Big v5" {
  let enc = @fit.encode_base(@fit.Uint8z, @fit.Unsigned(42UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint8z, enc, 0, @fit.Big), @fit.Unsigned(42UL))
}

///|
test "bt Uint16z Little v0" {
  let enc = @fit.encode_base(@fit.Uint16z, @fit.Unsigned(0UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint16z, enc, 0, @fit.Little),
    @fit.Unsigned(0UL),
  )
}

///|
test "bt Uint16z Little v1" {
  let enc = @fit.encode_base(@fit.Uint16z, @fit.Unsigned(1UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint16z, enc, 0, @fit.Little),
    @fit.Unsigned(1UL),
  )
}

///|
test "bt Uint16z Little v2" {
  let enc = @fit.encode_base(@fit.Uint16z, @fit.Unsigned(32768UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint16z, enc, 0, @fit.Little),
    @fit.Unsigned(32768UL),
  )
}

///|
test "bt Uint16z Little v3" {
  let enc = @fit.encode_base(@fit.Uint16z, @fit.Unsigned(65535UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint16z, enc, 0, @fit.Little),
    @fit.Unsigned(65535UL),
  )
}

///|
test "bt Uint16z Little v4" {
  let enc = @fit.encode_base(@fit.Uint16z, @fit.Unsigned(1234UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint16z, enc, 0, @fit.Little),
    @fit.Unsigned(1234UL),
  )
}

///|
test "bt Uint16z Little v5" {
  let enc = @fit.encode_base(@fit.Uint16z, @fit.Unsigned(255UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint16z, enc, 0, @fit.Little),
    @fit.Unsigned(255UL),
  )
}

///|
test "bt Uint16z Big v0" {
  let enc = @fit.encode_base(@fit.Uint16z, @fit.Unsigned(0UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint16z, enc, 0, @fit.Big), @fit.Unsigned(0UL))
}

///|
test "bt Uint16z Big v1" {
  let enc = @fit.encode_base(@fit.Uint16z, @fit.Unsigned(1UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint16z, enc, 0, @fit.Big), @fit.Unsigned(1UL))
}

///|
test "bt Uint16z Big v2" {
  let enc = @fit.encode_base(@fit.Uint16z, @fit.Unsigned(32768UL), @fit.Big)
  assert_eq(
    @fit.read_base(@fit.Uint16z, enc, 0, @fit.Big),
    @fit.Unsigned(32768UL),
  )
}

///|
test "bt Uint16z Big v3" {
  let enc = @fit.encode_base(@fit.Uint16z, @fit.Unsigned(65535UL), @fit.Big)
  assert_eq(
    @fit.read_base(@fit.Uint16z, enc, 0, @fit.Big),
    @fit.Unsigned(65535UL),
  )
}

///|
test "bt Uint16z Big v4" {
  let enc = @fit.encode_base(@fit.Uint16z, @fit.Unsigned(1234UL), @fit.Big)
  assert_eq(
    @fit.read_base(@fit.Uint16z, enc, 0, @fit.Big),
    @fit.Unsigned(1234UL),
  )
}

///|
test "bt Uint16z Big v5" {
  let enc = @fit.encode_base(@fit.Uint16z, @fit.Unsigned(255UL), @fit.Big)
  assert_eq(
    @fit.read_base(@fit.Uint16z, enc, 0, @fit.Big),
    @fit.Unsigned(255UL),
  )
}

///|
test "bt Uint32z Little v0" {
  let enc = @fit.encode_base(@fit.Uint32z, @fit.Unsigned(0UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint32z, enc, 0, @fit.Little),
    @fit.Unsigned(0UL),
  )
}

///|
test "bt Uint32z Little v1" {
  let enc = @fit.encode_base(@fit.Uint32z, @fit.Unsigned(1UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint32z, enc, 0, @fit.Little),
    @fit.Unsigned(1UL),
  )
}

///|
test "bt Uint32z Little v2" {
  let enc = @fit.encode_base(
    @fit.Uint32z,
    @fit.Unsigned(2147483648UL),
    @fit.Little,
  )
  assert_eq(
    @fit.read_base(@fit.Uint32z, enc, 0, @fit.Little),
    @fit.Unsigned(2147483648UL),
  )
}

///|
test "bt Uint32z Little v3" {
  let enc = @fit.encode_base(
    @fit.Uint32z,
    @fit.Unsigned(4294967295UL),
    @fit.Little,
  )
  assert_eq(
    @fit.read_base(@fit.Uint32z, enc, 0, @fit.Little),
    @fit.Unsigned(4294967295UL),
  )
}

///|
test "bt Uint32z Little v4" {
  let enc = @fit.encode_base(@fit.Uint32z, @fit.Unsigned(123456UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint32z, enc, 0, @fit.Little),
    @fit.Unsigned(123456UL),
  )
}

///|
test "bt Uint32z Little v5" {
  let enc = @fit.encode_base(@fit.Uint32z, @fit.Unsigned(255UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint32z, enc, 0, @fit.Little),
    @fit.Unsigned(255UL),
  )
}

///|
test "bt Uint32z Big v0" {
  let enc = @fit.encode_base(@fit.Uint32z, @fit.Unsigned(0UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint32z, enc, 0, @fit.Big), @fit.Unsigned(0UL))
}

///|
test "bt Uint32z Big v1" {
  let enc = @fit.encode_base(@fit.Uint32z, @fit.Unsigned(1UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint32z, enc, 0, @fit.Big), @fit.Unsigned(1UL))
}

///|
test "bt Uint32z Big v2" {
  let enc = @fit.encode_base(
    @fit.Uint32z,
    @fit.Unsigned(2147483648UL),
    @fit.Big,
  )
  assert_eq(
    @fit.read_base(@fit.Uint32z, enc, 0, @fit.Big),
    @fit.Unsigned(2147483648UL),
  )
}

///|
test "bt Uint32z Big v3" {
  let enc = @fit.encode_base(
    @fit.Uint32z,
    @fit.Unsigned(4294967295UL),
    @fit.Big,
  )
  assert_eq(
    @fit.read_base(@fit.Uint32z, enc, 0, @fit.Big),
    @fit.Unsigned(4294967295UL),
  )
}

///|
test "bt Uint32z Big v4" {
  let enc = @fit.encode_base(@fit.Uint32z, @fit.Unsigned(123456UL), @fit.Big)
  assert_eq(
    @fit.read_base(@fit.Uint32z, enc, 0, @fit.Big),
    @fit.Unsigned(123456UL),
  )
}

///|
test "bt Uint32z Big v5" {
  let enc = @fit.encode_base(@fit.Uint32z, @fit.Unsigned(255UL), @fit.Big)
  assert_eq(
    @fit.read_base(@fit.Uint32z, enc, 0, @fit.Big),
    @fit.Unsigned(255UL),
  )
}

///|
test "bt Byte Little v0" {
  let enc = @fit.encode_base(@fit.Byte, @fit.Unsigned(0UL), @fit.Little)
  assert_eq(@fit.read_base(@fit.Byte, enc, 0, @fit.Little), @fit.Unsigned(0UL))
}

///|
test "bt Byte Little v1" {
  let enc = @fit.encode_base(@fit.Byte, @fit.Unsigned(1UL), @fit.Little)
  assert_eq(@fit.read_base(@fit.Byte, enc, 0, @fit.Little), @fit.Unsigned(1UL))
}

///|
test "bt Byte Little v2" {
  let enc = @fit.encode_base(@fit.Byte, @fit.Unsigned(127UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Byte, enc, 0, @fit.Little),
    @fit.Unsigned(127UL),
  )
}

///|
test "bt Byte Little v3" {
  let enc = @fit.encode_base(@fit.Byte, @fit.Unsigned(128UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Byte, enc, 0, @fit.Little),
    @fit.Unsigned(128UL),
  )
}

///|
test "bt Byte Little v4" {
  let enc = @fit.encode_base(@fit.Byte, @fit.Unsigned(255UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Byte, enc, 0, @fit.Little),
    @fit.Unsigned(255UL),
  )
}

///|
test "bt Byte Little v5" {
  let enc = @fit.encode_base(@fit.Byte, @fit.Unsigned(42UL), @fit.Little)
  assert_eq(@fit.read_base(@fit.Byte, enc, 0, @fit.Little), @fit.Unsigned(42UL))
}

///|
test "bt Byte Big v0" {
  let enc = @fit.encode_base(@fit.Byte, @fit.Unsigned(0UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Byte, enc, 0, @fit.Big), @fit.Unsigned(0UL))
}

///|
test "bt Byte Big v1" {
  let enc = @fit.encode_base(@fit.Byte, @fit.Unsigned(1UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Byte, enc, 0, @fit.Big), @fit.Unsigned(1UL))
}

///|
test "bt Byte Big v2" {
  let enc = @fit.encode_base(@fit.Byte, @fit.Unsigned(127UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Byte, enc, 0, @fit.Big), @fit.Unsigned(127UL))
}

///|
test "bt Byte Big v3" {
  let enc = @fit.encode_base(@fit.Byte, @fit.Unsigned(128UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Byte, enc, 0, @fit.Big), @fit.Unsigned(128UL))
}

///|
test "bt Byte Big v4" {
  let enc = @fit.encode_base(@fit.Byte, @fit.Unsigned(255UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Byte, enc, 0, @fit.Big), @fit.Unsigned(255UL))
}

///|
test "bt Byte Big v5" {
  let enc = @fit.encode_base(@fit.Byte, @fit.Unsigned(42UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Byte, enc, 0, @fit.Big), @fit.Unsigned(42UL))
}

///|
test "bt Sint64 Little v0" {
  let enc = @fit.encode_base(
    @fit.Sint64,
    @fit.Signed(-9223372036854775808L),
    @fit.Little,
  )
  assert_eq(
    @fit.read_base(@fit.Sint64, enc, 0, @fit.Little),
    @fit.Signed(-9223372036854775808L),
  )
}

///|
test "bt Sint64 Little v1" {
  let enc = @fit.encode_base(@fit.Sint64, @fit.Signed(-1L), @fit.Little)
  assert_eq(@fit.read_base(@fit.Sint64, enc, 0, @fit.Little), @fit.Signed(-1L))
}

///|
test "bt Sint64 Little v2" {
  let enc = @fit.encode_base(@fit.Sint64, @fit.Signed(0L), @fit.Little)
  assert_eq(@fit.read_base(@fit.Sint64, enc, 0, @fit.Little), @fit.Signed(0L))
}

///|
test "bt Sint64 Little v3" {
  let enc = @fit.encode_base(@fit.Sint64, @fit.Signed(1L), @fit.Little)
  assert_eq(@fit.read_base(@fit.Sint64, enc, 0, @fit.Little), @fit.Signed(1L))
}

///|
test "bt Sint64 Little v4" {
  let enc = @fit.encode_base(
    @fit.Sint64,
    @fit.Signed(9223372036854775807L),
    @fit.Little,
  )
  assert_eq(
    @fit.read_base(@fit.Sint64, enc, 0, @fit.Little),
    @fit.Signed(9223372036854775807L),
  )
}

///|
test "bt Sint64 Little v5" {
  let enc = @fit.encode_base(@fit.Sint64, @fit.Signed(123L), @fit.Little)
  assert_eq(@fit.read_base(@fit.Sint64, enc, 0, @fit.Little), @fit.Signed(123L))
}

///|
test "bt Sint64 Big v0" {
  let enc = @fit.encode_base(
    @fit.Sint64,
    @fit.Signed(-9223372036854775808L),
    @fit.Big,
  )
  assert_eq(
    @fit.read_base(@fit.Sint64, enc, 0, @fit.Big),
    @fit.Signed(-9223372036854775808L),
  )
}

///|
test "bt Sint64 Big v1" {
  let enc = @fit.encode_base(@fit.Sint64, @fit.Signed(-1L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint64, enc, 0, @fit.Big), @fit.Signed(-1L))
}

///|
test "bt Sint64 Big v2" {
  let enc = @fit.encode_base(@fit.Sint64, @fit.Signed(0L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint64, enc, 0, @fit.Big), @fit.Signed(0L))
}

///|
test "bt Sint64 Big v3" {
  let enc = @fit.encode_base(@fit.Sint64, @fit.Signed(1L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint64, enc, 0, @fit.Big), @fit.Signed(1L))
}

///|
test "bt Sint64 Big v4" {
  let enc = @fit.encode_base(
    @fit.Sint64,
    @fit.Signed(9223372036854775807L),
    @fit.Big,
  )
  assert_eq(
    @fit.read_base(@fit.Sint64, enc, 0, @fit.Big),
    @fit.Signed(9223372036854775807L),
  )
}

///|
test "bt Sint64 Big v5" {
  let enc = @fit.encode_base(@fit.Sint64, @fit.Signed(123L), @fit.Big)
  assert_eq(@fit.read_base(@fit.Sint64, enc, 0, @fit.Big), @fit.Signed(123L))
}

///|
test "bt Uint64 Little v0" {
  let enc = @fit.encode_base(@fit.Uint64, @fit.Unsigned(0UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint64, enc, 0, @fit.Little),
    @fit.Unsigned(0UL),
  )
}

///|
test "bt Uint64 Little v1" {
  let enc = @fit.encode_base(@fit.Uint64, @fit.Unsigned(1UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint64, enc, 0, @fit.Little),
    @fit.Unsigned(1UL),
  )
}

///|
test "bt Uint64 Little v2" {
  let enc = @fit.encode_base(
    @fit.Uint64,
    @fit.Unsigned(9223372036854775808UL),
    @fit.Little,
  )
  assert_eq(
    @fit.read_base(@fit.Uint64, enc, 0, @fit.Little),
    @fit.Unsigned(9223372036854775808UL),
  )
}

///|
test "bt Uint64 Little v3" {
  let enc = @fit.encode_base(
    @fit.Uint64,
    @fit.Unsigned(18446744073709551615UL),
    @fit.Little,
  )
  assert_eq(
    @fit.read_base(@fit.Uint64, enc, 0, @fit.Little),
    @fit.Unsigned(18446744073709551615UL),
  )
}

///|
test "bt Uint64 Little v4" {
  let enc = @fit.encode_base(@fit.Uint64, @fit.Unsigned(123UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint64, enc, 0, @fit.Little),
    @fit.Unsigned(123UL),
  )
}

///|
test "bt Uint64 Little v5" {
  let enc = @fit.encode_base(@fit.Uint64, @fit.Unsigned(255UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint64, enc, 0, @fit.Little),
    @fit.Unsigned(255UL),
  )
}

///|
test "bt Uint64 Big v0" {
  let enc = @fit.encode_base(@fit.Uint64, @fit.Unsigned(0UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint64, enc, 0, @fit.Big), @fit.Unsigned(0UL))
}

///|
test "bt Uint64 Big v1" {
  let enc = @fit.encode_base(@fit.Uint64, @fit.Unsigned(1UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint64, enc, 0, @fit.Big), @fit.Unsigned(1UL))
}

///|
test "bt Uint64 Big v2" {
  let enc = @fit.encode_base(
    @fit.Uint64,
    @fit.Unsigned(9223372036854775808UL),
    @fit.Big,
  )
  assert_eq(
    @fit.read_base(@fit.Uint64, enc, 0, @fit.Big),
    @fit.Unsigned(9223372036854775808UL),
  )
}

///|
test "bt Uint64 Big v3" {
  let enc = @fit.encode_base(
    @fit.Uint64,
    @fit.Unsigned(18446744073709551615UL),
    @fit.Big,
  )
  assert_eq(
    @fit.read_base(@fit.Uint64, enc, 0, @fit.Big),
    @fit.Unsigned(18446744073709551615UL),
  )
}

///|
test "bt Uint64 Big v4" {
  let enc = @fit.encode_base(@fit.Uint64, @fit.Unsigned(123UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint64, enc, 0, @fit.Big), @fit.Unsigned(123UL))
}

///|
test "bt Uint64 Big v5" {
  let enc = @fit.encode_base(@fit.Uint64, @fit.Unsigned(255UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint64, enc, 0, @fit.Big), @fit.Unsigned(255UL))
}

///|
test "bt Uint64z Little v0" {
  let enc = @fit.encode_base(@fit.Uint64z, @fit.Unsigned(0UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint64z, enc, 0, @fit.Little),
    @fit.Unsigned(0UL),
  )
}

///|
test "bt Uint64z Little v1" {
  let enc = @fit.encode_base(@fit.Uint64z, @fit.Unsigned(1UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint64z, enc, 0, @fit.Little),
    @fit.Unsigned(1UL),
  )
}

///|
test "bt Uint64z Little v2" {
  let enc = @fit.encode_base(
    @fit.Uint64z,
    @fit.Unsigned(9223372036854775808UL),
    @fit.Little,
  )
  assert_eq(
    @fit.read_base(@fit.Uint64z, enc, 0, @fit.Little),
    @fit.Unsigned(9223372036854775808UL),
  )
}

///|
test "bt Uint64z Little v3" {
  let enc = @fit.encode_base(
    @fit.Uint64z,
    @fit.Unsigned(18446744073709551615UL),
    @fit.Little,
  )
  assert_eq(
    @fit.read_base(@fit.Uint64z, enc, 0, @fit.Little),
    @fit.Unsigned(18446744073709551615UL),
  )
}

///|
test "bt Uint64z Little v4" {
  let enc = @fit.encode_base(@fit.Uint64z, @fit.Unsigned(123UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint64z, enc, 0, @fit.Little),
    @fit.Unsigned(123UL),
  )
}

///|
test "bt Uint64z Little v5" {
  let enc = @fit.encode_base(@fit.Uint64z, @fit.Unsigned(255UL), @fit.Little)
  assert_eq(
    @fit.read_base(@fit.Uint64z, enc, 0, @fit.Little),
    @fit.Unsigned(255UL),
  )
}

///|
test "bt Uint64z Big v0" {
  let enc = @fit.encode_base(@fit.Uint64z, @fit.Unsigned(0UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint64z, enc, 0, @fit.Big), @fit.Unsigned(0UL))
}

///|
test "bt Uint64z Big v1" {
  let enc = @fit.encode_base(@fit.Uint64z, @fit.Unsigned(1UL), @fit.Big)
  assert_eq(@fit.read_base(@fit.Uint64z, enc, 0, @fit.Big), @fit.Unsigned(1UL))
}

///|
test "bt Uint64z Big v2" {
  let enc = @fit.encode_base(
    @fit.Uint64z,
    @fit.Unsigned(9223372036854775808UL),
    @fit.Big,
  )
  assert_eq(
    @fit.read_base(@fit.Uint64z, enc, 0, @fit.Big),
    @fit.Unsigned(9223372036854775808UL),
  )
}

///|
test "bt Uint64z Big v3" {
  let enc = @fit.encode_base(
    @fit.Uint64z,
    @fit.Unsigned(18446744073709551615UL),
    @fit.Big,
  )
  assert_eq(
    @fit.read_base(@fit.Uint64z, enc, 0, @fit.Big),
    @fit.Unsigned(18446744073709551615UL),
  )
}

///|
test "bt Uint64z Big v4" {
  let enc = @fit.encode_base(@fit.Uint64z, @fit.Unsigned(123UL), @fit.Big)
  assert_eq(
    @fit.read_base(@fit.Uint64z, enc, 0, @fit.Big),
    @fit.Unsigned(123UL),
  )
}

///|
test "bt Uint64z Big v5" {
  let enc = @fit.encode_base(@fit.Uint64z, @fit.Unsigned(255UL), @fit.Big)
  assert_eq(
    @fit.read_base(@fit.Uint64z, enc, 0, @fit.Big),
    @fit.Unsigned(255UL),
  )
}

///|
test "bt Float32 Little v0" {
  let enc = @fit.encode_base(@fit.Float32, @fit.Real(0.0), @fit.Little)
  assert_eq(@fit.read_base(@fit.Float32, enc, 0, @fit.Little), @fit.Real(0.0))
}

///|
test "bt Float32 Little v1" {
  let enc = @fit.encode_base(@fit.Float32, @fit.Real(1.5), @fit.Little)
  assert_eq(@fit.read_base(@fit.Float32, enc, 0, @fit.Little), @fit.Real(1.5))
}

///|
test "bt Float32 Little v2" {
  let enc = @fit.encode_base(@fit.Float32, @fit.Real(-2.25), @fit.Little)
  assert_eq(@fit.read_base(@fit.Float32, enc, 0, @fit.Little), @fit.Real(-2.25))
}

///|
test "bt Float32 Little v3" {
  let enc = @fit.encode_base(@fit.Float32, @fit.Real(100.0), @fit.Little)
  assert_eq(@fit.read_base(@fit.Float32, enc, 0, @fit.Little), @fit.Real(100.0))
}

///|
test "bt Float32 Big v0" {
  let enc = @fit.encode_base(@fit.Float32, @fit.Real(0.0), @fit.Big)
  assert_eq(@fit.read_base(@fit.Float32, enc, 0, @fit.Big), @fit.Real(0.0))
}

///|
test "bt Float32 Big v1" {
  let enc = @fit.encode_base(@fit.Float32, @fit.Real(1.5), @fit.Big)
  assert_eq(@fit.read_base(@fit.Float32, enc, 0, @fit.Big), @fit.Real(1.5))
}

///|
test "bt Float32 Big v2" {
  let enc = @fit.encode_base(@fit.Float32, @fit.Real(-2.25), @fit.Big)
  assert_eq(@fit.read_base(@fit.Float32, enc, 0, @fit.Big), @fit.Real(-2.25))
}

///|
test "bt Float32 Big v3" {
  let enc = @fit.encode_base(@fit.Float32, @fit.Real(100.0), @fit.Big)
  assert_eq(@fit.read_base(@fit.Float32, enc, 0, @fit.Big), @fit.Real(100.0))
}

///|
test "bt Float64 Little v0" {
  let enc = @fit.encode_base(@fit.Float64, @fit.Real(0.0), @fit.Little)
  assert_eq(@fit.read_base(@fit.Float64, enc, 0, @fit.Little), @fit.Real(0.0))
}

///|
test "bt Float64 Little v1" {
  let enc = @fit.encode_base(@fit.Float64, @fit.Real(1.5), @fit.Little)
  assert_eq(@fit.read_base(@fit.Float64, enc, 0, @fit.Little), @fit.Real(1.5))
}

///|
test "bt Float64 Little v2" {
  let enc = @fit.encode_base(@fit.Float64, @fit.Real(-2.25), @fit.Little)
  assert_eq(@fit.read_base(@fit.Float64, enc, 0, @fit.Little), @fit.Real(-2.25))
}

///|
test "bt Float64 Little v3" {
  let enc = @fit.encode_base(
    @fit.Float64,
    @fit.Real(3.141592653589793),
    @fit.Little,
  )
  assert_eq(
    @fit.read_base(@fit.Float64, enc, 0, @fit.Little),
    @fit.Real(3.141592653589793),
  )
}

///|
test "bt Float64 Big v0" {
  let enc = @fit.encode_base(@fit.Float64, @fit.Real(0.0), @fit.Big)
  assert_eq(@fit.read_base(@fit.Float64, enc, 0, @fit.Big), @fit.Real(0.0))
}

///|
test "bt Float64 Big v1" {
  let enc = @fit.encode_base(@fit.Float64, @fit.Real(1.5), @fit.Big)
  assert_eq(@fit.read_base(@fit.Float64, enc, 0, @fit.Big), @fit.Real(1.5))
}

///|
test "bt Float64 Big v2" {
  let enc = @fit.encode_base(@fit.Float64, @fit.Real(-2.25), @fit.Big)
  assert_eq(@fit.read_base(@fit.Float64, enc, 0, @fit.Big), @fit.Real(-2.25))
}

///|
test "bt Float64 Big v3" {
  let enc = @fit.encode_base(
    @fit.Float64,
    @fit.Real(3.141592653589793),
    @fit.Big,
  )
  assert_eq(
    @fit.read_base(@fit.Float64, enc, 0, @fit.Big),
    @fit.Real(3.141592653589793),
  )
}

///|
test "bt Str Little v0" {
  let enc = @fit.encode_base(@fit.Str, @fit.Text(""), @fit.Little)
  assert_eq(@fit.read_base(@fit.Str, enc, 0, @fit.Little), @fit.Text(""))
}

///|
test "bt Str Little v1" {
  let enc = @fit.encode_base(@fit.Str, @fit.Text("a"), @fit.Little)
  assert_eq(@fit.read_base(@fit.Str, enc, 0, @fit.Little), @fit.Text("a"))
}

///|
test "bt Str Little v2" {
  let enc = @fit.encode_base(@fit.Str, @fit.Text("hello"), @fit.Little)
  assert_eq(@fit.read_base(@fit.Str, enc, 0, @fit.Little), @fit.Text("hello"))
}

///|
test "bt Str Big v0" {
  let enc = @fit.encode_base(@fit.Str, @fit.Text(""), @fit.Big)
  assert_eq(@fit.read_base(@fit.Str, enc, 0, @fit.Big), @fit.Text(""))
}

///|
test "bt Str Big v1" {
  let enc = @fit.encode_base(@fit.Str, @fit.Text("a"), @fit.Big)
  assert_eq(@fit.read_base(@fit.Str, enc, 0, @fit.Big), @fit.Text("a"))
}

///|
test "bt Str Big v2" {
  let enc = @fit.encode_base(@fit.Str, @fit.Text("hello"), @fit.Big)
  assert_eq(@fit.read_base(@fit.Str, enc, 0, @fit.Big), @fit.Text("hello"))
}

///|
test "invalid Enum" {
  assert_true(
    @fit.is_invalid(@fit.Enum, Bytes::from_array([bb(0xFF)]), 0, @fit.Little),
  )
}

///|
test "invalid Sint8" {
  assert_true(
    @fit.is_invalid(@fit.Sint8, Bytes::from_array([bb(0x7F)]), 0, @fit.Little),
  )
}

///|
test "invalid Uint8" {
  assert_true(
    @fit.is_invalid(@fit.Uint8, Bytes::from_array([bb(0xFF)]), 0, @fit.Little),
  )
}

///|
test "invalid Sint16" {
  assert_true(
    @fit.is_invalid(
      @fit.Sint16,
      Bytes::from_array([bb(0xFF), bb(0x7F)]),
      0,
      @fit.Little,
    ),
  )
}

///|
test "invalid Uint16" {
  assert_true(
    @fit.is_invalid(
      @fit.Uint16,
      Bytes::from_array([bb(0xFF), bb(0xFF)]),
      0,
      @fit.Little,
    ),
  )
}

///|
test "invalid Sint32" {
  assert_true(
    @fit.is_invalid(
      @fit.Sint32,
      Bytes::from_array([bb(0xFF), bb(0xFF), bb(0xFF), bb(0x7F)]),
      0,
      @fit.Little,
    ),
  )
}

///|
test "invalid Uint32" {
  assert_true(
    @fit.is_invalid(
      @fit.Uint32,
      Bytes::from_array([bb(0xFF), bb(0xFF), bb(0xFF), bb(0xFF)]),
      0,
      @fit.Little,
    ),
  )
}

///|
test "invalid Uint8z" {
  assert_true(
    @fit.is_invalid(@fit.Uint8z, Bytes::from_array([bb(0)]), 0, @fit.Little),
  )
}

///|
test "invalid Uint16z" {
  assert_true(
    @fit.is_invalid(
      @fit.Uint16z,
      Bytes::from_array([bb(0), bb(0)]),
      0,
      @fit.Little,
    ),
  )
}

///|
test "invalid Uint32z" {
  assert_true(
    @fit.is_invalid(
      @fit.Uint32z,
      Bytes::from_array([bb(0), bb(0), bb(0), bb(0)]),
      0,
      @fit.Little,
    ),
  )
}

///|
test "invalid Byte" {
  assert_true(
    @fit.is_invalid(@fit.Byte, Bytes::from_array([bb(0xFF)]), 0, @fit.Little),
  )
}

///|
test "invalid Sint64" {
  assert_true(
    @fit.is_invalid(
      @fit.Sint64,
      Bytes::from_array([
        bb(0xFF),
        bb(0xFF),
        bb(0xFF),
        bb(0xFF),
        bb(0xFF),
        bb(0xFF),
        bb(0xFF),
        bb(0x7F),
      ]),
      0,
      @fit.Little,
    ),
  )
}

///|
test "invalid Uint64" {
  assert_true(
    @fit.is_invalid(
      @fit.Uint64,
      Bytes::from_array([
        bb(0xFF),
        bb(0xFF),
        bb(0xFF),
        bb(0xFF),
        bb(0xFF),
        bb(0xFF),
        bb(0xFF),
        bb(0xFF),
      ]),
      0,
      @fit.Little,
    ),
  )
}

///|
test "invalid Uint64z" {
  assert_true(
    @fit.is_invalid(
      @fit.Uint64z,
      Bytes::from_array([bb(0), bb(0), bb(0), bb(0), bb(0), bb(0), bb(0), bb(0)]),
      0,
      @fit.Little,
    ),
  )
}

///|
test "invalid Float32" {
  assert_true(
    @fit.is_invalid(
      @fit.Float32,
      Bytes::from_array([bb(0xFF), bb(0xFF), bb(0xFF), bb(0xFF)]),
      0,
      @fit.Little,
    ),
  )
}

///|
test "invalid Float64" {
  assert_true(
    @fit.is_invalid(
      @fit.Float64,
      Bytes::from_array([
        bb(0xFF),
        bb(0xFF),
        bb(0xFF),
        bb(0xFF),
        bb(0xFF),
        bb(0xFF),
        bb(0xFF),
        bb(0xFF),
      ]),
      0,
      @fit.Little,
    ),
  )
}
