///|
fn dispatch(matches : @argparse.Matches) -> Int32 {
  match matches.subcommand {
    Some((name, _)) =>
      match name {
        "version" => {
          println(moonfit_version)
          0
        }
        "units" => {
          print_unit_table()
          0
        }
        _ => {
          eprintln("moonfit: unknown command '\{name}'")
          2
        }
      }
    None => {
      eprintln("moonfit: no command given")
      2
    }
  }
}
