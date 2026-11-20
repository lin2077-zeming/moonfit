///|
// `moonfit dump <file.fit>` prints one JSON object per data message, in file
// order, with raw (unscaled) field values. This is the substrate for the G3
// differential gate, which compares it against an independent decoder.
// Array / opaque fields are reported as a raw byte count, not decoded.

///|
fn escape(s : String) -> String {
  let mut out = ""
  for c in s {
    match c {
      '"' => out = out + "\\\""
      '\\' => out = out + "\\\\"
      '\n' => out = out + "\\n"
      '\r' => out = out + "\\r"
      '\t' => out = out + "\\t"
      _ => out = out + c.to_string()
    }
  }
  out
}

///|
fn value_json(v : @fit.BaseValue, invalid : Bool) -> String {
  match v {
    @fit.Array(elems) => {
      let mut parts = ""
      let mut i = 0
      for e in elems {
        if i > 0 {
          parts = parts + ","
        }
        parts = parts + value_json(e, false)
        i = i + 1
      }
      "[" + parts + "]"
    }
    @fit.Signed(x) => if invalid { "null" } else { x.to_string() }
    @fit.Unsigned(x) => if invalid { "null" } else { x.to_string() }
    @fit.Real(d) => if invalid { "null" } else { d.to_string() }
    @fit.Text(t) => if invalid { "null" } else { "\"" + escape(t) + "\"" }
    @fit.Raw(b) => if invalid { "null" } else { "\"raw:\{b.length()}\"" }
  }
}

///|
fn run_dump(argv : Array[String]) -> Int32 {
  if argv.length() < 2 {
    eprintln("moonfit: dump needs a file argument")
    return 2
  }
  let path = argv[1]
  let data = @fs.read_file_to_bytes(path) catch {
    @fs.IOError(_) => {
      eprintln("moonfit: cannot read \{path}")
      return 2
    }
  }
  let msgs = @fit.parse_messages(data) catch {
    _ => {
      eprintln("moonfit: cannot decode \{path}")
      return 2
    }
  }
  for m in @fit.data_messages(msgs) {
    let ts = match m.ts_offset {
      Some(t) => t.to_string()
      None => "null"
    }
    let mut fj = ""
    let mut i = 0
    for f in m.fields {
      if i > 0 {
        fj = fj + ","
      }
      let inv = if f.invalid { 1 } else { 0 }
      fj = fj +
        "{\"d\":" +
        f.def_num.to_string() +
        ",\"v\":" +
        value_json(f.value, f.invalid) +
        ",\"i\":" +
        inv.to_string() +
        "}"
      i = i + 1
    }
    println(
      "{\"g\":\{m.global},\"l\":\{m.local_id},\"ts\":\{ts},\"f\":[\{fj}]}",
    )
  }
  0
}
