# Metrics

All metrics are computed from the canonical activity model (`src/model`), which
extracts FIT fields into native units with invalid-as-None.

## Distance
- `device_distance_m`: session `total_distance` (cm -> m). Authoritative.
- `gps_distance_m`: sum of spherical haversine over consecutive points with valid
  lat/lon. Cross-check only; compared against Karney geodesics in Gate G4 with a
  documented sphere-vs-ellipsoid tolerance.

## Speed / pace
- `avg_speed_mps` = `device_distance_m / timer_s` (device basis, works without GPS).
- `gps_avg_speed_mps` = `gps_distance_m / timer_s` (GPS cross-check).
- `avg_pace_min_per_km` = `1000 / avg_speed_mps / 60`.

## Time
- `elapsed_s`, `timer_s`, `moving_s` from session fields 7/8/59 (ms -> s).
- `timer_s` excludes auto-pause; `elapsed_s` includes it.

## Splits (`splits`, `split_basis`)
- Per-kilometre splits of the **device** cumulative distance, with linear
  interpolation of the boundary timestamp between adjacent valid points.
- Generation starts at `floor(first_valid_distance/1000)+1`, so a trimmed track
  does not backfill leading kilometres.
- Each split's `time_s` is the delta from the previous *boundary* time.
- **`split_basis` is `"elapsed"`**: split times are wall-clock and therefore
  **include auto-pause**. `sum(splits.time_s)` approximates elapsed time up to the
  last full kilometre, NOT `timer_s`. This is a deliberate, documented choice
  (audit P0-3 scheme B); pause-subtracted splits are a possible future extension.

## Ascent
- `device_ascent_m` / `device_descent_m`: session totals.
- `computed_ascent_m`: sum of positive deltas of a trailing moving average of the
  altitude series; window = `ascent_window` parameter (default 5, min 1).

## Heart-rate zones (`hr_zones`)
- Boundaries supplied by the caller (`bounds`); no built-in recommendation.
- `seconds` accumulated from consecutive timestamp deltas where the current HR is
  valid; zone index = number of boundaries <= HR. Uses elapsed deltas (includes
  pause), consistent with `split_basis`.
