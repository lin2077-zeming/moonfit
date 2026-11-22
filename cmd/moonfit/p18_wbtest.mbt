///|
test "P1-8: parse_bounds rejects malformed / non-increasing / duplicate / empty" {
  assert_eq(parse_bounds("abc,,140"), None)
  assert_eq(parse_bounds("160,100"), None)
  assert_eq(parse_bounds("100,100"), None)
  assert_eq(parse_bounds(""), None)
  assert_eq(parse_bounds("100,120,140"), Some([100, 120, 140]))
}

///|
test "P1-8: parse_window requires a positive integer" {
  assert_eq(parse_window("-1"), None)
  assert_eq(parse_window("0"), None)
  assert_eq(parse_window("abc"), None)
  assert_eq(parse_window("3"), Some(3))
}
