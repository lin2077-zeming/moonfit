///|
// Unified JSON serialization helpers. All JSON output in the CLI and in
// metrics/diff goes through these so strings are always properly escaped
// (including 0x00-0x1F control characters) and non-finite numbers become null
// rather than bare NaN/Infinity (which are not valid JSON).

///|
fn hexdigit(n : Int32) -> String {
  match n {
    0 => "0"
    1 => "1"
    2 => "2"
    3 => "3"
    4 => "4"
    5 => "5"
    6 => "6"
    7 => "7"
    8 => "8"
    9 => "9"
    10 => "a"
    11 => "b"
    12 => "c"
    13 => "d"
    14 => "e"
    15 => "f"
    _ => "0"
  }
}

///|
fn hex2(n : Int32) -> String {
  hexdigit((n >> 4) & 0xF) + hexdigit(n & 0xF)
}

///|
pub fn json_escape(s : String) -> String {
  let mut out = ""
  for c in s {
    let code = c.to_int()
    if c == '"' {
      out = out + "\\\""
    } else if c == '\\' {
      out = out + "\\\\"
    } else if code < 0x20 {
      out = out + "\\u00" + hex2(code)
    } else {
      out = out + c.to_string()
    }
  }
  out
}

///|
pub fn json_string(s : String) -> String {
  "\"" + json_escape(s) + "\""
}

///|
pub fn json_double(d : Double) -> String {
  let inf = 1.0 / 0.0
  if d != d || d == inf || d == -inf {
    "null"
  } else {
    d.to_string()
  }
}
