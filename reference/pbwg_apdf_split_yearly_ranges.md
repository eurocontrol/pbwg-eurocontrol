# Split a date range into yearly APDF chunks

Breaks a `[wef, til]` span into one list element per calendar year,
allowing multi-year APDF summaries to be queried in manageable blocks.

## Usage

``` r
pbwg_apdf_split_yearly_ranges(wef, til)
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

## Value

List of lists with `wef` and `til` date entries for each year.
