///|
let tcx_rich : String = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<TrainingCenterDatabase xmlns=\"http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2\">\n<Activities><Activity Sport=\"Biking\"><Id>2026-08-03T10:40:06Z</Id>\n<Lap StartTime=\"2026-08-03T10:40:06Z\"><TotalTimeSeconds>199.0</TotalTimeSeconds><DistanceMeters>817.03</DistanceMeters><AverageHeartRateBpm><Value>120</Value></AverageHeartRateBpm><MaximumHeartRateBpm><Value>150</Value></MaximumHeartRateBpm>\n<Track><Trackpoint><Time>2026-08-03T10:40:06Z</Time><Position><LatitudeDegrees>22.37</LatitudeDegrees><LongitudeDegrees>112.70</LongitudeDegrees></Position><AltitudeMeters>-8.4</AltitudeMeters><DistanceMeters>0.0</DistanceMeters><HeartRateBpm><Value>110</Value></HeartRateBpm><Extensions><TPX><Speed>3.9</Speed></TPX></Extensions></Trackpoint>\n<Trackpoint><Time>2026-08-03T10:40:16Z</Time><Position><LatitudeDegrees>22.371</LatitudeDegrees><LongitudeDegrees>112.701</LongitudeDegrees></Position><DistanceMeters>100.0</DistanceMeters></Trackpoint></Track>\n</Lap></Activity></Activities></TrainingCenterDatabase>"

///|
let tcx_huawei : String = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<TrainingCenterDatabase creator=\"Health\" xmlns=\"http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2\">\n<Activities><Activity Sport=\"\u6237\u5916\u8dd1\u6b65\"><Id>2026-08-15T04:14:16.601Z</Id>\n<Lap StartTime=\"2026-08-15T04:14:16.601Z\"><TotalTimeSeconds>293.0</TotalTimeSeconds><DistanceMeters>1231.0</DistanceMeters>\n<Track><Trackpoint><Time>2026-08-15T04:14:16.601Z</Time><Position><LatitudeDegrees>22.373491</LatitudeDegrees><LongitudeDegrees>112.672297</LongitudeDegrees></Position></Trackpoint></Track>\n</Lap></Activity></Activities></TrainingCenterDatabase>"

///|
test "tcx: rich variant extracts fields and matches FIT epoch" {
  let t = @tcx.parse(@utf8.encode(tcx_rich))
  assert_eq(t.sport_raw, "Biking")
  assert_true(!t.sport_nonstandard)
  assert_eq(t.activity.sport, "cycling")
  assert_eq(t.activity.points.length(), 2)
  assert_eq(t.activity.points[0].timestamp, 1154688006L)
  assert_eq(t.activity.points[0].altitude_m, Some(-8.4))
  assert_eq(t.activity.points[0].speed_mps, Some(3.9))
  assert_eq(t.activity.points[0].heart_rate, Some(110))
  assert_eq(t.activity.device_distance_m, 817.03)
  assert_eq(t.activity.timer_s, 199.0)
  assert_eq(t.activity.avg_hr, Some(120))
}

///|
test "tcx: huawei variant normalises non-standard sport and tolerates fraction" {
  let t = @tcx.parse(@utf8.encode(tcx_huawei))
  assert_eq(t.sport_raw, "户外跑步")
  assert_true(t.sport_nonstandard)
  assert_eq(t.activity.sport, "running")
  assert_eq(t.activity.points.length(), 1)
  assert_eq(t.activity.points[0].heart_rate, None)
  assert_eq(t.activity.points[0].altitude_m, None)
  assert_eq(t.activity.device_distance_m, 1231.0)
}

///|
test "tcx: UTF-8 BOM is tolerated" {
  let bom = Bytes::add(
    Bytes::from_array([b'\xef', b'\xbb', b'\xbf']),
    @utf8.encode(tcx_huawei),
  )
  let t = @tcx.parse(bom)
  assert_eq(t.activity.sport, "running")
  assert_eq(t.activity.points.length(), 1)
}

///|
fn tcx_tp_field(inner : String) -> Bytes {
  @utf8.encode(
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<TrainingCenterDatabase xmlns=\"http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2\">\n<Activities><Activity Sport=\"Biking\"><Id>2026-08-03T10:40:06Z</Id>\n<Lap StartTime=\"2026-08-03T10:40:06Z\"><TotalTimeSeconds>199.0</TotalTimeSeconds><DistanceMeters>817.03</DistanceMeters>\n<Track><Trackpoint><Time>2026-08-03T10:40:06Z</Time>" +
    inner +
    "</Trackpoint></Track>\n</Lap></Activity></Activities></TrainingCenterDatabase>",
  )
}

///|
fn raises_malformed(data : Bytes) -> Bool {
  let _ = @tcx.parse(data) catch { @tcx.Malformed(_) => return true }
  false
}

///|
test "P1-2: malformed heart-rate value raises Malformed, not Some(0)" {
  assert_true(
    raises_malformed(
      tcx_tp_field("<HeartRateBpm><Value>abc</Value></HeartRateBpm>"),
    ),
  )
  assert_true(
    raises_malformed(
      tcx_tp_field("<HeartRateBpm><Value>N/A</Value></HeartRateBpm>"),
    ),
  )
  assert_true(
    raises_malformed(
      tcx_tp_field("<HeartRateBpm><Value>NaN</Value></HeartRateBpm>"),
    ),
  )
  assert_true(
    raises_malformed(
      tcx_tp_field("<HeartRateBpm><Value>Infinity</Value></HeartRateBpm>"),
    ),
  )
  assert_true(
    raises_malformed(
      tcx_tp_field("<HeartRateBpm><Value>3000000000</Value></HeartRateBpm>"),
    ),
  )
}

///|
test "P1-2: malformed distance value raises Malformed, not 0" {
  assert_true(
    raises_malformed(tcx_tp_field("<DistanceMeters>NaN</DistanceMeters>")),
  )
  assert_true(
    raises_malformed(tcx_tp_field("<DistanceMeters>Infinity</DistanceMeters>")),
  )
  assert_true(
    raises_malformed(tcx_tp_field("<DistanceMeters>-5</DistanceMeters>")),
  )
  assert_true(
    raises_malformed(tcx_tp_field("<DistanceMeters>abc</DistanceMeters>")),
  )
}

///|
fn tcx_two_activities() -> Bytes {
  @utf8.encode(
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<TrainingCenterDatabase xmlns=\"http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2\">\n<Activities><Activity Sport=\"Biking\"><Id>2026-08-03T10:40:06Z</Id><Lap StartTime=\"2026-08-03T10:40:06Z\"><TotalTimeSeconds>199.0</TotalTimeSeconds><DistanceMeters>817.03</DistanceMeters><Track><Trackpoint><Time>2026-08-03T10:40:06Z</Time></Trackpoint></Track></Lap></Activity><Activity Sport=\"Running\"><Id>2026-08-03T11:40:06Z</Id><Lap StartTime=\"2026-08-03T11:40:06Z\"><TotalTimeSeconds>100.0</TotalTimeSeconds><DistanceMeters>500.0</DistanceMeters><Track><Trackpoint><Time>2026-08-03T11:40:06Z</Time></Trackpoint></Track></Lap></Activity></Activities></TrainingCenterDatabase>",
  )
}

///|
test "P1-5: multiple TCX Activity elements raise Malformed, not silent merge" {
  assert_true(raises_malformed(tcx_two_activities()))
}
