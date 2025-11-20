#' OTP punctuality extract
#'
#' Pulls CODA/CFMU punctuality counts for a set of airports and years by
#' reusing the legacy SQL embedded in `02-chn-eur-data-prep.Rmd`.
#'
#' @param years Integer vector of years (Gregorian) to retrieve.
#' @param airports Character vector of ICAO airport designators used for the
#'   TOP34 flag as well as the explicit airport columns in the result.
#' @param conn Optional Oracle [DBI::DBIConnection-class]. When omitted a fresh
#'   `PRU_DEV` connection is created via [eurocontrol::db_connection()].
#'
#' @return A tibble with one row per `(YY, MM, ADEP, ADES, PCT_DEP, PCT_ARR)`
#'   combination; the executed SQL statements (one per year) are attached in the
#'   `"sql"` attribute.
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
  sql_map <- purrr::map_chr(
    years,
    ~ pbwg_build_otp_sql(.x, airports)
  )
  names(sql_map) <- years

  conn_info <- pbwg_resolve_conn(conn, schema = "PRU_DEV")
  con <- conn_info$conn
  on.exit({
    if (conn_info$created) {
      try(DBI::dbDisconnect(con), silent = TRUE)
    }
  }, add = TRUE)

  data <- purrr::map2_dfr(
    sql_map,
    years,
    ~ DBI::dbGetQuery(con, .x) |>
      tibble::as_tibble() |>
      dplyr::mutate(YEAR = .y)
  )

  pbwg_attach_sql(data, sql_map)
}

pbwg_build_otp_sql <- function(year, airports) {
  next_year <- year + 1L
  airport_string <- paste(airports, collapse = ",")
  glue::glue(
    "
    WITH apt_one_list AS (
      SELECT '{airport_string}' AS ids
      FROM dual
    ),
    apts AS (
      SELECT TRIM(REGEXP_SUBSTR(ids, '[^,]+', 1, LEVEL)) AS apt_id
      FROM apt_one_list
      CONNECT BY LEVEL <= LENGTH(ids) - LENGTH(REPLACE(ids, ',', '')) + 1
    ),
    t1 AS (
      SELECT
        actual_out,
        id AS id_a,
        CASE
          WHEN ROUND((TRUNC(actual_out, 'MI') - TRUNC(std, 'MI')) * 1440) <= 15 THEN '<=15'
          ELSE '>15'
        END AS pct_dep,
        CASE
          WHEN ROUND((TRUNC(actual_in, 'MI') - TRUNC(sta, 'MI')) * 1440) <= 15 THEN '<=15'
          ELSE '>15'
        END AS pct_arr
      FROM acars.pru_acars_flight
      WHERE actual_out >= TO_DATE('01-JAN-{year}', 'DD-MON-YYYY')
        AND actual_out < TO_DATE('01-JAN-{next_year}', 'DD-MON-YYYY')
        AND (actual_out IS NULL OR actual_off > actual_out)
        AND (actual_out IS NULL OR actual_in > actual_on)
        AND (actual_out IS NULL OR actual_on > actual_off)
        AND (actual_out IS NULL OR ROUND((actual_in - sta) * 1440) BETWEEN -60 AND 720)
        AND (actual_out IS NULL OR ROUND((actual_out - std) * 1440) BETWEEN -60 AND 720)
    ),
    t2 AS (
      SELECT
        TRUNC(lobt, 'MM') AS mm,
        TRUNC(lobt, 'YYYY') AS yy,
        CASE
          WHEN UPPER(ades) IN (SELECT apt_id FROM apts) THEN ades
          ELSE 'OTH'
        END AS ades,
        CASE
          WHEN UPPER(adep) IN (SELECT apt_id FROM apts) THEN adep
          ELSE 'OTH'
        END AS adep,
        CASE
          WHEN UPPER(adep) IN (SELECT apt_id FROM apts) THEN 'Y'
          ELSE 'N'
        END AS from_top34,
        CASE
          WHEN UPPER(ades) IN (SELECT apt_id FROM apts) THEN 'Y'
          ELSE 'N'
        END AS to_top34,
        id AS id_f
      FROM swh_fct.fac_flight
      WHERE lobt >= TO_DATE('01-JAN-{year}', 'DD-MON-YYYY')
        AND lobt < TO_DATE('01-JAN-{next_year}', 'DD-MON-YYYY')
    ),
    t3 AS (
      SELECT a.*, b.*
      FROM t1 a
      LEFT JOIN t2 b ON a.id_a = b.id_f
    )
    SELECT
      yy,
      mm,
      adep,
      ades,
      from_top34,
      to_top34,
      CASE
        WHEN from_top34 = 'Y' OR to_top34 = 'Y' THEN 'Y'
        ELSE 'N'
      END AS top34,
      pct_dep,
      pct_arr,
      COUNT(id_a) AS n_coda,
      COUNT(id_f) AS n_cfmu
    FROM t3
    GROUP BY
      yy,
      mm,
      adep,
      ades,
      pct_dep,
      pct_arr,
      from_top34,
      to_top34
    ORDER BY
      mm
    "
  )
}
