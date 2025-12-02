#' OTP punctuality extract
#'
#' Pulls CODA/CFMU punctuality counts for a set of airports and years using a
#' dbplyr translation of the legacy SQL embedded in `02-chn-eur-data-prep.Rmd`.
#' Flights are bucketed by departure/arrival delay (<=15 minutes vs >15) and
#' grouped by month and airport pairing with TOP34 flags.
#'
#' @param years Integer vector of years (Gregorian) to retrieve.
#' @param airports Character vector of ICAO airport designators used for the
#'   TOP34 flag as well as the explicit airport columns in the result.
#' @param conn Optional Oracle [DBI::DBIConnection-class]. When omitted a fresh
#'   `PRU_DEV` connection is created via [eurocontrol::db_connection()].
#'
#' @return A tibble with an attached `"sql"` attribute (named vector of one SQL
#'   string per requested year) and columns:
#'   \itemize{
#'     \item{\code{YY}}{Year truncated date (first day of the year).}
#'     \item{\code{MM}}{Month truncated date (first day of the month).}
#'     \item{\code{ADEP}}{Departure airport code; non-target airports grouped as `"OTH"`.}
#'     \item{\code{ADES}}{Destination airport code; non-target airports grouped as `"OTH"`.}
#'     \item{\code{FROM_TOP34}}{`"Y"`/`"N"` flag if the departure airport is in the target set.}
#'     \item{\code{TO_TOP34}}{`"Y"`/`"N"` flag if the destination airport is in the target set.}
#'     \item{\code{TOP34}}{`"Y"` when either leg is in the target set, otherwise `"N"`.}
#'     \item{\code{PCT_DEP}}{Departure punctuality bucket (`<=15` or `>15`).}
#'     \item{\code{PCT_ARR}}{Arrival punctuality bucket (`<=15` or `>15`).}
#'     \item{\code{N_CODA}}{Number of CODA records in the bucket.}
#'     \item{\code{N_CFMU}}{Number of CFMU records in the bucket.}
#'     \item{\code{YEAR}}{Numeric year indicator matching the query year.}
#'   }
#' @export
pbwg_otp_punctuality <- function(years, airports, conn = NULL) {
  if (missing(years) || length(years) == 0) {
    cli::cli_abort("{.arg years} must contain at least one value.")
  }
  airports <- unique(toupper(airports))
  if (length(airports) == 0) {
    cli::cli_abort("{.arg airports} must contain at least one ICAO code.")
  }

  years <- sort(unique(as.integer(years)))

  conn_info <- pbwg_resolve_conn(conn, schema = "PRU_DEV")
  con <- conn_info$conn
  on.exit({
    if (conn_info$created) {
      try(DBI::dbDisconnect(con), silent = TRUE)
    }
  }, add = TRUE)

  queries <- purrr::map(
    years,
    ~ pbwg_build_otp_query(con, .x, airports)
  )

  sql_map <- purrr::map_chr(
    queries,
    dbplyr::sql_render,
    con = con
  )
  names(sql_map) <- years

  data <- purrr::map2_dfr(
    queries,
    years,
    ~ dplyr::collect(.x) |>
      dplyr::mutate(YEAR = .y)
  )

  pbwg_attach_sql(data, sql_map)
}

pbwg_build_otp_query <- function(con, year, airports) {
  next_year <- year + 1L
  start_expr <- dbplyr::sql(glue::glue("TO_DATE('01-JAN-{year}', 'DD-MON-YYYY')"))
  end_expr <- dbplyr::sql(glue::glue("TO_DATE('01-JAN-{next_year}', 'DD-MON-YYYY')"))

  dep_diff <- dbplyr::sql(
    "ROUND((TRUNC(ACTUAL_OUT, 'MI') - TRUNC(STD, 'MI')) * 1440)"
  )
  arr_diff <- dbplyr::sql(
    "ROUND((TRUNC(ACTUAL_IN, 'MI') - TRUNC(STA, 'MI')) * 1440)"
  )

  acars_tbl <- dplyr::tbl(con, dbplyr::in_schema("ACARS", "PRU_ACARS_FLIGHT"))
  t1 <- acars_tbl |>
    dplyr::filter(
      .data$ACTUAL_OUT >= !!start_expr,
      .data$ACTUAL_OUT < !!end_expr,
      .data$ACTUAL_OFF > .data$ACTUAL_OUT,
      .data$ACTUAL_IN > .data$ACTUAL_ON,
      .data$ACTUAL_ON > .data$ACTUAL_OFF,
      dplyr::between(!!arr_diff, -60, 720),
      dplyr::between(!!dep_diff, -60, 720)
    ) |>
    dplyr::transmute(
      ID = .data$ID,
      PCT_DEP = dplyr::if_else(!!dep_diff <= 15, "<=15", ">15"),
      PCT_ARR = dplyr::if_else(!!arr_diff <= 15, "<=15", ">15")
    )

  flights_tbl <- dplyr::tbl(con, dbplyr::in_schema("SWH_FCT", "FAC_FLIGHT"))
  airports_upper <- toupper(airports)

  t2 <- flights_tbl |>
    dplyr::filter(
      .data$LOBT >= !!start_expr,
      .data$LOBT < !!end_expr
    ) |>
    dplyr::transmute(
      ID = .data$ID,
      ID_F = .data$ID,
      MM = dbplyr::sql("TRUNC(LOBT, 'MM')"),
      YY = dbplyr::sql("TRUNC(LOBT, 'YYYY')"),
      ADES = dplyr::if_else(
        toupper(.data$ADES) %in% airports_upper,
        .data$ADES,
        "OTH"
      ),
      ADEP = dplyr::if_else(
        toupper(.data$ADEP) %in% airports_upper,
        .data$ADEP,
        "OTH"
      ),
      FROM_TOP34 = dplyr::if_else(
        toupper(.data$ADEP) %in% airports_upper,
        "Y",
        "N"
      ),
      TO_TOP34 = dplyr::if_else(
        toupper(.data$ADES) %in% airports_upper,
        "Y",
        "N"
      )
    )

  t1 |>
    dplyr::left_join(t2, by = "ID") |>
    dplyr::group_by(
      .data$YY,
      .data$MM,
      .data$ADEP,
      .data$ADES,
      .data$PCT_DEP,
      .data$PCT_ARR,
      .data$FROM_TOP34,
      .data$TO_TOP34
    ) |>
    dplyr::summarise(
      N_CODA = dplyr::n(),
      N_CFMU = dplyr::sum(dplyr::if_else(is.na(.data$ID_F), 0L, 1L)),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      TOP34 = dplyr::if_else(
        .data$FROM_TOP34 == "Y" | .data$TO_TOP34 == "Y",
        "Y",
        "N"
      )
    ) |>
    dplyr::select(
      "YY",
      "MM",
      "ADEP",
      "ADES",
      "FROM_TOP34",
      "TO_TOP34",
      "TOP34",
      "PCT_DEP",
      "PCT_ARR",
      "N_CODA",
      "N_CFMU"
    ) |>
    dplyr::arrange(.data$MM)
}
