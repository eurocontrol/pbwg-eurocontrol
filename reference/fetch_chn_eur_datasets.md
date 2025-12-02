# Fetch CHN-EUR datasets to Parquet

Downloads NM area traffic counts (weight and market segments), regional
roll-ups, APDF airport traffic counts, and OTP punctuality buckets for a
date window, writing each dataset to Parquet files for downstream
CHN-EUR reporting.

## Usage

``` r
fetch_chn_eur_datasets(
  wef = as.Date("2019-01-01"),
  til = as.Date("2025-06-30"),
  airports = c("EDDF", "EDDM", "EGKK", "EGLL", "EHAM", "LEBL", "LEMD", "LFPG", "LGAV",
    "LIRF", "LSZH", "LTFM"),
  years = NULL,
  include_weight = TRUE,
  include_market = TRUE,
  include_regional = TRUE,
  include_airport = TRUE,
  include_raw_apdf = TRUE,
  include_otp = TRUE,
  out_dir = "data/eur"
)
```

## Arguments

- wef:

  Date; start of the interval (inclusive).

- til:

  Date; end of the interval (inclusive).

- airports:

  Character vector of ICAO airport codes to include for APDF and OTP
  datasets.

- years:

  Optional integer vector of years for OTP. Defaults to all years
  overlapping `[wef, til]`.

- include_weight:

  Logical; fetch NM area weight segment counts.

- include_market:

  Logical; fetch NM area market segment counts.

- include_regional:

  Logical; fetch regional roll-up (PBWG schema).

- include_airport:

  Logical; fetch APDF airport traffic counts.

- include_raw_apdf:

  Logical; also export raw APDF rows when available.

- include_otp:

  Logical; fetch OTP punctuality buckets.

- out_dir:

  Output directory; created if missing.

## Value

Invisibly returns `TRUE` after writing requested datasets.
