# Specification notes and measured corpus profile

Everything in this file was measured from the files under `corpus/redacted/`
using two independent implementations that agree: a byte-level walker written
for this project, and `fitparse` 1.2.0. Where the two disagree, the byte-level
walker is authoritative, because `fitparse` synthesises fields that are not
present in the file.

## Corpus

Six outdoor rides recorded by an iGPSPORT cycle computer, exported as FIT, TCX
and GPX. Eight outdoor runs recorded by a Huawei band, exported as TCX, GPX and
KML. All files were recorded by the project author and redacted before being
committed; see `corpus/README.md`.

The FIT files share one profile: protocol version 1.0, profile version 20.74,
a 14-byte header carrying its own checksum, little-endian throughout, and a
valid trailing CRC-16. In every file `header_size + data_size + 2` equals the
file size, and the byte-level walker consumes the data section exactly, with
zero bytes left over.

## Messages and fields present

| Message | Global number | Fields | Bytes | Instances per file |
|---|---|---|---|---|
| `file_id` | 0 | 5 | 41 | 1 |
| `file_creator` | 49 | 2 | 3 | 1 |
| `device_info` | 23 | 8 | 45 | 2 |
| `event` | 21 | 4 | 10 | 9 to 49 |
| `record` | 20 | 10 | 25 | 45 to 841 |
| `lap` | 19 | 48 | 100 | 1 |
| `session` | 18 | 56 | 187 | 1 |
| `activity` | 34 | 7 | 17 | 1 |

3120 `record` messages in total. Base types exercised: `enum`, `sint8`,
`uint8`, `sint16`, `uint16`, `sint32`, `uint32`, `uint32z`. The remaining
eight base types in the specification are covered by generated fixtures.

Absent from the corpus entirely: compressed-timestamp record headers,
developer fields, big-endian definitions, unknown messages, and the `length`,
`hrv`, `course*`, `workout*` and `segments` messages.

Local message type 1 is defined twice in every file, with an identical field
layout both times. A decoder that assumes one definition per local id will
mis-track the stream.

## Wire scalings

| Field | Encoding | Native unit type |
|---|---|---|
| `position_lat`, `position_long` | sint32 semicircles, `degrees = semis * 180 / 2^31` | `Semicircle` |
| `timestamp`, `start_time`, `local_timestamp` | uint32 seconds since 1989-12-31T00:00:00Z, unix offset 631065600 | `FitTimestamp` |
| `distance`, `total_distance` | uint32 centimetres | `Centimetre` |
| `altitude`, `enhanced_altitude` | `(metres + 500) * 5` | `AltitudeRaw` to `Decimetre` |
| `speed`, `enhanced_speed`, `avg_speed`, `max_speed` | millimetres per second | `MillimetrePerSecond` |
| `total_elapsed_time`, `total_timer_time`, `total_moving_time` | uint32 milliseconds | `Millisecond` |
| `avg_grade`, `max_pos_grade`, `max_neg_grade` | sint16 hundredths of a percent | `CentiPercent` |

One semicircle is `8.381903171539307e-8` degrees, about 9.3 mm on the equator.

Altitude goes through decimetres rather than the obvious float expression. For
raw 2458 the naive `2458 / 5.0 - 500.0` produces `-8.399999999999977`, while
the exact integer path `2458 * 2 - 5000` produces `-84` decimetres, which is
exactly `-8.4` metres. The two Doubles are not equal, and only the integer one
can be asserted against a constant.

## Invalid values

FIT marks a field absent by filling it with all-ones in its base type. The
corpus exercises this heavily:

| Field | Invalid occurrences |
|---|---|
| `record.cadence` | 3120 of 3120 |
| `record.power` | 3120 of 3120 |
| `device_info.device_index` | 12 of 12 |
| `record.altitude` | 117 of 3120 |
| `record.heart_rate` | 45 of 3120 |
| `session.avg_power`, `max_power`, `normalized_power`, `training_stress_score`, `intensity_factor`, `left_right_balance`, `avg_cadence`, `max_cadence` | 6 of 6 |

A field that is present in the definition message but invalid in every instance
must be reported as absent, not as zero. Treating `record.power` as 0 W would
invent a measurement the device never made.

`session.time_in_hr_zone`, `time_in_cadence_zone` and `time_in_power_zone` are
array fields of 5, 6 and 7 uint32 elements respectively, all zero here.

## Structural laws measured across formats

Each law held for every file it was checked against, which is what makes it
usable as a regression gate rather than an observation.

| Law | Statement | Files |
|---|---|---|
| L1 | TCX trackpoint count equals the FIT `record` count | 6 of 6 |
| L2 | GPX `trkpt` count equals `ceil(record count / 2)` | 6 of 6 |
| L3 | GPX is the even-indexed subsample of FIT. As committed the coordinates agree to within 2.8e-11 degrees, about 3 nm; in the unredacted exports they were bit-identical | 6 of 6 |
| L4 | TCX coordinates are the FIT coordinates rounded to 7 decimal places. As committed the agreement is within 7.6e-8 degrees, about 8.4 mm; in the unredacted exports it was 4.4e-8 | 6 of 6 |
| L5 | KML placemark count equals the TCX trackpoint count plus two, the extra pair being the Start and End markers | 8 of 8 |
| L6 | TCX `Lap/TotalTimeSeconds` equals FIT `session.total_timer_time`, not `total_elapsed_time` | 6 of 6 |

L6 is the one that costs data. In the 2026-09-25 ride, `total_elapsed_time` is
6268 s and `total_timer_time` is 5355 s. The 913 s difference is auto-pause
time, recorded in FIT as 24 pairs of `timer start` and `timer stop` events.
TCX, GPX and KML all carry the 5355 s figure and none of them carries anything
that indicates the other 913 s existed.

## Device defects found in the corpus

These are properties of the files, not of this decoder. Each one is asserted by
a gate so that a change in behaviour is noticed.

| Id | Observation | Files |
|---|---|---|
| B1 | `session.swc_lat` and `session.swc_long` are 0 while `nec_lat` and `nec_long` hold real values, so a bounding box built from them spans from the Gulf of Guinea | 6 of 6 |
| B2 | The iGPSPORT GPX export writes `<ele>0</ele>` where altitude is unavailable, while the TCX export of the same activity omits `AltitudeMeters`. Zero and absent are conflated in one format and distinguished in the other | observed |
| B3 | `session.first_lap_index` is 0 while `lap.message_index` is 1 | 6 of 6 |
| B4 | `activity.num_sessions` is 0 where the specification implies 1 | 6 of 6 |
| B5 | The Huawei TCX export writes `Sport="户外跑步"`. The TCX schema defines `Sport` as an enumeration of `Running`, `Biking` and `Other`, so a schema-validating reader rejects the file | 8 of 8 |
| B6 | The iGPSPORT GPX export writes a bare `schemaLocation` attribute without the `xsi:` prefix | 6 of 6 |
| B7 | The iGPSPORT GPX export begins with a UTF-8 byte order mark; the Huawei exports do not | 6 of 6 |
| B8 | The Huawei KML declares `version="1.0"` while its namespace is KML 2.1 | 8 of 8 |
| B9 | The Huawei GPX export is GPX 1.0 and the iGPSPORT export is GPX 1.1 | 8 and 6 |
| B10 | The Huawei TCX, GPX and KML exports carry no heart rate and no altitude, although the band records heart rate and the FIT-equivalent data would hold it | 8 of 8 |
| B11 | The Huawei KML export writes `<Data name="cumulativeClimb"/>` with no value child, while the GPX export of the same activity writes `0.0` for the same quantity | 8 of 8 |

## Sampling

Record intervals in the corpus range from 1 s to 73 s within a single file. The
devices use smart recording, not a fixed 1 Hz clock. Any metric that assumes
uniform sampling will be wrong on this data, so derived quantities are computed
from the timestamps and the cumulative distance field rather than from a
 presumed sample rate.

## Auto-pause

`event` messages carry `timer` events with `start`, `stop` and `stop_all`
types, plus one `session` event with `stop_disable_all`. The corpus holds
between 4 and 24 start/stop pairs per ride. `timer_trigger` is invalid in every
instance, so the reason for each pause is not recoverable from these files.

## Coordinate agreement after redaction

The committed files have been shifted by a constant offset, so the coordinate
laws were re-measured on them rather than carried over from the raw exports:

| Comparison | Maximum deviation | In metres |
|---|---|---|
| GPX `trkpt` against the even-indexed FIT `record` | 2.768e-11 degrees | 3.1e-6 |
| TCX `Trackpoint` against the matching FIT `record` | 7.536e-08 degrees | 8.4e-3 |

The shift is an exact integer number of semicircles in FIT, and the equivalent
number of degrees in the XML exports, re-rounded to each file's own decimal
precision. That re-rounding is the whole of the deviation above.

## Privacy

`file_id.serial_number` and `device_info.serial_number` hold the device serial
as a `uint32z` array of 8 elements, and every GPS trace begins and ends at a
place the author visits regularly. `corpus/README.md` records exactly what was
changed before the files were committed.
