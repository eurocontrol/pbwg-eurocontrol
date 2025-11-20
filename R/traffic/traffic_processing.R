#' PBWG regional traffic summary (EUR view)
#'
#' Recreates the composite PBWG workflow that merges DAIO, H/M/L,
#' and market segment statistics into a single daily table.
#'
#' @inheritParams pbwg_nm_area_weight_segment
#' @param region DAIO region code. Defaults to `"ECAC"`.
#'
#' @return A list with the processed `data`, an optional `plot` (if `plotly`
#'   is installed), diagnostic `details`, and the `raw` component tables.
#' @export
pbwg_traffic_summary <- function(wef, til, region = "ECAC", conn = NULL) {
  conn_info <- pbwg_resolve_conn(conn)
  con <- conn_info$conn
  on.exit({
    if (conn_info$created) {
      try(DBI::dbDisconnect(con), silent = TRUE)
    }
  }, add = TRUE)

  weight <- pbwg_nm_area_weight_segment(wef, til, conn = con)
  market <- pbwg_nm_area_market_segment(wef, til, conn = con)
  daio <- pbwg_daio(wef, til, region = region, include_source_id = TRUE, conn = con)

  processed <- pbwg_compile_components(weight, market, daio)

  pbwg <- processed$share |>
    dplyr::mutate(
      REG = "EUR",
      ARRS = .data$A + .data$I,
      DEPS = .data$D + .data$I,
      ARRS_DOM = .data$I,
      DEPS_DOM = .data$I,
      OVR_FLTS = .data$O,
      PAX = .data$SCHED + .data$CHARTER
    ) |>
    dplyr::select(
      "REG", "DATE", "FLIGHTS", "ARRS", "DEPS",
      "HEAVY", "MED", "LIGHT",
      "ARRS_DOM", "DEPS_DOM", "OVR_FLTS", "PAX",
      "CARGO", "OTHER",
      "D", "A", "I", "O",
      "SCHED", "CHARTER"
    )

  diagnostics <- list(
    deltas = processed$delta,
    messages = processed$messages
  )

  list(
    data = pbwg,
    plot = processed$plot,
    diagnostics = diagnostics,
    raw = list(
      weight_segment = weight,
      market_segment = market,
      daio = daio
    )
  )
}

#' CHN-EUR collaboration traffic summary
#'
#' Equivalent to the Python `query_process_chn()` routine. Returns the
#' streamlined table used in the CHN-EUR dashboard.
#'
#' @inheritParams pbwg_traffic_summary
#'
#' @return Same structure as [pbwg_traffic_summary()], but the `data`
#'   component matches the CHN-EUR schema.
#' @export
pbwg_chn_summary <- function(wef, til, region = "ECAC", conn = NULL) {
  conn_info <- pbwg_resolve_conn(conn)
  con <- conn_info$conn
  on.exit({
    if (conn_info$created) {
      try(DBI::dbDisconnect(con), silent = TRUE)
    }
  }, add = TRUE)

  weight <- pbwg_nm_area_weight_segment(wef, til, conn = con)
  market <- pbwg_nm_area_market_segment(wef, til, conn = con)
  daio <- pbwg_daio(wef, til, region = region, include_source_id = TRUE, conn = con)

  processed <- pbwg_compile_components(weight, market, daio)

  eur <- processed$share |>
    dplyr::mutate(REG = "EUR") |>
    dplyr::select(
      "REG", "DATE", "FLIGHTS",
      "D", "A", "I", "O",
      "HEAVY", "MED", "LIGHT",
      "SCHED", "CHARTER", "CARGO", "OTHER"
    )

  diagnostics <- list(
    deltas = processed$delta,
    messages = processed$messages
  )

  list(
    data = eur,
    plot = processed$plot,
    diagnostics = diagnostics,
    raw = list(
      weight_segment = weight,
      market_segment = market,
      daio = daio
    )
  )
}

pbwg_compile_components <- function(weight, market, daio) {
  weight <- pbwg_upper_names(weight)
  market <- pbwg_upper_names(market)
  daio <- pbwg_upper_names(daio)

  flt <- daio |>
    dplyr::group_by(.data$ENTRY_DATE) |>
    dplyr::summarise(FLIGHTS = sum(.data$FLIGHT), .groups = "drop")

  daio_wide <- daio |>
    dplyr::group_by(.data$ENTRY_DATE, .data$DAIO) |>
    dplyr::summarise(FLTS = sum(.data$FLIGHT), .groups = "drop") |>
    tidyr::pivot_wider(
      names_from = .data$DAIO,
      values_from = .data$FLTS,
      values_fill = 0
    ) |>
    dplyr::ungroup()

  needed <- c("D", "A", "I", "O")
  for (nm in needed) {
    if (!nm %in% names(daio_wide)) {
      daio_wide[[nm]] <- 0
    }
  }
  daio_wide <- daio_wide |>
    dplyr::select("ENTRY_DATE", dplyr::all_of(needed))

  hml2 <- pbwg_prepare_hml(weight, flt)
  seg <- pbwg_prepare_segments(market)

  counts <- flt |>
    dplyr::left_join(daio_wide, by = "ENTRY_DATE") |>
    dplyr::left_join(hml2, by = "ENTRY_DATE") |>
    dplyr::left_join(seg, by = "ENTRY_DATE")

  share <- counts |>
    dplyr::select(
      "ENTRY_DATE", "FLIGHTS",
      "D", "A", "I", "O",
      "HEAVY", "MED", "LIGHT",
      "SCHED", "CHARTER", "CARGO", "OTHER"
    ) |>
    dplyr::rename(DATE = .data$ENTRY_DATE)

  delta_df <- pbwg_check_numbers(share)
  messages <- pbwg_check_messages(delta_df)

  daio_melt <- daio_wide |>
    tidyr::pivot_longer(
      cols = tidyselect::all_of(needed),
      names_to = "TYPE",
      values_to = "FLTS"
    )

  list(
    share = share,
    delta = delta_df,
    messages = messages,
    plot = pbwg_daio_plot(
      daio_melt |>
        dplyr::mutate(ENTRY_DATE = .data$ENTRY_DATE)
    )
  )
}

pbwg_prepare_hml <- function(weight, flt) {
  hml <- weight |>
    dplyr::mutate(
      WK_TBL_CAT = stringr::str_trim(.data$WK_TBL_CAT),
      CATEGORY1 = stringr::str_trim(.data$CATEGORY1),
      WTC = pbwg_recode_wtc(.data$WK_TBL_CAT, .data$CATEGORY1)
    ) |>
    dplyr::group_by(.data$ENTRY_DATE, .data$WK_TBL_CAT, .data$CATEGORY1, .data$WTC) |>
    dplyr::summarise(FLIGHT = sum(.data$FLIGHT), .groups = "drop") |>
    tidyr::pivot_wider(
      names_from = .data$WTC,
      values_from = .data$FLIGHT,
      values_fill = 0
    )

  if ("H" %in% names(hml)) hml <- dplyr::rename(hml, H0 = "H")
  if ("L" %in% names(hml)) hml <- dplyr::rename(hml, L0 = "L")

  H_vals <- pbwg_rowsum(hml, c("H0", "J"))
  L_vals <- pbwg_rowsum(hml, c("L0", "LP"))

  hml <- hml |>
    dplyr::mutate(
      H = H_vals,
      L = L_vals,
      M = dplyr::coalesce(.data$M, 0),
      HEAVY = .data$H,
      MED = .data$M,
      LIGHT = .data$L
    )

  hml_check <- hml |>
    dplyr::group_by(.data$ENTRY_DATE) |>
    dplyr::summarise(
      H = sum(.data$HEAVY),
      M = sum(.data$MED),
      L = sum(.data$LIGHT),
      .groups = "drop"
    ) |>
    dplyr::left_join(flt, by = "ENTRY_DATE") |>
    dplyr::mutate(
      N_HML = .data$H + .data$M + .data$L,
      CHECK_N = .data$FLIGHTS - .data$N_HML
    )

  hml_check <- pbwg_fix_hml_delta(hml_check)

  hml_check |>
    dplyr::transmute(
      ENTRY_DATE,
      HEAVY = .data$H2,
      MED = .data$M2,
      LIGHT = .data$L2
    )
}

pbwg_fix_hml_delta <- function(df) {
  df |>
    dplyr::mutate(
      H2 = .data$H + as.integer(0.1299 * .data$CHECK_N),
      M2 = .data$M + as.integer(0.8026 * .data$CHECK_N),
      L2 = .data$L + as.integer(0.0675 * .data$CHECK_N),
      CHECK_N2 = .data$H2 + .data$M2 + .data$L2,
      DELTA = .data$FLIGHTS - .data$CHECK_N2
    )
}

pbwg_prepare_segments <- function(market) {
  seg <- market |>
    dplyr::group_by(.data$ENTRY_DATE, .data$MARKET_SEGMENT_DESCR) |>
    dplyr::summarise(FLIGHT = sum(.data$FLIGHT), .groups = "drop") |>
    tidyr::pivot_wider(
      names_from = .data$MARKET_SEGMENT_DESCR,
      values_from = .data$FLIGHT,
      values_fill = 0
    )

  seg <- seg |>
    dplyr::rename_with(
      .cols = -dplyr::all_of("ENTRY_DATE"),
      .fn = ~ stringr::str_replace_all(stringr::str_to_upper(.x), "[^A-Z0-9]+", "_")
    )

  ensure <- function(df, cols) {
    for (nm in cols) {
      if (!nm %in% names(df)) {
        df[[nm]] <- 0
      }
    }
    df
  }

  seg <- ensure(seg, c(
    "ALL_CARGO", "CHARTER", "MAINLINE", "LOWCOST",
    "REGIONAL_AIRCRAFT", "BUSINESS_AVIATION", "OTHER_TYPES",
    "MILITARY", "NOT_CLASSIFIED"
  ))

  seg |>
    dplyr::mutate(
      CARGO = .data$ALL_CARGO,
      CHARTER = .data$CHARTER,
      SCHED = .data$MAINLINE + .data$LOWCOST + .data$REGIONAL_AIRCRAFT,
      OTHER = .data$BUSINESS_AVIATION + .data$OTHER_TYPES +
        .data$MILITARY + .data$NOT_CLASSIFIED
    ) |>
    dplyr::select("ENTRY_DATE", "SCHED", "CHARTER", "CARGO", "OTHER")
}
