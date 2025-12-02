# Prepare market segment counts

Converts raw market segment counts into PBWG segment groupings and
ensures required columns exist.

## Usage

``` r
pbwg_prepare_segments(market)
```

## Arguments

- market:

  Tibble with `ENTRY_DATE`, `MARKET_SEGMENT_DESCR`, and `FLIGHT`.

## Value

Tibble with columns:

- `ENTRY_DATE`Date of operation.

- `SCHED`Scheduled flights (mainline + low-cost + regional aircraft).

- `CHARTER`Charter flights.

- `CARGO`All-cargo flights.

- `OTHER`Business aviation, military, and other types.
