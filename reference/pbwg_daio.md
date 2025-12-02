# Daily DAIO traffic counts

Runs the DAIO aggregation used by PBWG, grouping the FIR-time entries by
DAIO flag and region. Optional inclusion of `SK_SOURCE_ID` reproduces
the CHN-specific variant of the legacy Python query.

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
with `"sql"` attribute and columns:

- `YEAR`Numeric year derived from `ENTRY_TIME`.

- `MONTH`Numeric month derived from `ENTRY_TIME`.

- `ENTRY_DATE`Date (UTC) of the FIR entry.

- `TZ_NAME`Region name from `DIMCL_TZ`.

- `DAIO`DAIO flag (`D`, `A`, `I`, `O`).

- `SK_SOURCE_ID`Optional source ID when `include_source_id = TRUE`.

- `FLIGHT`Total flights for the grouping.
