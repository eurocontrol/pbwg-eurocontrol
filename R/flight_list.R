#' NM area traffic by wake turbulence category
#'
#' Counts Network Manager area flights per day and wake turbulence category,
#' filtering to operational statuses (`TE`, `TA`, `AA`) and the requested date
#' window. Uses [eurocontrol::flights_tbl()] as the base and joins aircraft
#' categories from `PRUDEV.V_PRU_AIRCRAFT_CATEGORY` (limited to PBWG-allowed
#' categories) before aggregating.
#'
#' @param wef Start date (inclusive). Can be anything that
#'   [lubridate::as_date()] understands.
#' @param til End date (inclusive). Can be anything that
#'   [lubridate::as_date()] understands.
#' @param conn Optional Oracle [DBI::DBIConnection-class]. When omitted a fresh
#'   connection to `PRUDEV` is created via [eurocontrol::db_connection()], with
#'   access to `SWH_FCT.V_FAC_FLIGHT_MS` and `PRUDEV.V_PRU_AIRCRAFT_CATEGORY`.
#'
#' @return A [tibble::tibble()] with one row per day/category combination and an
#'   attached `"sql"` attribute. Columns:
#'
#'   * `ENTRY_DATE`: truncated IFPZ entry date (UTC).
#'   * `MONTH`: numeric month extracted from `ENTRY_DATE`.
#'   * `YEAR`: numeric year extracted from `ENTRY_DATE`.
#'   * `WK_TBL_CAT`: wake turbulence category (L/M/H/J/UNK).
#'   * `CATEGORY1`: aircraft category level 1 from `V_PRU_AIRCRAFT_CATEGORY`.
#'   * `CATEGORY2`: aircraft category level 2 from `V_PRU_AIRCRAFT_CATEGORY`.
#'   * `FLIGHT`: count of flights for the date/category combination.
#'   * `UNIT_CODE`: fixed `"NM_AREA"`.
#'   * `UNIT_NAME`: fixed `"Total Network Manager Area"`.
#' @export
pbwg_weight_segment_tfc_counts <- function(wef, til, conn = NULL) {
  dates <- pbwg_sql_dates(wef, til)

  conn_info <- pbwg_resolve_conn(conn)
  con <- conn_info$conn
  on.exit({
    if (conn_info$created) {
      try(DBI::dbDisconnect(con), silent = TRUE)
    }
  }, add = TRUE)

  flights <- pbwg_filtered_flights(con, dates) |>
    dplyr::select(dplyr::all_of(c(
      "ENTRY_DATE",
      "WK_TBL_CAT",
      "AIRCRAFT_TYPE_ICAO_ID"
    )))

  cat_tbl <- dplyr::tbl(con, dbplyr::in_schema("PRUDEV", "V_PRU_AIRCRAFT_CATEGORY")) |>
    dplyr::select(dplyr::all_of(c("CIVIL_ICAO_ID", "CATEGORY1", "CATEGORY2")))

  allowed_cat <- dplyr::tbl(con, dbplyr::in_schema("PRUDEV", "PRU_GROUP_AIRCRAFT_CATEGORY")) |>
    dplyr::select("CATEGORY1") |>
    dplyr::distinct()

  acft_category <- cat_tbl |>
    dplyr::semi_join(allowed_cat, by = "CATEGORY1")

  summary_tbl <- flights |>
    dplyr::left_join(acft_category, by = c("AIRCRAFT_TYPE_ICAO_ID" = "CIVIL_ICAO_ID")) |>
    dplyr::mutate(
      WK_TBL_CAT = dplyr::coalesce(.data$WK_TBL_CAT, "UNK"),
      CATEGORY1 = dplyr::coalesce(.data$CATEGORY1, "UNK"),
      CATEGORY2 = dplyr::coalesce(.data$CATEGORY2, "UNK")
    ) |>
    dplyr::group_by(.data$ENTRY_DATE, .data$WK_TBL_CAT, .data$CATEGORY1, .data$CATEGORY2) |>
    dplyr::summarise(FLIGHT = dplyr::n(), .groups = "drop")

  data <- summary_tbl |>
    dplyr::collect() |>
    dplyr::mutate(
      ENTRY_DATE = as.Date(.data$ENTRY_DATE),
      MONTH = lubridate::month(.data$ENTRY_DATE),
      YEAR = lubridate::year(.data$ENTRY_DATE),
      UNIT_CODE = "NM_AREA",
      UNIT_NAME = "Total Network Manager Area"
    ) |>
    dplyr::select(
      dplyr::all_of(c(
        "ENTRY_DATE",
        "MONTH",
        "YEAR",
        "WK_TBL_CAT",
        "CATEGORY1",
        "CATEGORY2",
        "FLIGHT",
        "UNIT_CODE",
        "UNIT_NAME"
      ))
    )

  desc <- glue::glue(
    "Derived from eurocontrol::flights_tbl() for {dates$start} to {dates$end}"
  )
  pbwg_attach_sql(data, desc)
}

#' NM area traffic by market segment
#' 
#' Counts Network Manager area flights per day and market segment, filtering the
#' flights fact to operational statuses (`TE`, `TA`, `AA`) and the requested
#' date window. Segments are resolved through `SWH_FCT.DIM_FLIGHT_TYPE_RULE`,
#' and missing day/segment combinations are backfilled with zeros to give a
#' complete calendar grid.
#'
#' @inheritParams pbwg_weight_segment_tfc_counts
#'
#' @return A [tibble::tibble()] with one row per day/market segment and an
#'   attached `"sql"` attribute. Columns:
#'
#'   * `YEAR`: numeric year extracted from `ENTRY_DATE`.
#'   * `MONTH`: numeric month extracted from `ENTRY_DATE`.
#'   * `ENTRY_DATE`: truncated IFPZ entry date (UTC).
#'   * `MARKET_SEGMENT`: market segment label from `DIM_FLIGHT_TYPE_RULE`.
#'   * `MARKET_SEGMENT_DESCR`: description from `DIM_FLIGHT_TYPE_RULE`.
#'   * `UNIT_CODE`: fixed `"NM_AREA"`.
#'   * `UNIT_NAME`: fixed `"Total Network Manager Area"`.
#'   * `FLIGHT`: count of flights for the date/segment combination.
#' @export
pbwg_market_segment_tfc_counts <- function(wef, til, conn = NULL) {
  dates <- pbwg_sql_dates(wef, til)

  conn_info <- pbwg_resolve_conn(conn)
  con <- conn_info$conn
  on.exit({
    if (conn_info$created) {
      try(DBI::dbDisconnect(con), silent = TRUE)
    }
  }, add = TRUE)

  flights <- pbwg_filtered_flights(con, dates) |>
    dplyr::select(dplyr::all_of(c("ENTRY_DATE", "SK_FLT_TYPE_RULE_ID")))

  flights_segment <- flights |>
    dplyr::group_by(.data$ENTRY_DATE, .data$SK_FLT_TYPE_RULE_ID) |>
    dplyr::summarise(FLIGHT = dplyr::n(), .groups = "drop") |>
    dplyr::collect() |>
    dplyr::mutate(ENTRY_DATE = as.Date(.data$ENTRY_DATE))

  dim_segment <- dplyr::tbl(con, dbplyr::in_schema("SWH_FCT", "DIM_FLIGHT_TYPE_RULE")) |>
    dplyr::filter(.data$SK_FLT_TYPE_RULE_ID != 5L) |>
    dplyr::transmute(
      SK_FLT_TYPE_RULE_ID = .data$SK_FLT_TYPE_RULE_ID,
      MARKET_SEGMENT = .data$RULE_NAME,
      MARKET_SEGMENT_DESCR = .data$RULE_DESCRIPTION
    ) |>
    dplyr::collect()

  calendar <- tibble::tibble(
    ENTRY_DATE = seq(dates$start, dates$end, by = "day")
  ) |>
    dplyr::mutate(
      YEAR = lubridate::year(.data$ENTRY_DATE),
      MONTH = lubridate::month(.data$ENTRY_DATE)
    )

  grid <- tidyr::crossing(calendar, dim_segment)

  data <- grid |>
    dplyr::left_join(
      flights_segment,
      by = c("ENTRY_DATE", "SK_FLT_TYPE_RULE_ID")
    ) |>
    tidyr::replace_na(list(FLIGHT = 0)) |>
    dplyr::mutate(
      UNIT_CODE = "NM_AREA",
      UNIT_NAME = "Total Network Manager Area"
    ) |>
    dplyr::select(dplyr::all_of(c(
      "YEAR",
      "MONTH",
      "ENTRY_DATE",
      "MARKET_SEGMENT",
      "MARKET_SEGMENT_DESCR",
      "UNIT_CODE",
      "UNIT_NAME",
      "FLIGHT"
    )))

  desc <- glue::glue(
    "Derived from eurocontrol::flights_tbl() and DIM_FLIGHT_TYPE_RULE for {dates$start} to {dates$end}"
  )
  pbwg_attach_sql(data, desc)
}

pbwg_filtered_flights <- function(con, dates) {
  start_expr <- dbplyr::sql(glue::glue("TO_DATE('{dates$start_sql}', 'dd-mm-yyyy')"))
  end_expr <- dbplyr::sql(glue::glue("TO_DATE('{dates$end_sql}', 'dd-mm-yyyy')"))

  eurocontrol::flights_tbl(con) |>
    dplyr::filter(
      .data$FLT_STATUS %in% c("TE", "TA", "AA"),
      !!start_expr <= .data$LOBT,
      .data$LOBT <= !!end_expr,
      !!start_expr <= .data$IFPZ_ENTRY_TIME_ACT,
      .data$IFPZ_ENTRY_TIME_ACT <= !!end_expr
    ) |>
    dplyr::mutate(
      ENTRY_DATE = dbplyr::sql("TRUNC(IFPZ_ENTRY_TIME_ACT)")
    )
}
