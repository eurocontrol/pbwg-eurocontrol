# OTP punctuality extract

Pulls CODA/CFMU punctuality counts for a set of airports and years by
reusing the legacy SQL embedded in `02-chn-eur-data-prep.Rmd`.

## Usage

``` r
pbwg_otp_punctuality(years, airports, conn = NULL)
```

## Arguments

- years:

  Integer vector of years (Gregorian) to retrieve.

- airports:

  Character vector of ICAO airport designators used for the TOP34 flag
  as well as the explicit airport columns in the result.

- conn:

  Optional Oracle
  [DBI::DBIConnection](https://dbi.r-dbi.org/reference/DBIConnection-class.html).
  When omitted a fresh `PRU_DEV` connection is created via
  [`eurocontrol::db_connection()`](https://eurocontrol.github.io/eurocontrol/reference/db_connection.html).

## Value

A tibble with one row per `(YY, MM, ADEP, ADES, PCT_DEP, PCT_ARR)`
combination; the executed SQL statements (one per year) are attached in
the `"sql"` attribute.
