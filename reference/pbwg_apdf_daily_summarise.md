# Summarise APDF movements for one airport/day

Internal helper that normalises column names and wake-turbulence
classes, flags domestic traffic, drops helicopters, and aggregates
arrivals/departures plus H/M/L totals.

## Usage

``` r
pbwg_apdf_daily_summarise(raw_tbl, airport, domestic_prefixes)
```

## Arguments

- raw_tbl:

  Output of
  [`pbwg_apdf_fetch_airport_raw()`](https://eurocontrol.github.io/pbwg-eurocontrol/reference/pbwg_apdf_fetch_airport_raw.md)
  or equivalent APDF data frame.

- airport:

  ICAO airport code used to flag arrivals vs departures.

- domestic_prefixes:

  Prefixes passed to
  [`pbwg_apdf_is_domestic()`](https://eurocontrol.github.io/pbwg-eurocontrol/reference/pbwg_apdf_is_domestic.md).

## Value

Tibble with one row per day for the provided airport, containing:

- `ICAO`: airport code.

- `DATE`: movement date (UTC).

- `ARRS` / `DEPS`: arrival and departure counts.

- `HEAVY` / `MED` / `LIGHT`: counts by wake turbulence class.

- `ARRS_DOM` / `DEPS_DOM`: domestic arrivals/departures based on
  prefixes.
