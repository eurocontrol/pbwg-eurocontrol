# PBWG regional traffic summary (EUR view)

PBWG workflow that merges DAIO, H/M/L, and market segment statistics
into a single daily table.

## Usage

``` r
pbwg_traffic_summary(
  wef,
  til,
  region = "ECAC",
  schema = c("pbwg", "chn"),
  conn = NULL
)
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

- schema:

  Output shape: `"pbwg"` (default, full EUR table with ARRS/DEPS,
  domestic, overflights, and PAX) or `"chn"` (lean CHN-EUR dashboard
  schema).

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

- data:

  Tibble of daily metrics. For `schema = "pbwg"` columns are `REG`,
  `DATE`, `FLIGHTS`, `ARRS`, `DEPS`, `HEAVY`, `MED`, `LIGHT`,
  `ARRS_DOM`, `DEPS_DOM`, `OVR_FLTS`, `PAX`, `CARGO`, `OTHER`, `D`, `A`,
  `I`, `O`, `SCHED`, `CHARTER`. For `schema = "chn"` columns are `REG`,
  `DATE`, `FLIGHTS`, `D`, `A`, `I`, `O`, `HEAVY`, `MED`, `LIGHT`,
  `SCHED`, `CHARTER`, `CARGO`, `OTHER`.

- plot:

  Optional `plotly` object showing DAIO breakdown if `plotly` is
  installed, otherwise `NULL`.

- diagnostics:

  List with `deltas` (sanity-check calculations) and `messages`
  (warnings about imbalances).

- raw:

  List of component tables: `weight_segment`, `market_segment`, and
  `daio`.
