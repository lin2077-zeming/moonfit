///|
pub let moonfit_version : String = "0.2.0"

///|
fn build_command() -> @argparse.Command {
  @argparse.Command(
    "moonfit",
    about="Garmin FIT activity codec with byte-exact round-trip, TCX decoding, and measured cross-format divergence reports.",
    version=moonfit_version,
    subcommands=[
      @argparse.Command("version", about="Print the module version"),
      @argparse.Command(
        "units",
        about="Print the FIT wire-unit table and the independent source of each G7 constant",
      ),
    ],
  )
}

///|
// @env.args() includes the program invocation, but its shape differs per
// backend: native yields [exePath, ...], while js yields process.argv
// unchanged, i.e. [nodePath, scriptPath, ...]. argparse wants neither.
//
// Rather than branch on the backend, drop leading tokens that can only be a
// program invocation. The loop stops at the first token that is not one, so a
// path argument appearing after a subcommand name is never touched.
fn is_program_token(token : String) -> Bool {
  token == "moonfit" ||
  token == "node" ||
  token.has_suffix(".exe") ||
  token.has_suffix(".js") ||
  token.has_suffix(".wasm") ||
  token.contains("/") ||
  token.contains("\\")
}

///|
fn user_args(args : Array[String]) -> Array[String] {
  let mut start = 0
  while start < args.length() && is_program_token(args[start]) {
    start = start + 1
  }
  let out : Array[String] = []
  let mut index = start
  while index < args.length() {
    out.push(args[index])
    index = index + 1
  }
  out
}

///|
fn main {
  let command = build_command()
  let argv = user_args(@env.args())
  // An explicit --help exits 0, but being invoked with no command at all is a
  // usage error and exits 2. argparse folds both into one Help outcome when
  // arg_required_else_help is set, so the empty case is decided here instead.
  if argv.length() > 0 && argv[0] == "dump" {
    @env.exit(run_dump(argv))
  }
  if argv.length() > 0 && argv[0] == "roundtrip" {
    @env.exit(run_roundtrip(argv))
  }
  if argv.length() > 0 && argv[0] == "metrics" {
    @env.exit(run_metrics(argv))
  }
  if argv.length() > 0 && argv[0] == "tcx" {
    @env.exit(run_tcx(argv))
  }
  if argv.length() > 0 && argv[0] == "diff" {
    @env.exit(run_diff(argv))
  }
  if argv.length() > 0 && argv[0] == "redact" {
    @env.exit(run_redact(argv))
  }
  if argv.length() > 0 && argv[0] == "verify" {
    @env.exit(run_verify(argv))
  }
  if argv.length() > 0 && argv[0] == "info" {
    @env.exit(run_info(argv))
  }
  if argv.length() == 0 {
    eprintln("moonfit: no command given")
    eprintln("")
    eprintln(command.render_help())
    @env.exit(2)
  }
  let outcome = command.parse_outcome(argv~)
  let code : Int32 = match outcome {
    @argparse.Parsed(matches) => dispatch(matches)
    @argparse.Help(text) => {
      println(text)
      0
    }
    @argparse.Version(text) => {
      println(text)
      0
    }
    @argparse.Failed(err) => {
      eprintln(err)
      2
    }
  }
  @env.exit(code)
}
