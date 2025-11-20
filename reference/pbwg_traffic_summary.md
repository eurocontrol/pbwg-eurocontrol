# PBWG regional traffic summary (EUR view)

Recreates the composite PBWG workflow that merges DAIO, H/M/L, and
market segment statistics into a single daily table.

## Usage

``` r
pbwg_traffic_summary(wef, til, region = "ECAC", conn = NULL)
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

## Value

A list with the processed `data`, an optional `plot` (if `plotly` is
installed), diagnostic `details`, and the `raw` component tables.
