# OTP punctuality extract

Pulls CODA/CFMU punctuality counts for a set of airports and years using
a dbplyr translation of the legacy SQL embedded in
`02-chn-eur-data-prep.Rmd`. Flights are bucketed by departure/arrival
delay (\<=15 minutes vs \>15) and grouped by month and airport pairing
with TOP34 flags.

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

A tibble with an attached `"sql"` attribute (named vector of one SQL
string per requested year) and columns:

- `YY`Year truncated date (first day of the year).

- `MM`Month truncated date (first day of the month).

- `ADEP`Departure airport code; non-target airports grouped as `"OTH"`.

- `ADES`Destination airport code; non-target airports grouped as
  `"OTH"`.

- `FROM_TOP34``"Y"`/`"N"` flag if the departure airport is in the target
  set.

- `TO_TOP34``"Y"`/`"N"` flag if the destination airport is in the target
  set.

- `TOP34``"Y"` when either leg is in the target set, otherwise `"N"`.

- `PCT_DEP`Departure punctuality bucket (`<=15` or `>15`).

- `PCT_ARR`Arrival punctuality bucket (`<=15` or `>15`).

- `N_CODA`Number of CODA records in the bucket.

- `N_CFMU`Number of CFMU records in the bucket.

- `YEAR`Numeric year indicator matching the query year.
