# Daily DAIO traffic counts

Executes the DAIO query that powers the PBWG tool. When
`include_source_id` is `TRUE` the output matches the `query_daio_CHN()`
variant from the Python implementation.

## Usage

``` r
pbwg_daio(wef, til, region, include_source_id = FALSE, conn = NULL)
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

  One or more TZ codes (e.g. `"ECAC"`). Values are embedded into the SQL
  `IN (...)` clause verbatim.

- include_source_id:

  Should `SK_SOURCE_ID` be returned? Defaults to `FALSE`, mirroring the
  classic DAIO table.

- conn:

  Optional Oracle
  [DBI::DBIConnection](https://dbi.r-dbi.org/reference/DBIConnection-class.html).
  When omitted a fresh connection to `PRUDEV` is created via
  [`eurocontrol::db_connection()`](https://eurocontrol.github.io/eurocontrol/reference/db_connection.html),
  with access to `SWH_FCT.V_FAC_FLIGHT_MS` and
  `PRUDEV.V_PRU_AIRCRAFT_CATEGORY`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with `"sql"` attribute.
