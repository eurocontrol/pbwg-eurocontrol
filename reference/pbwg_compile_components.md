# Compile DAIO, weight, and market components

Internal helper that normalises the component tables, aligns dates, and
produces both share data and diagnostics.

## Usage

``` r
pbwg_compile_components(weight, market, daio)
```

## Arguments

- weight:

  Tibble of weight category counts with columns including `ENTRY_DATE`,
  `WK_TBL_CAT`, `CATEGORY1`, and `FLIGHT`.

- market:

  Tibble of market segment counts with columns including `ENTRY_DATE`,
  `MARKET_SEGMENT_DESCR`, and `FLIGHT`.

- daio:

  Tibble of DAIO counts with columns including `ENTRY_DATE`, `DAIO`, and
  `FLIGHT`.

## Value

A list with:

- `share`:

  Tibble with columns `DATE`, `FLIGHTS`, `D`, `A`, `I`, `O`, `HEAVY`,
  `MED`, `LIGHT`, `SCHED`, `CHARTER`, `CARGO`, `OTHER`.

- `delta`:

  Output of `pbwg_check_numbers()` adding `DAIO`, `D_DAIO`, `HML`,
  `D_HML`, `MARK`, and `D_MARK` to the share columns.

- `messages`:

  Character vector of diagnostic messages from `pbwg_check_messages()`.

- `plot`:

  Optional `plotly` object showing the DAIO breakdown, otherwise `NULL`.
