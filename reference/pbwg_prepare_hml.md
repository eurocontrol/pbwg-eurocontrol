# Prepare H/M/L counts

Aggregates raw weight category counts into Heavy/Medium/Light totals,
reconciles them against overall flight counts, and returns daily H/M/L.

## Usage

``` r
pbwg_prepare_hml(weight, flt)
```

## Arguments

- weight:

  Tibble of weight category counts with at least `ENTRY_DATE`,
  `WK_TBL_CAT`, `CATEGORY1`, and `FLIGHT`.

- flt:

  Tibble with overall flights per day, containing `ENTRY_DATE` and
  `FLIGHTS`.

## Value

Tibble with columns:

- `ENTRY_DATE`Date of operation.

- `HEAVY`Heavy aircraft movements.

- `MED`Medium aircraft movements.

- `LIGHT`Light aircraft movements.
