///|
test "json_string escapes quote and backslash" {
  assert_eq(@json.json_escape("\""), "\\\"")
  assert_eq(@json.json_escape("\\"), "\\\\")
  assert_eq(@json.json_string("a\"b"), "\"a\\\"b\"")
}

///|
test "json_double maps non-finite to null" {
  assert_eq(@json.json_double(0.0 / 0.0), "null")
  assert_eq(@json.json_double(1.0 / 0.0), "null")
  assert_eq(@json.json_double(-1.0 / 0.0), "null")
  assert_eq(@json.json_double(1.5), "1.5")
}
