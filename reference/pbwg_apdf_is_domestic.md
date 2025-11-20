# Detect domestic APDF traffic

Flags ICAO codes that start with any of the provided prefixes. Used by
the APDF summaries to derive domestic arrival/departure counts.

## Usage

``` r
pbwg_apdf_is_domestic(code, prefixes)
```

## Arguments

- code:

  ICAO code vector.

- prefixes:

  Vector of prefixes to match (upper-case).

## Value

Logical vector: `TRUE` when the code matches one of the prefixes.
