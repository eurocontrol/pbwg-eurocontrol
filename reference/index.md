# Package index

## Network-wide traffic counts

NM area counts by wake turbulence and market segment, plus raw DAIO
daily totals.

- [`pbwg_weight_segment_tfc_counts()`](https://eurocontrol.github.io/pbwg-eurocontrol/reference/pbwg_weight_segment_tfc_counts.md)
  : NM area traffic by wake turbulence category
- [`pbwg_market_segment_tfc_counts()`](https://eurocontrol.github.io/pbwg-eurocontrol/reference/pbwg_market_segment_tfc_counts.md)
  : NM area traffic by market segment
- [`pbwg_daio()`](https://eurocontrol.github.io/pbwg-eurocontrol/reference/pbwg_daio.md)
  : Daily DAIO traffic counts

## Regional summaries (EUR / CHN-EUR)

Daily roll-ups that merge DAIO, H/M/L, and market segments, with
diagnostics.

- [`pbwg_traffic_summary()`](https://eurocontrol.github.io/pbwg-eurocontrol/reference/pbwg_traffic_summary.md)
  : PBWG regional traffic summary (EUR view)
- [`pbwg_chn_summary()`](https://eurocontrol.github.io/pbwg-eurocontrol/reference/pbwg_chn_summary.md)
  : CHN-EUR collaboration traffic summary

## Airport-level APDF

APDF pulls for one or more airports, returning raw movement rows or
daily summaries with H/M/L and domestic flags.

- [`pbwg_apdf_fetch_airport_raw()`](https://eurocontrol.github.io/pbwg-eurocontrol/reference/pbwg_apdf_fetch_airport_raw.md)
  : Fetch APDF records for a single airport
- [`pbwg_apdf_daily_airport_movements()`](https://eurocontrol.github.io/pbwg-eurocontrol/reference/pbwg_apdf_daily_airport_movements.md)
  : Daily APDF airport summary

## Punctuality (from CODA AODF)

On-time performance extracts bucketed by \<=15 min vs \>15 min delays
for selected airports/years.

- [`pbwg_otp_punctuality()`](https://eurocontrol.github.io/pbwg-eurocontrol/reference/pbwg_otp_punctuality.md)
  : OTP punctuality extract

## Dataset exporters

Convenience wrapper to pull and persist CHN-EUR datasets in one call.

- [`fetch_chn_eur_datasets()`](https://eurocontrol.github.io/pbwg-eurocontrol/reference/fetch_chn_eur_datasets.md)
  : Fetch CHN-EUR datasets to Parquet
