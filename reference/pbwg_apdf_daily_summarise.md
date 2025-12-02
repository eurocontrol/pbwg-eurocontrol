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

- `ICAO`Airport code.

- `DATE`Movement date (UTC).

- `ARRS`Arrival count.

- `DEPS`Departure count.

- `HEAVY`Heavy wake turbulence movements.

- `MED`Medium wake turbulence movements.

- `LIGHT`Light wake turbulence movements.

- `ARRS_DOM`Domestic arrivals based on prefixes.

- `DEPS_DOM`Domestic departures based on prefixes.
