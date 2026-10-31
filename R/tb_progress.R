#' The baseline year used by the WHO End TB Strategy
#' @noRd
tb_baseline_year <- 2015L

#' Describe an indicator: which column of `tb_burden` it uses and how to label it
#' @param indicator `"incidence"` or `"mortality"`.
#' @noRd
tb_indicator_info <- function(indicator) {
  switch(
    indicator,
    incidence = list(
      column = "incidence_rate",
      label = "TB incidence rate",
      phrase = "the TB incidence rate",
      short = "Incidence rate",
      unit = "new cases per 100,000 people"
    ),
    mortality = list(
      column = "mortality_n",
      label = "Number of TB deaths",
      phrase = "the number of TB deaths",
      short = "TB deaths",
      unit = "deaths per year"
    )
  )
}

#' Check a data frame has the columns a function needs
#' @noRd
check_tb_data <- function(data, needed) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame such as `tb_burden`.", call. = FALSE)
  }
  missing_cols <- setdiff(needed, names(data))
  if (length(missing_cols) > 0) {
    stop(
      "`data` is missing required column(s): ",
      paste(missing_cols, collapse = ", "), ".",
      call. = FALSE
    )
  }
  invisible(data)
}

#' WHO End TB reduction required by a given year
#'
#' The WHO End TB Strategy sets reduction milestones (2020, 2025) and targets
#' (2030, 2035) relative to 2015 (see [tb_targets]). This function returns the
#' reduction a country would need to have achieved by any year, by linearly
#' interpolating between those points. Years before 2015 return 0 and years
#' after 2035 return the 2035 target.
#'
#' Linear interpolation between milestone years is a transparent simplification:
#' WHO does not define yearly milestones.
#'
#' @param year Numeric vector of years.
#' @param indicator Either `"incidence"` (TB incidence rate) or `"mortality"`
#'   (number of TB deaths).
#'
#' @return A numeric vector, the same length as `year`: the required
#'   percentage reduction compared with 2015.
#' @export
#' @examples
#' tb_required_reduction(c(2020, 2023, 2030), "incidence")
#' tb_required_reduction(2023, "mortality")
tb_required_reduction <- function(year, indicator = c("incidence", "mortality")) {
  indicator <- match.arg(indicator)
  if (!is.numeric(year)) {
    stop("`year` must be numeric.", call. = FALSE)
  }
  targets <- tbprogress::tb_targets
  targets <- targets[targets$indicator == indicator, ]
  targets <- targets[order(targets$year), ]
  stats::approx(
    x = targets$year, y = targets$reduction_pct,
    xout = year, rule = 2
  )$y
}

#' Index a country's TB burden against its 2015 baseline
#'
#' Rescales the chosen indicator so that each country's value in the baseline
#' year equals 100. An index of 60 in 2023 therefore means the burden is 40%
#' lower than in 2015. Countries whose baseline value is missing or zero get
#' `NA`, because a percentage change from zero is undefined.
#'
#' @param data A data frame with the columns of [tb_burden]. Defaults to
#'   [tb_burden].
#' @param indicator Either `"incidence"` (incidence rate per 100,000) or
#'   `"mortality"` (number of TB deaths).
#' @param baseline_year The year used as 100. Defaults to 2015, the baseline
#'   of the WHO End TB Strategy.
#' @param countries Optional character vector of country names to keep.
#'   `NULL` (default) keeps all countries.
#'
#' @return A tibble with one row per country-year and columns `country`,
#'   `iso3`, `who_region`, `year`, `value` (the indicator), `baseline_value`,
#'   `index` (baseline = 100) and `pct_change` (percent change since the
#'   baseline; negative means the burden has fallen).
#' @export
#' @examples
#' idx <- tb_index(indicator = "incidence", countries = c("Kenya", "India"))
#' subset(idx, year == 2023)
tb_index <- function(data = tbprogress::tb_burden,
                     indicator = c("incidence", "mortality"),
                     baseline_year = 2015L,
                     countries = NULL) {
  indicator <- match.arg(indicator)
  info <- tb_indicator_info(indicator)
  check_tb_data(data, c("country", "iso3", "who_region", "year", info$column))

  if (!is.null(countries)) {
    data <- data[data$country %in% countries, , drop = FALSE]
  }

  out <- tibble::tibble(
    country = as.character(data$country),
    iso3 = as.character(data$iso3),
    who_region = as.character(data$who_region),
    year = as.integer(data$year),
    value = as.numeric(data[[info$column]])
  )

  base <- out[out$year == baseline_year, c("iso3", "value")]
  names(base)[2] <- "baseline_value"
  out <- dplyr::left_join(out, base, by = "iso3")

  valid <- !is.na(out$baseline_value) & out$baseline_value > 0 & !is.na(out$value)
  out$index <- ifelse(valid, 100 * out$value / out$baseline_value, NA_real_)
  out$pct_change <- out$index - 100
  out
}

#' Summarise progress towards the WHO End TB milestone path
#'
#' For each country, compares the reduction achieved between 2015 and an
#' assessment year with the reduction the WHO End TB Strategy requires by that
#' year (from [tb_required_reduction()]).
#'
#' Status is assigned as follows:
#' * **On track**: the reduction achieved is at least the required reduction.
#' * **Behind**: the burden has fallen, but by less than required.
#' * **Rising**: the burden is higher than in 2015.
#' * **No data**: the 2015 value (or the value in the assessment year) is
#'   missing, or the 2015 value is zero, so a reduction cannot be calculated.
#'
#' @inheritParams tb_index
#' @param assess_year The year to assess. `NULL` (default) uses the latest year
#'   in `data`.
#'
#' @return A tibble with one row per country and columns `country`, `iso3`,
#'   `who_region`, `population` (in the assessment year), `indicator`,
#'   `assess_year`, `baseline_value`, `current_value`, `reduction_pct`
#'   (positive = burden has fallen), `required_reduction_pct`, `gap_pp`
#'   (reduction achieved minus required, in percentage points; positive means
#'   ahead of the path) and `status` (an ordered factor).
#' @export
#' @examples
#' tb_progress_summary(indicator = "incidence", countries = c("Kenya", "India"))
#'
#' # How many countries were on track for deaths in 2023?
#' s <- tb_progress_summary(indicator = "mortality", assess_year = 2023)
#' table(s$status)
tb_progress_summary <- function(data = tbprogress::tb_burden,
                                indicator = c("incidence", "mortality"),
                                assess_year = NULL,
                                countries = NULL) {
  indicator <- match.arg(indicator)
  check_tb_data(data, c("population"))
  idx <- tb_index(data, indicator, tb_baseline_year, countries)
  if (nrow(idx) == 0) {
    stop("No rows left after selecting `countries`.", call. = FALSE)
  }

  if (is.null(assess_year)) {
    assess_year <- max(idx$year, na.rm = TRUE)
  }
  assess_year <- as.integer(assess_year)

  ctry <- unique(idx[, c("country", "iso3", "who_region")])
  base <- idx[idx$year == tb_baseline_year, c("iso3", "value")]
  names(base)[2] <- "baseline_value"
  cur <- idx[idx$year == assess_year, c("iso3", "value")]
  names(cur)[2] <- "current_value"
  pop <- data[data$year == assess_year, c("iso3", "population")]

  out <- dplyr::left_join(ctry, pop, by = "iso3")
  out <- dplyr::left_join(out, base, by = "iso3")
  out <- dplyr::left_join(out, cur, by = "iso3")

  out$indicator <- indicator
  out$assess_year <- assess_year
  valid <- !is.na(out$baseline_value) & out$baseline_value > 0 &
    !is.na(out$current_value)
  out$reduction_pct <- ifelse(
    valid, 100 * (1 - out$current_value / out$baseline_value), NA_real_
  )
  out$required_reduction_pct <- tb_required_reduction(assess_year, indicator)
  out$gap_pp <- out$reduction_pct - out$required_reduction_pct

  status <- ifelse(
    is.na(out$reduction_pct), "No data",
    ifelse(out$reduction_pct >= out$required_reduction_pct, "On track",
           ifelse(out$reduction_pct < 0, "Rising", "Behind"))
  )
  out$status <- factor(
    status, levels = c("On track", "Behind", "Rising", "No data")
  )

  out <- out[, c(
    "country", "iso3", "who_region", "population", "indicator", "assess_year",
    "baseline_value", "current_value", "reduction_pct",
    "required_reduction_pct", "gap_pp", "status"
  )]
  out <- out[order(out$country), ]
  tibble::as_tibble(out)
}
