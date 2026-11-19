///|
// Civil-time rendering of a Unix second as an ISO-8601 UTC timestamp.
//
// FIT stores `timestamp` as uint32 seconds since 1989-12-31T00:00:00Z, so the
// reachable Unix range is 631065600 .. 4926032895, i.e. years 1989 .. 2126.
// The implementation still covers the general proleptic Gregorian calendar so
// the defensive branches are exercised by tests instead of being dead code.

///|
fn floor_div(x : Int64, divisor : Int64) -> Int64 {
  if x >= 0L {
    x / divisor
  } else {
    (x - divisor + 1L) / divisor
  }
}

///|
// Howard Hinnant's civil_from_days. The era adjustment keeps every subsequent
// dividend non-negative, so MoonBit's truncating integer division agrees with
// the mathematical floor division the algorithm assumes.
fn civil_from_days(days_from_epoch : Int64) -> (Int64, Int64, Int64) {
  let shifted = days_from_epoch + 719468L
  let era = floor_div(shifted, 146097L)
  let day_of_era = shifted - era * 146097L
  let year_of_era =
    (day_of_era - day_of_era / 1460L + day_of_era / 36524L - day_of_era / 146096L) /
    365L
  let year = year_of_era + era * 400L
  let day_of_year =
    day_of_era - (365L * year_of_era + year_of_era / 4L - year_of_era / 100L)
  let shifted_month = (5L * day_of_year + 2L) / 153L
  let day = day_of_year - (153L * shifted_month + 2L) / 5L + 1L
  let month =
    if shifted_month < 10L { shifted_month + 3L } else { shifted_month - 9L }
  (if month <= 2L { year + 1L } else { year }, month, day)
}

///|
fn pad2(value : Int64) -> String {
  if value < 10L { "0\{value}" } else { "\{value}" }
}

///|
fn pad4(value : Int64) -> String {
  if value < 10L {
    "000\{value}"
  } else if value < 100L {
    "00\{value}"
  } else if value < 1000L {
    "0\{value}"
  } else {
    "\{value}"
  }
}

///|
// Renders as `YYYY-MM-DDThh:mm:ssZ`. Returns None when the year falls outside
// 0 .. 9999, which the fixed-width format cannot represent. Total function:
// no raise, so every branch is testable.
pub fn iso8601_of_unix_second(x : UnixSecond) -> Option[String] {
  let unix = x.value
  let days = floor_div(unix, 86400L)
  let seconds_of_day = unix - days * 86400L
  let (year, month, day) = civil_from_days(days)
  if year < 0L || year > 9999L {
    return None
  }
  let hour = seconds_of_day / 3600L
  let minute = (seconds_of_day % 3600L) / 60L
  let second = seconds_of_day % 60L
  Some(
    "\{pad4(year)}-\{pad2(month)}-\{pad2(day)}T\{pad2(hour)}:\{pad2(minute)}:\{pad2(second)}Z",
  )
}

///|
pub fn iso8601_of_fit_timestamp(x : FitTimestamp) -> Option[String] {
  iso8601_of_unix_second(unix_of_fit_timestamp(x))
}
