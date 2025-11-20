# nocov start

pbwg_resolve_conn <- function(conn = NULL, schema = "PRU_DEV") {
  created <- FALSE
  if (is.null(conn)) {
    conn <- eurocontrol::db_connection(schema = schema)
    created <- TRUE
  }
  list(conn = conn, created = created)
}

pbwg_with_conn <- function(conn_info, expr) {
  on.exit({
    if (conn_info$created) {
      try(DBI::dbDisconnect(conn_info$conn), silent = TRUE)
    }
  }, add = TRUE)
  force(expr)
}

pbwg_sql_dates <- function(wef, til, fmt = "%d-%m-%Y", tz = "UTC") {
  start <- lubridate::as_date(wef, tz = tz)
  end <- lubridate::as_date(til, tz = tz)
  if (is.na(start) || is.na(end)) {
    cli::cli_abort("Start and end dates must be coercible to Date.")
  }
  if (start > end) {
    cli::cli_abort("Start date must be on or before end date.")
  }
  list(
    start = start,
    end = end,
    start_sql = format(start, fmt),
    end_sql = format(end, fmt)
  )
}

pbwg_attach_sql <- function(data, sql) {
  attr(data, "sql") <- sql
  data
}

pbwg_upper_names <- function(df) {
  names(df) <- toupper(names(df))
  df
}

pbwg_rowsum <- function(df, cols) {
  cols <- intersect(cols, names(df))
  if (length(cols) == 0) {
    return(rep(0, nrow(df)))
  }
  mat <- as.matrix(df[, cols, drop = FALSE])
  rowSums(mat, na.rm = TRUE)
}

pbwg_safe_rename <- function(df, mapping) {
  for (nm in names(mapping)) {
    old <- mapping[[nm]]
    if (old %in% names(df)) {
      df <- dplyr::rename(df, !!rlang::sym(nm) := !!rlang::sym(old))
    }
  }
  df
}

pbwg_recode_wtc <- function(wtc, category) {
  dplyr::case_when(
    wtc == "UNK" & category == "Commuter (TurboP)" ~ "M",
    wtc == "UNK" & category == "Light Turbo Prop" ~ "L",
    wtc == "UNK" & category == "Light/business jet" ~ "L",
    wtc == "UNK" & category == "Narrow body" ~ "M",
    wtc == "UNK" & category == "Piston" ~ "LP",
    wtc == "UNK" & category == "Regional Jet" ~ "M",
    wtc == "UNK" & category == "UNK" ~ "M",
    wtc == "UNK" & category == "Military Turbo Prop" ~ "M",
    wtc == "UNK" & category == "Helicopter" ~ "HEL",
    wtc == "UNK" & category == "Military Jet" ~ "M",
    wtc == "UNK" & category == "Wide body" ~ "H",
    wtc == "UNK" & category == "Large Turbo Prop" ~ "H",
    wtc == "UNK" & category == "Very Large Aircraft" ~ "J",
    TRUE ~ wtc
  )
}

pbwg_daio_plot <- function(daio_table) {
  if (!rlang::is_installed("plotly")) {
    return(NULL)
  }
  plotly::plot_ly(
    daio_table,
    x = ~ENTRY_DATE,
    y = ~FLTS,
    color = ~TYPE,
    type = "scatter",
    mode = "lines"
  )
}

pbwg_check_numbers <- function(df) {
  df |>
    dplyr::mutate(
      DAIO = .data$D + .data$A + .data$I + .data$O,
      D_DAIO = .data$FLIGHTS - .data$DAIO,
      HML = .data$HEAVY + .data$MED + .data$LIGHT,
      D_HML = .data$FLIGHTS - .data$HML,
      MARK = .data$SCHED + .data$CHARTER + .data$CARGO + .data$OTHER,
      D_MARK = .data$FLIGHTS - .data$MARK
    )
}

pbwg_check_messages <- function(df) {
  build_msg <- function(col, min_threshold = NULL, max_threshold = NULL) {
    msgs <- character()
    if (!is.null(min_threshold)) {
      val <- min(df[[col]], na.rm = TRUE)
      if (is.finite(val) && val < min_threshold) {
        msgs <- c(msgs, glue::glue("{col} too big ({val})"))
      }
    }
    if (!is.null(max_threshold)) {
      val <- max(df[[col]], na.rm = TRUE)
      if (is.finite(val) && val > max_threshold) {
        msgs <- c(msgs, glue::glue("{col} - high underestimate ({val})"))
      }
    }
    msgs
  }
  c(
    build_msg("D_DAIO", min_threshold = 0, max_threshold = 20),
    build_msg("D_HML", min_threshold = 0, max_threshold = 20),
    build_msg("D_MARK", min_threshold = 0, max_threshold = 20)
  )
}

# nocov end
