# CHN-EUR collaboration traffic summary

Thin wrapper around
[`pbwg_traffic_summary()`](https://eurocontrol.github.io/pbwg-eurocontrol/reference/pbwg_traffic_summary.md)
returning the CHN-EUR schema (`schema = "chn"`).

## Usage

``` r
pbwg_chn_summary(wef, til, region = "ECAC", conn = NULL)
```

## Arguments

- wef:

  Start date (inclusive). Can be anything that
  [`lubridate::as_date()`](https://lubridate.tidyverse.org/reference/as_date.html)
  understands.

- til:

  End date (inclusive). Can be anything that
  [`lubridate::as_date()`](https://lubridate.tidyverse.org/reference/as_date.html)
  understands.

- region:

  DAIO region code. Defaults to `"ECAC"`.

- conn:

  Optional Oracle
  [DBI::DBIConnection](https://dbi.r-dbi.org/reference/DBIConnection-class.html).
  When omitted a fresh connection to `PRUDEV` is created via
  [`eurocontrol::db_connection()`](https://eurocontrol.github.io/eurocontrol/reference/db_connection.html),
  with access to `SWH_FCT.V_FAC_FLIGHT_MS` and
  `PRUDEV.V_PRU_AIRCRAFT_CATEGORY`.
