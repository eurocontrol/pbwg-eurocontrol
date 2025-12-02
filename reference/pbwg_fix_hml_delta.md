# Distribute H/M/L delta back into categories

Adjusts Heavy/Medium/Light counts so they sum to the observed total
flights, allocating the discrepancy using fixed proportions.

## Usage

``` r
pbwg_fix_hml_delta(df)
```

## Arguments

- df:

  Tibble with daily H/M/L totals and `FLIGHTS`, containing columns
  `ENTRY_DATE`, `H`, `M`, `L`, `FLIGHTS`, `N_HML`, and `CHECK_N`.

## Value

Tibble with the input columns plus:

- `H2`Adjusted heavy movements.

- `M2`Adjusted medium movements.

- `L2`Adjusted light movements.

- `CHECK_N2`Adjusted total H/M/L sum.

- `DELTA`Remaining gap to `FLIGHTS` after adjustment.
