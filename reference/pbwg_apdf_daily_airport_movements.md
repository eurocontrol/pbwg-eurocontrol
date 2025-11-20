# Daily APDF airport summary

Rebuilds the parquet-export workflow from the PBWG tooling: pulls APDF
movements per airport, coerces registrations/types to the PBWG shape,
and aggregates daily arrivals/departures with a heavy/medium/light
split. Date ranges spanning multiple years are handled in yearly chunks
to keep queries manageable.

## Usage

``` r
pbwg_apdf_daily_airport_movements(
  airports,
  wef,
  til,
  conn = NULL,
  domestic_prefixes = pbwg_apdf_domestic_prefixes_default()
)
```

## Arguments

- airports:

  Character vector of ICAO airport codes.

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

- domestic_prefixes:

  Character prefixes used to flag domestic traffic via
  [`pbwg_apdf_is_domestic()`](https://eurocontrol.github.io/pbwg-eurocontrol/reference/pbwg_apdf_is_domestic.md).
  Defaults to the ECTL set defined in
  [`pbwg_apdf_domestic_prefixes_default()`](https://eurocontrol.github.io/pbwg-eurocontrol/reference/pbwg_apdf_domestic_prefixes_default.md).

## Value

Tibble with one row per airport per day containing:

- `ICAO`: airport code.

- `DATE`: movement date (UTC).

- `ARRS` / `DEPS`: arrival and departure counts.

- `HEAVY` / `MED` / `LIGHT`: counts by wake turbulence class
  (`AC_CLASS`-derived).

- `ARRS_DOM` / `DEPS_DOM`: domestic arrivals/departures matched on ICAO
  prefixes.
