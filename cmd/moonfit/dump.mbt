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

///|
fn run_roundtrip(argv : Array[String]) -> Int32 {
  if argv.length() < 3 {
    eprintln("moonfit: roundtrip needs <in.fit> <out.fit>")
    return 2
  }
  let data = @fs.read_file_to_bytes(argv[1]) catch {
    @fs.IOError(_) => {
      eprintln("moonfit: cannot read \{argv[1]}")
      return 2
    }
  }
  let out = @fit.encode_fit(data) catch {
    _ => {
      eprintln("moonfit: cannot re-encode \{argv[1]}")
      return 2
    }
  }
  @fs.write_bytes_to_file(argv[2], out) catch {
    @fs.IOError(_) => {
      eprintln("moonfit: cannot write \{argv[2]}")
      return 2
    }
  }
  0
}

///|
fn to_int_def(s : String, def : Int32) -> Int32 {
  @string.parse_int(s) catch {
    _ => def
  }
}

///|
fn parse_bounds(csv : String) -> Array[Int32] {
  let out : Array[Int32] = []
  if csv == "" {
    return out
  }
  let mut cur = ""
  for c in csv {
    if c == ',' {
      out.push(to_int_def(cur, 0))
      cur = ""
    } else {
      cur = cur + c.to_string()
    }
  }
  out.push(to_int_def(cur, 0))
  out
}

///|
fn run_metrics(argv : Array[String]) -> Int32 {
  if argv.length() < 2 {
    eprintln("moonfit: metrics needs a file argument")
    return 2
  }
  let bounds = if argv.length() > 2 {
    parse_bounds(argv[2])
  } else {
    [100, 120, 140, 160]
  }
  let window = if argv.length() > 3 { to_int_def(argv[3], 5) } else { 5 }
  let data = @fs.read_file_to_bytes(argv[1]) catch {
    @fs.IOError(_) => {
      eprintln("moonfit: cannot read \{argv[1]}")
      return 2
    }
  }
  let act = @model.from_fit(@fit.parse_messages(data)) catch {
    _ => {
      eprintln("moonfit: cannot decode \{argv[1]}")
      return 2
    }
  }
  println(@metrics.to_json(@metrics.compute(act, bounds, window)))
  0
}

///|
fn opt_i32_json(v : Int32?) -> String {
  match v {
    Some(x) => x.to_string()
    None => "null"
  }
}

///|
fn run_tcx(argv : Array[String]) -> Int32 {
  if argv.length() < 2 {
    eprintln("moonfit: tcx needs a file argument")
    return 2
  }
  let data = @fs.read_file_to_bytes(argv[1]) catch {
    @fs.IOError(_) => {
      eprintln("moonfit: cannot read \{argv[1]}")
      return 2
    }
  }
  let t = @tcx.parse(data) catch {
    @tcx.Malformed(msg) => {
      eprintln("moonfit: malformed TCX: \{msg}")
      return 2
    }
  }
  let a = t.activity
  let first = if a.points.length() > 0 { a.points[0].timestamp } else { 0L }
  let last = if a.points.length() > 0 {
    a.points[a.points.length() - 1].timestamp
  } else {
    0L
  }
  let avghr = opt_i32_json(a.avg_hr)
  let maxhr = opt_i32_json(a.max_hr)
  println(
    "{\"sport\":\"" +
    a.sport +
    "\",\"sport_raw\":\"" +
    t.sport_raw +
    "\",\"sport_nonstandard\":" +
    (if t.sport_nonstandard { "true" } else { "false" }) +
    ",\"n_points\":" +
    a.points.length().to_string() +
    ",\"n_laps\":" +
    a.laps.length().to_string() +
    ",\"device_distance_m\":" +
    a.device_distance_m.to_string() +
    ",\"timer_s\":" +
    a.timer_s.to_string() +
    ",\"avg_hr\":" +
    avghr +
    ",\"max_hr\":" +
    maxhr +
    ",\"first_ts\":" +
    first.to_string() +
    ",\"last_ts\":" +
    last.to_string() +
    "}",
  )
  0
}

///|
fn run_diff(argv : Array[String]) -> Int32 {
  if argv.length() < 3 {
    eprintln("moonfit: diff needs <fit> <tcx>")
    return 2
  }
  let fdata = @fs.read_file_to_bytes(argv[1]) catch {
    @fs.IOError(_) => {
      eprintln("moonfit: cannot read \{argv[1]}")
      return 2
    }
  }
  let tdata = @fs.read_file_to_bytes(argv[2]) catch {
    @fs.IOError(_) => {
      eprintln("moonfit: cannot read \{argv[2]}")
      return 2
    }
  }
  let fit = @model.from_fit(@fit.parse_messages(fdata)) catch {
    _ => {
      eprintln("moonfit: cannot decode FIT \{argv[1]}")
      return 2
    }
  }
  let tcx = @tcx.parse(tdata) catch {
    @tcx.Malformed(msg) => {
      eprintln("moonfit: malformed TCX: \{msg}")
      return 2
    }
  }
  println(
    @diff.to_json(@diff.compare(fit, tcx.activity, tcx.sport_nonstandard)),
  )
  0
}

///|
fn run_redact(argv : Array[String]) -> Int32 {
  if argv.length() < 3 {
    eprintln("moonfit: redact needs <in.fit> <out.fit> [trim] [dlat] [dlon]")
    return 2
  }
  let trim = if argv.length() > 3 { to_int_def(argv[3], 0) } else { 0 }
  let dlat = if argv.length() > 4 {
    to_int_def(argv[4], 600000).to_int64()
  } else {
    600000L
  }
  let dlon = if argv.length() > 5 {
    to_int_def(argv[5], -800000).to_int64()
  } else {
    -800000L
  }
  let data = @fs.read_file_to_bytes(argv[1]) catch {
    @fs.IOError(_) => {
      eprintln("moonfit: cannot read \{argv[1]}")
      return 2
    }
  }
  let out = @redact.redact(data, trim, dlat, dlon) catch {
    _ => {
      eprintln("moonfit: cannot redact \{argv[1]}")
      return 2
    }
  }
  @fs.write_bytes_to_file(argv[2], out) catch {
    @fs.IOError(_) => {
      eprintln("moonfit: cannot write \{argv[2]}")
      return 2
    }
  }
  0
}

///|
fn run_verify(argv : Array[String]) -> Int32 {
  if argv.length() < 2 {
    eprintln("moonfit: verify needs a file argument")
    return 2
  }
  let data = @fs.read_file_to_bytes(argv[1]) catch {
    @fs.IOError(_) => {
      eprintln("moonfit: cannot read \{argv[1]}")
      return 2
    }
  }
  if @fit.verify(data) {
    println("ok")
    0
  } else {
    eprintln("moonfit: invalid FIT \{argv[1]}")
    1
  }
}

///|
fn run_info(argv : Array[String]) -> Int32 {
  if argv.length() < 2 {
    eprintln("moonfit: info needs a file argument")
    return 2
  }
  let data = @fs.read_file_to_bytes(argv[1]) catch {
    @fs.IOError(_) => {
      eprintln("moonfit: cannot read \{argv[1]}")
      return 2
    }
  }
  let h = @fit.parse_header(data) catch {
    _ => {
      eprintln("moonfit: bad header \{argv[1]}")
      return 2
    }
  }
  let msgs = @fit.parse_messages(data) catch {
    _ => {
      eprintln("moonfit: bad record stream \{argv[1]}")
      return 2
    }
  }
  let data_n = @fit.data_messages(msgs).length()
  println(
    "{\"header_size\":" +
    h.header_size.to_string() +
    ",\"protocol\":\"" +
    @fit.protocol_major(h).to_string() +
    "." +
    @fit.protocol_minor(h).to_string() +
    "\",\"profile\":" +
    h.profile.to_string() +
    ",\"data_size\":" +
    h.data_size.to_string() +
    ",\"has_header_crc\":" +
    (if h.has_header_crc { "true" } else { "false" }) +
    ",\"file_crc_ok\":" +
    (if @fit.file_crc_ok(data) { "true" } else { "false" }) +
    ",\"data_messages\":" +
    data_n.to_string() +
    ",\"records\":" +
    @fit.count_global(msgs, 20).to_string() +
    "}",
  )
  0
}
