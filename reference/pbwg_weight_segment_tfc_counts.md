# NM area traffic by wake turbulence category

Counts Network Manager area flights per day and wake turbulence
category, filtering to operational statuses (`TE`, `TA`, `AA`) and the
requested date window. Uses
[`eurocontrol::flights_tbl()`](https://eurocontrol.github.io/eurocontrol/reference/flights_tbl.html)
as the base and joins aircraft categories from
`PRUDEV.V_PRU_AIRCRAFT_CATEGORY` (limited to PBWG-allowed categories)
before aggregating.

## Usage

``` r
pbwg_weight_segment_tfc_counts(wef, til, conn = NULL)
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
with one row per day/category combination and an attached `"sql"`
attribute. Columns:

- `ENTRY_DATE`: truncated IFPZ entry date (UTC).

- `MONTH`: numeric month extracted from `ENTRY_DATE`.

- `YEAR`: numeric year extracted from `ENTRY_DATE`.

- `WK_TBL_CAT`: wake turbulence category (L/M/H/J/UNK).

- `CATEGORY1`: aircraft category level 1 from `V_PRU_AIRCRAFT_CATEGORY`.

- `CATEGORY2`: aircraft category level 2 from `V_PRU_AIRCRAFT_CATEGORY`.

- `FLIGHT`: count of flights for the date/category combination.

- `UNIT_CODE`: fixed `"NM_AREA"`.

- `UNIT_NAME`: fixed `"Total Network Manager Area"`.
