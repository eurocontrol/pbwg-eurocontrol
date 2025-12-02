#' Daily DAIO traffic counts
#'
#' Runs the DAIO aggregation used by PBWG, grouping the FIR-time entries by
#' DAIO flag and region. Optional inclusion of `SK_SOURCE_ID` reproduces the
#' CHN-specific variant of the legacy Python query.
#'
#' @inheritParams pbwg_weight_segment_tfc_counts
#' @param region One or more TZ codes (e.g. `"ECAC"`). Values are embedded into
#'   the SQL `IN (...)` clause verbatim.
#' @param include_source_id Should `SK_SOURCE_ID` be returned? Defaults to
#'   `FALSE`, mirroring the classic DAIO table.
#'
#' @return A [tibble::tibble()] with `"sql"` attribute and columns:
#'   \itemize{
#'     \item{\code{YEAR}}{Numeric year derived from `ENTRY_TIME`.}
#'     \item{\code{MONTH}}{Numeric month derived from `ENTRY_TIME`.}
#'     \item{\code{ENTRY_DATE}}{Date (UTC) of the FIR entry.}
#'     \item{\code{TZ_NAME}}{Region name from `DIMCL_TZ`.}
#'     \item{\code{DAIO}}{DAIO flag (`D`, `A`, `I`, `O`).}
#'     \item{\code{SK_SOURCE_ID}}{Optional source ID when `include_source_id = TRUE`.}
#'     \item{\code{FLIGHT}}{Total flights for the grouping.}
#'   }
#' @export
pbwg_daio <- function(
    wef,
    til,
    region,
    include_source_id = FALSE,
    conn = NULL) {
  dates <- pbwg_sql_dates(wef, til)

  if (length(region) == 0) {
    cli::cli_abort("{.arg region} must contain at least one code.")
  }
  region <- toupper(region)
  conn_info <- pbwg_resolve_conn(conn)
  con <- conn_info$conn
  on.exit({
    if (conn_info$created) {
      try(DBI::dbDisconnect(con), silent = TRUE)
    }
  }, add = TRUE)

  start_expr <- dbplyr::sql(glue::glue("TO_DATE('{dates$start_sql}', 'dd-mm-yyyy')"))
  end_expr <- dbplyr::sql(glue::glue("TO_DATE('{dates$end_sql}', 'dd-mm-yyyy')"))

  fir <- dplyr::tbl(con, dbplyr::in_schema("SWH_DM", "DM_TZ_FIR_D2"))
  tz <- dplyr::tbl(con, dbplyr::in_schema("SWH_FCT", "DIMCL_TZ")) |>
    dplyr::select("SK_T2TR_ID", "TZ_NAME", "TZ_CODE")

  joined <- fir |>
    dplyr::inner_join(
      tz,
      by = c("SK_DIMCL_TZ_ID" = "SK_T2TR_ID")
    ) |>
    dplyr::filter(
      .data$TZ_CODE %in% region,
      !!start_expr <= .data$ENTRY_TIME,
      .data$ENTRY_TIME < !!end_expr
    )

  select_cols <- c("ENTRY_TIME", "TZ_NAME", "DAIO", "TF_TZ")
  group_cols <- c("ENTRY_TIME", "TZ_NAME", "DAIO")
  if (include_source_id) {
    select_cols <- c(select_cols, "SK_SOURCE_ID")
    group_cols <- c(group_cols, "SK_SOURCE_ID")
  }

  summary_tbl <- joined |>
    dplyr::select(dplyr::all_of(select_cols)) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_cols))) |>
    dplyr::summarise(
      FLIGHT = sum(.data$TF_TZ),
      .groups = "drop"
    )

  data <- summary_tbl |>
    dplyr::collect() |>
    dplyr::mutate(
      ENTRY_DATE = as.Date(.data$ENTRY_TIME),
      YEAR = lubridate::year(.data$ENTRY_TIME),
      MONTH = lubridate::month(.data$ENTRY_TIME)
    ) |>
    dplyr::arrange(.data$ENTRY_TIME)

  final_cols <- c("YEAR", "MONTH", "ENTRY_DATE", "TZ_NAME", "DAIO")
  if (include_source_id) {
    final_cols <- c(final_cols, "SK_SOURCE_ID")
  }
  final_cols <- c(final_cols, "FLIGHT")

  data <- data |>
    dplyr::select(dplyr::all_of(final_cols))

  desc <- glue::glue(
    "Derived from SWH_DM.DM_TZ_FIR_D2 joined to DIMCL_TZ for {dates$start} to {dates$end}"
  )
  pbwg_attach_sql(data, desc)
}
