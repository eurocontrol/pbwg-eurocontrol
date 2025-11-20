#' Fetch APDF records for a single airport
#'
#' Queries `SWH_FCT.FAC_APDS_FLIGHT_IR691` via [eurocontrol::apdf_tbl()], filters
#' to one airport and date window, then collects the rows used by the legacy
#' pbwg-ectl-query-tool. The default column set mirrors the Python extract and
#' keeps operational details (`AC_CLASS`, runway/stand, movement times) that are
#' dropped by `eurocontrol::apdf_tidy()`.
#'
#' @inheritParams pbwg_nm_area_weight_segment
#' @param airport ICAO airport designator (e.g. `"EIDW"`). Only a single code is
#'   allowed.
#' @param columns Vector of column names to include. Defaults to the exact set
#'   used by the Python scripts; see [pbwg_apdf_columns_default()] for details.
#'
#' @return A [tibble::tibble()] with the requested APDF columns and an attached
#'   `"sql"` attribute describing the filter. Key fields include:
#'
#'   * `AP_C_FLTID`: flight identifier (source airport).
#'   * `AP_C_FLTRUL`: rules under which the flight operates (`IFR`, `VFR`, `NA`).
#'   * `AP_C_REG`: aircraft registration with separators removed.
#'   * `ADEP_ICAO` / `ADES_ICAO`: departure/destination aerodrome (ICAO code).
#'   * `SRC_PHASE`: `DEP` for departures, `ARR` for arrivals.
#'   * `MVT_TIME_UTC` / `BLOCK_TIME_UTC` / `SCHED_TIME_UTC`: movement, block and
#'     scheduled times in UTC.
#'   * `ARCTYP`: ICAO aircraft type code (e.g. `A21N`).
#'   * `AC_CLASS`: wake turbulence class (kept for H/M/L aggregation).
#'   * `AP_C_RWY` / `AP_C_STND`: runway and stand identifiers.
#'   * `C40_*` / `C100_*`: first/last crossing time, position, level and bearing
#'     at 40 NM and 100 NM from the aerodrome reference point.
#' @export
pbwg_apdf_fetch_airport_raw <- function(
    airport,
    wef,
    til,
    columns = pbwg_apdf_columns_default(),
    conn = NULL) {
  if (length(airport) != 1) {
    cli::cli_abort("{.arg airport} must be a single ICAO code.")
  }
  airport <- toupper(airport)

  dates <- pbwg_sql_dates(wef, til, fmt = "%Y-%m-%d")
  start_expr <- dbplyr::sql(glue::glue(
    "TO_DATE('{dates$start_sql}', 'yyyy-mm-dd')"
  ))
  end_expr <- dbplyr::sql(glue::glue(
    "TO_DATE('{dates$end_sql}', 'yyyy-mm-dd') + 1"
  ))

  conn_info <- pbwg_resolve_conn(conn, schema = "PRU_ATMAP")
  con <- conn_info$conn
  on.exit({
    if (conn_info$created) {
      try(DBI::dbDisconnect(con), silent = TRUE)
    }
  }, add = TRUE)

  tbl <- eurocontrol::apdf_tbl(con) |>
    dplyr::filter(
      .data$SRC_AIRPORT == !!airport,
      .data$SRC_DATE_FROM >= !!start_expr,
      .data$SRC_DATE_FROM < !!end_expr
    ) |>
    dplyr::select(dplyr::any_of(columns))

  data <- tbl |>
    dplyr::collect() |>
    tibble::as_tibble()

  desc <- glue::glue(
    "apdf_tbl filtered for {airport} between {dates$start} and {dates$end}"
  )
  pbwg_attach_sql(data, desc)
}

#' Daily APDF airport summary
#'
#' Rebuilds the parquet-export workflow from the PBWG tooling: pulls APDF
#' movements per airport, coerces registrations/types to the PBWG shape, and
#' aggregates daily arrivals/departures with a heavy/medium/light split. Date
#' ranges spanning multiple years are handled in yearly chunks to keep queries
#' manageable.
#'
#' @param airports Character vector of ICAO airport codes.
#' @inheritParams pbwg_apdf_fetch_airport_raw
#' @param domestic_prefixes Character prefixes used to flag domestic traffic via
#'   [pbwg_apdf_is_domestic()]. Defaults to the ECTL set defined in
#'   [pbwg_apdf_domestic_prefixes_default()].
#'
#' @return Tibble with one row per airport per day containing:
#'
#'   * `ICAO`: airport code.
#'   * `DATE`: movement date (UTC).
#'   * `ARRS` / `DEPS`: arrival and departure counts.
#'   * `HEAVY` / `MED` / `LIGHT`: counts by wake turbulence class
#'     (`AC_CLASS`-derived).
#'   * `ARRS_DOM` / `DEPS_DOM`: domestic arrivals/departures matched on ICAO
#'     prefixes.
#' @export
pbwg_apdf_daily_airport_movements <- function(
    airports,
    wef,
    til,
    conn = NULL,
    domestic_prefixes = pbwg_apdf_domestic_prefixes_default()) {
  if (length(airports) == 0) {
    cli::cli_abort("{.arg airports} must contain at least one ICAO code.")
  }

  airports <- toupper(airports)
  intervals <- pbwg_apdf_split_yearly_ranges(wef, til)
  conn_info <- pbwg_resolve_conn(conn, schema = "PRU_ATMAP")
  con <- conn_info$conn
  on.exit({
    if (conn_info$created) {
      try(DBI::dbDisconnect(con), silent = TRUE)
    }
  }, add = TRUE)

  purrr::map_dfr(intervals, function(span) {
    purrr::map_dfr(airports, function(apt) {
      raw <- pbwg_apdf_fetch_airport_raw(apt, span$wef, span$til, conn = con)
      pbwg_apdf_daily_summarise(raw, apt, domestic_prefixes)
    })
  })
}

#' Columns used for APDF extracts
#'
#' Returns the default column set used by PBWG APDF queries. These fields carry
#' the identifiers, movement times and wake turbulence class needed for the
#' legacy airport-level summaries.
#'
#' @return Character vector of APDF column names.
#' @keywords internal
pbwg_apdf_columns_default <- function() {
  c(
    "AP_C_FLTID",
    "AP_C_REG",
    "ADEP_ICAO",
    "ADES_ICAO",
    "MVT_TIME_UTC",
    "BLOCK_TIME_UTC",
    "SCHED_TIME_UTC",
    "AP_C_FLTRUL",
    "ARCTYP",
    "AC_CLASS",
    "AP_C_RWY",
    "AP_C_STND",
    "SRC_PHASE",
    "C40_CROSS_TIME",
    "C40_CROSS_LAT",
    "C40_CROSS_LON",
    "C100_CROSS_TIME",
    "C100_CROSS_LAT",
    "C100_CROSS_LON",
    "C40_BEARING",
    "C100_BEARING"
  )
}

#' ICAO prefixes treated as domestic
#'
#' Helper list of ICAO country/region prefixes that define "domestic" APDF
#' traffic for PBWG reporting.
#'
#' @return Character vector of prefixes (upper-case).
#' @keywords internal
pbwg_apdf_domestic_prefixes_default <- function() {
  c(
    "LA", "LO", "EBB", "LQ", "LB", "LD", "LCP", "LK", "EK", "EE", "EF",
    "LF", "ED", "LG", "LH", "BI", "EI", "LI", "EY", "ELL", "LM", "LWMK",
    "EH", "EN", "EP", "LP", "LR", "LY", "LZ", "LJ", "LE", "ES", "LS", "LT",
    "EG", "UK", "L", "UG", "UB", "MD", "ARM"
  )
}

#' Summarise APDF movements for one airport/day
#'
#' Internal helper that normalises column names and wake-turbulence classes,
#' flags domestic traffic, drops helicopters, and aggregates arrivals/departures
#' plus H/M/L totals.
#'
#' @param raw_tbl Output of [pbwg_apdf_fetch_airport_raw()] or equivalent APDF data frame.
#' @param airport ICAO airport code used to flag arrivals vs departures.
#' @param domestic_prefixes Prefixes passed to [pbwg_apdf_is_domestic()].
#'
#' @return Tibble with one row per day for the provided airport, containing:
#'
#'   * `ICAO`: airport code.
#'   * `DATE`: movement date (UTC).
#'   * `ARRS` / `DEPS`: arrival and departure counts.
#'   * `HEAVY` / `MED` / `LIGHT`: counts by wake turbulence class.
#'   * `ARRS_DOM` / `DEPS_DOM`: domestic arrivals/departures based on prefixes.
#' @keywords internal
pbwg_apdf_daily_summarise <- function(raw_tbl, airport, domestic_prefixes) {
  df <- raw_tbl |>
    pbwg_upper_names() |>
    pbwg_safe_rename(c(
      "FLTID" = "AP_C_FLTID",
      "REGISTRATION" = "AP_C_REG",
      "ADEP" = "ADEP_ICAO",
      "ADES" = "ADES_ICAO",
      "MVT_TIME" = "MVT_TIME_UTC",
      "BLOCK_TIME" = "BLOCK_TIME_UTC",
      "SCHED_TIME" = "SCHED_TIME_UTC",
      "FLTRUL" = "AP_C_FLTRUL",
      "CLASS" = "AC_CLASS",
      "RWY" = "AP_C_RWY",
      "STAND" = "AP_C_STND"
    )) |>
    dplyr::mutate(
      CLASS = dplyr::na_if(.data$CLASS, ""),
      CLASS = dplyr::case_match(
        .data$CLASS,
        "MJ" ~ "MED",
        "H" ~ "HEAVY",
        "MT" ~ "MED",
        "LJ" ~ "LIGHT",
        "LT" ~ "LIGHT",
        "LP" ~ "LIGHT",
        "LIGHT" ~ "LIGHT",
        .default = .data$CLASS
      ),
      MVT_TIME = suppressWarnings(lubridate::as_datetime(.data$MVT_TIME, tz = "UTC")),
      DATE = as.Date(.data$MVT_TIME),
      ARRS = .data$ADES == airport,
      DEPS = .data$ADEP == airport
    ) |>
    dplyr::mutate(
      ARRS_DOM = .data$ARRS & pbwg_apdf_is_domestic(.data$ADEP, domestic_prefixes),
      DEPS_DOM = .data$DEPS & pbwg_apdf_is_domestic(.data$ADES, domestic_prefixes)
    ) |>
    dplyr::filter(!is.na(.data$DATE)) |>
    dplyr::filter(.data$CLASS != "HEL" | is.na(.data$CLASS))

  daily <- df |>
    dplyr::group_by(.data$DATE) |>
    dplyr::summarise(
      ARRS = sum(.data$ARRS, na.rm = TRUE),
      DEPS = sum(.data$DEPS, na.rm = TRUE),
      ARRS_DOM = sum(.data$ARRS_DOM, na.rm = TRUE),
      DEPS_DOM = sum(.data$DEPS_DOM, na.rm = TRUE),
      .groups = "drop"
    )

  class_counts <- df |>
    dplyr::filter(!is.na(.data$CLASS)) |>
    dplyr::count(.data$DATE, .data$CLASS, name = "COUNT") |>
    tidyr::pivot_wider(
      names_from = .data$CLASS,
      values_from = .data$COUNT,
      values_fill = 0
    )

  for (nm in c("HEAVY", "MED", "LIGHT")) {
    if (!nm %in% names(class_counts)) {
      class_counts[[nm]] <- 0
    }
  }

  daily |>
    dplyr::left_join(class_counts, by = "DATE") |>
    dplyr::mutate(
      ICAO = airport,
      HEAVY = dplyr::coalesce(.data$HEAVY, 0L),
      MED = dplyr::coalesce(.data$MED, 0L),
      LIGHT = dplyr::coalesce(.data$LIGHT, 0L)
    ) |>
    dplyr::select(
      "ICAO", "DATE", "ARRS", "DEPS", "HEAVY", "MED", "LIGHT",
      "ARRS_DOM", "DEPS_DOM"
    )
}

#' Detect domestic APDF traffic
#'
#' Flags ICAO codes that start with any of the provided prefixes. Used by the
#' APDF summaries to derive domestic arrival/departure counts.
#'
#' @param code ICAO code vector.
#' @param prefixes Vector of prefixes to match (upper-case).
#'
#' @return Logical vector: `TRUE` when the code matches one of the prefixes.
#' @keywords internal
pbwg_apdf_is_domestic <- function(code, prefixes) {
  patt <- stringr::regex(
    paste0("^(", paste(prefixes, collapse = "|"), ")"),
    ignore_case = FALSE
  )
  stringr::str_detect(dplyr::coalesce(code, ""), patt)
}

#' Split a date range into yearly APDF chunks
#'
#' Breaks a `[wef, til]` span into one list element per calendar year, allowing
#' multi-year APDF summaries to be queried in manageable blocks.
#'
#' @inheritParams pbwg_nm_area_weight_segment
#'
#' @return List of lists with `wef` and `til` date entries for each year.
#' @keywords internal
pbwg_apdf_split_yearly_ranges <- function(wef, til) {
  dates <- pbwg_sql_dates(wef, til)
  start_year <- lubridate::year(dates$start)
  end_year <- lubridate::year(dates$end)
  purrr::map(seq.int(start_year, end_year), function(year) {
    year_start <- as.Date(glue::glue("{year}-01-01"))
    year_end <- as.Date(glue::glue("{year}-12-31"))
    list(
      wef = max(dates$start, year_start),
      til = min(dates$end, year_end)
    )
  })
}
