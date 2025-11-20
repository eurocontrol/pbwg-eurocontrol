# NM area traffic by market segment

Runs the PBWG "Traffic NM Area per Market Segment" query for data for
PBWG reports. Gets data from the PRISME flights fact
(`SWH_FCT.V_FAC_FLIGHT_MS`), using
[`eurocontrol::flights_tbl()`](https://eurocontrol.github.io/eurocontrol/reference/flights_tbl.html)
as the base joined on ' `DIM_FLIGHT_TYPE_RULE`. Market segment data are
only available from 2004.

## Usage

``` r
pbwg_nm_area_market_segment(wef, til, conn = NULL)
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
with one row per day/market segment and an attached `"sql"` attribute.
Columns:

- `YEAR`: numeric year extracted from `ENTRY_DATE`.

- `MONTH`: numeric month extracted from `ENTRY_DATE`.

- `ENTRY_DATE`: truncated IFPZ entry date (UTC).

- `MARKET_SEGMENT`: market segment label from `DIM_FLIGHT_TYPE_RULE`.

- `MARKET_SEGMENT_DESCR`: description from `DIM_FLIGHT_TYPE_RULE`.

- `UNIT_CODE`: fixed `"NM_AREA"`.

- `UNIT_NAME`: fixed `"Total Network Manager Area"`.

- `FLIGHT`: count of flights for the date/segment combination.
