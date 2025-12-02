# PBWG EUROCONTROL helper package

Provides high-level wrappers combining `eurocontrol` primitives and
purpose-built SQL for the PBWG ECTL workflows.

## User-facing functions

- pbwg_traffic_summary()Regional EUR traffic roll-up combining DAIO,
  wake turbulence, and market segment counts with diagnostics.

- pbwg_chn_summary()Lean variant of the traffic summary aligned with the
  CHN-EUR dashboard schema.

- pbwg_daio()Daily DAIO breakdowns by region, with optional
  `SK_SOURCE_ID`.

- pbwg_weight_segment_tfc_counts()Network Manager area traffic by wake
  turbulence category (NM flights fact + aircraft categories).

- pbwg_market_segment_tfc_counts()Network Manager area traffic by market
  segment (NM flights fact + flight type rule dimension).

- pbwg_apdf_fetch_airport_raw()Raw APDF rows for a single airport and
  date range, retaining operational fields used by PBWG tools.

- pbwg_apdf_daily_airport_movements()Daily APDF airport movements with
  arrivals/departures, H/M/L split, and domestic flags.

- pbwg_otp_punctuality()CODA/CFMU punctuality summary for selected
  airports and years.

- fetch_chn_eur_datasets()One-call exporter that pulls NM counts,
  regional roll-ups, APDF airport summaries, and OTP buckets to Parquet.

## Author

**Maintainer**: EUROCONTROL Performance Review Unit (PRU)
<pru-support@eurocontrol.int>
