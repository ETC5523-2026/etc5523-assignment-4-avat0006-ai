#' Launch the TB Progress Tracker app
#'
#' Starts the Shiny app stored in the package's `inst/app` folder. The app is
#' built for a **public-health analyst or policy student** who wants to answer
#' one question: *is a country's TB burden falling fast enough to meet the WHO
#' End TB milestones, and how does it compare with its region?*
#'
#' The app uses only the data bundled in the package ([tb_burden]); it does not
#' read any external file or need an internet connection.
#'
#' @param launch.browser Open the app in a web browser? Defaults to `TRUE` when
#'   R is running interactively. Passed to [shiny::runApp()].
#' @param ... Further arguments passed to [shiny::runApp()], for example
#'   `port = 8080`.
#'
#' @return Called for its side effect of running the app; returns invisibly
#'   when the app is stopped.
#' @export
#' @examples
#' if (interactive()) {
#'   run_tb_app()
#' }
run_tb_app <- function(launch.browser = interactive(), ...) {
  app_dir <- system.file("app", package = "tbprogress")
  if (!nzchar(app_dir)) {
    stop(
      "Could not find the app directory. Try re-installing 'tbprogress'.",
      call. = FALSE
    )
  }
  shiny::runApp(app_dir, launch.browser = launch.browser, ...)
}

#' Visual theme for the TB Progress Tracker app
#'
#' A [bslib::bs_theme()] with the colours and fonts used by the app. Exported
#' so that the app (which lives in `inst/app`) and any custom app can share it.
#'
#' @return A [bslib::bs_theme()] object.
#' @export
#' @examples
#' tb_app_theme()
tb_app_theme <- function() {
  bslib::bs_theme(
    version = 5,
    bg = "#FBFAF7",
    fg = "#1B2A32",
    primary = "#0B5C6B",
    secondary = "#5B6B73",
    success = "#2F7D4F",
    warning = "#B26A00",
    danger = "#B3261E",
    base_font = bslib::font_collection(
      "system-ui", "-apple-system", "Segoe UI", "Roboto", "Helvetica Neue",
      "Arial", "sans-serif"
    ),
    heading_font = bslib::font_collection(
      "system-ui", "-apple-system", "Segoe UI", "Roboto", "Helvetica Neue",
      "Arial", "sans-serif"
    )
  )
}

#' Format a progress summary as an interactive table
#'
#' Turns the output of [tb_progress_summary()] into a [DT::datatable()] with
#' readable column names and colour-coded status labels (the status is always
#' also written as text, so colour is never the only signal).
#'
#' @param summary A data frame returned by [tb_progress_summary()].
#'
#' @return A [DT::datatable()] widget.
#' @export
#' @examples
#' s <- tb_progress_summary(indicator = "incidence",
#'                          countries = c("Kenya", "India", "Brazil"))
#' tb_status_table(s)
tb_status_table <- function(summary) {
  check_tb_data(
    summary,
    c("country", "who_region", "assess_year", "baseline_value", "current_value",
      "reduction_pct", "required_reduction_pct", "gap_pp", "status", "indicator")
  )
  if (nrow(summary) == 0) {
    stop("`summary` has no rows.", call. = FALSE)
  }
  ay <- summary$assess_year[1]
  is_rate <- summary$indicator[1] == "incidence"
  digits <- if (is_rate) 1 else 0

  tab <- data.frame(
    Country = summary$country,
    Region = as.character(summary$who_region),
    Baseline = summary$baseline_value,
    Current = summary$current_value,
    Reduction = summary$reduction_pct,
    Required = summary$required_reduction_pct,
    Gap = summary$gap_pp,
    Status = as.character(summary$status),
    stringsAsFactors = FALSE
  )
  names(tab) <- c(
    "Country", "WHO region", "2015 value", paste(ay, "value"),
    "Reduction since 2015 (%)", paste0("Needed by ", ay, " (%)"),
    "Gap (pct. points)", "Status"
  )

  DT::datatable(
    tab,
    rownames = FALSE,
    class = "stripe hover compact",
    options = list(dom = "t", paging = FALSE, ordering = TRUE, scrollX = TRUE),
    caption = NULL
  ) |>
    DT::formatRound(c("2015 value", paste(ay, "value")), digits = digits) |>
    DT::formatRound(
      c("Reduction since 2015 (%)", paste0("Needed by ", ay, " (%)"),
        "Gap (pct. points)"),
      digits = 1
    ) |>
    DT::formatStyle(
      "Status",
      fontWeight = "bold",
      backgroundColor = DT::styleEqual(
        c("On track", "Behind", "Rising", "No data"),
        c("#D5EDDC", "#FFE7BF", "#F8D3D0", "#E5E7EB")
      )
    )
}
