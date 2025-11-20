# Fetch APDF records for a single airport

Queries `SWH_FCT.FAC_APDS_FLIGHT_IR691` via
[`eurocontrol::apdf_tbl()`](https://eurocontrol.github.io/eurocontrol/reference/apdf_tbl.html),
filters to one airport and date window, then collects the rows used by
the legacy pbwg-ectl-query-tool. The default column set mirrors the
Python extract and keeps operational details (`AC_CLASS`, runway/stand,
movement times) that are dropped by
[`eurocontrol::apdf_tidy()`](https://eurocontrol.github.io/eurocontrol/reference/apdf_tidy.html).

## Usage

``` r
pbwg_apdf_fetch_airport_raw(
  airport,
  wef,
  til,
  columns = pbwg_apdf_columns_default(),
  conn = NULL
)
```

## Arguments

- airport:

  ICAO airport designator (e.g. `"EIDW"`). Only a single code is
  allowed.

- wef:

  Start date (inclusive). Can be anything that
  [`lubridate::as_date()`](https://lubridate.tidyverse.org/reference/as_date.html)
  understands.

- til:

  End date (inclusive). Can be anything that
  [`lubridate::as_date()`](https://lubridate.tidyverse.org/reference/as_date.html)
  understands.

- columns:

  Vector of column names to include. Defaults to the exact set used by
  the Python scripts; see
  [`pbwg_apdf_columns_default()`](https://eurocontrol.github.io/pbwg-eurocontrol/reference/pbwg_apdf_columns_default.md)
  for details.

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
with the requested APDF columns and an attached `"sql"` attribute
describing the filter. Key fields include:

- `AP_C_FLTID`: flight identifier (source airport).

- `AP_C_FLTRUL`: rules under which the flight operates (`IFR`, `VFR`,
  `NA`).

- `AP_C_REG`: aircraft registration with separators removed.

- `ADEP_ICAO` / `ADES_ICAO`: departure/destination aerodrome (ICAO
  code).

- `SRC_PHASE`: `DEP` for departures, `ARR` for arrivals.

- `MVT_TIME_UTC` / `BLOCK_TIME_UTC` / `SCHED_TIME_UTC`: movement, block
  and scheduled times in UTC.

- `ARCTYP`: ICAO aircraft type code (e.g. `A21N`).

- `AC_CLASS`: wake turbulence class (kept for H/M/L aggregation).

- `AP_C_RWY` / `AP_C_STND`: runway and stand identifiers.

- `C40_*` / `C100_*`: first/last crossing time, position, level and
  bearing at 40 NM and 100 NM from the aerodrome reference point.
