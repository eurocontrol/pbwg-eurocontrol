#' Fetch CHN-EUR datasets to Parquet
#'
#' Downloads NM area traffic counts (weight and market segments), regional
#' roll-ups, APDF airport traffic counts, and OTP punctuality buckets for a date
#' window, writing each dataset to Parquet files for downstream CHN-EUR
#' reporting.
#'
#' @param wef Date; start of the interval (inclusive).
#' @param til Date; end of the interval (inclusive).
#' @param airports Character vector of ICAO airport codes to include for APDF
#'   and OTP datasets.
#' @param years Optional integer vector of years for OTP. Defaults to all years
#'   overlapping `[wef, til]`.
#' @param include_weight Logical; fetch NM area weight segment counts.
#' @param include_market Logical; fetch NM area market segment counts.
#' @param include_regional Logical; fetch regional roll-up (PBWG schema).
#' @param include_airport Logical; fetch APDF airport traffic counts.
#' @param include_otp Logical; fetch OTP punctuality buckets.
#' @param out_dir Output directory; created if missing.
#'
#' @return Invisibly returns `TRUE` after writing requested datasets.
#' @export
fetch_chn_eur_datasets <- function(
    wef = as.Date("2019-01-01"),
    til = as.Date("2025-06-30"),
    airports = c(
      "EDDF", "EDDM", "EGKK", "EGLL", "EHAM", "LEBL",
      "LEMD", "LFPG", "LGAV", "LIRF", "LSZH", "LTFM"
    ),
    years = NULL,
    include_weight = TRUE,
    include_market = TRUE,
    include_regional = TRUE,
    include_airport = TRUE,
    include_otp = TRUE,
    out_dir = "data/eur") {

  if (!requireNamespace("arrow", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg arrow} must be installed to write Parquet outputs.")
  }

  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  start_chr <- format(wef, "%Y-%m-%d")
  end_chr <- format(til, "%Y-%m-%d")

  if (include_weight) {
    path_weight <- file.path(out_dir, glue::glue("NM_AREA_WEIGHT_SEGMENT_RESULT_{start_chr}_{end_chr}.parquet"))
    if (file.exists(path_weight)) {
      cli::cli_inform("Skipping NM area weight segment counts (exists).")
    } else {
      cli::cli_inform("Fetching NM area weight segment counts...")
      nm_weight <- pbwg_weight_segment_tfc_counts(wef, til)
      arrow::write_parquet(nm_weight, path_weight)
    }
  }

  if (include_market) {
    path_market <- file.path(out_dir, glue::glue("NM_AREA_MARKET_SEGMENT_RESULT_{start_chr}_{end_chr}.parquet"))
    if (file.exists(path_market)) {
      cli::cli_inform("Skipping NM area market segment counts (exists).")
    } else {
      cli::cli_inform("Fetching NM area market segment counts...")
      nm_market <- pbwg_market_segment_tfc_counts(wef, til)
      arrow::write_parquet(nm_market, path_market)
    }
  }

  if (include_regional) {
    path_regional <- file.path(out_dir, glue::glue("EUR_TFC_COUNTS_{start_chr}_{end_chr}.parquet"))
    if (file.exists(path_regional)) {
      cli::cli_inform("Skipping regional traffic summary (exists).")
    } else {
      cli::cli_inform("Fetching regional traffic summary (PBWG schema)...")
      pbwg_data <- pbwg_traffic_summary(wef, til, schema = "pbwg")$data
      arrow::write_parquet(pbwg_data, path_regional)
    }
  }

  if (include_airport) {
    cli::cli_inform("Fetching APDF airport traffic counts...")
    purrr::walk(
      unique(toupper(airports)),
      function(icao) {
        out_path <- file.path(
          out_dir,
          glue::glue("{icao}_{start_chr}_{end_chr}_APDF.parquet")
        )
        raw_path <- file.path(
          out_dir,
          glue::glue("{icao}_{start_chr}_{end_chr}_APDF_RAW.parquet")
        )
        need_summary <- !file.exists(out_path)
        need_raw <- !file.exists(raw_path)

        if (!need_summary && !need_raw) {
          cli::cli_inform("Skipping APDF for {icao} (exists).")
          return(invisible())
        }

        cli::cli_inform("Fetching APDF for {icao}...")
        apdf <- pbwg_apdf_daily_airport_movements(
          icao,
          wef,
          til,
          include_raw = need_raw
        )

        if (need_summary) {
          daily <- if (need_raw) apdf$data else apdf
          arrow::write_parquet(daily, out_path)
          cli::cli_inform("Wrote APDF summary for {icao} to {out_path}.")
        }

        if (need_raw) {
          arrow::write_parquet(apdf$raw, raw_path)
          cli::cli_inform("Wrote APDF raw for {icao} to {raw_path}.")
        }
      }
    )
  }

  if (include_otp) {
    path_otp <- file.path(out_dir, glue::glue("OTP_RESULT_{start_chr}_{end_chr}.parquet"))
    if (file.exists(path_otp)) {
      cli::cli_inform("Skipping OTP punctuality buckets (exists).")
    } else {
      cli::cli_inform("Fetching OTP punctuality buckets...")
      otp_years <- years
      if (is.null(otp_years)) {
        otp_years <- seq.int(lubridate::year(as.Date(wef)), lubridate::year(as.Date(til)))
      }
      otp <- pbwg_otp_punctuality(otp_years, airports)
      arrow::write_parquet(otp, path_otp)
    }
  }

  invisible(TRUE)
}
