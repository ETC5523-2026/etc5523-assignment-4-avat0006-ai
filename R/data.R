#' WHO tuberculosis burden estimates by country and year
#'
#' Modelled estimates of tuberculosis (TB) incidence, mortality and related
#' indicators for 215 countries and territories, 2000-2023. This is the data
#' behind the \pkg{tbprogress} app and functions; see `data-raw/tb_burden.R`
#' for the script that prepares it from the raw file.
#'
#' All rates are *estimates* produced by the World Health Organization (WHO)
#' using notification data, surveys and modelling. The subset used here does
#' not include WHO's uncertainty intervals, so small differences between
#' countries or years should not be over-interpreted. A few countries have
#' missing values (for example, `mortality_rate` is missing for every year for
#' the Democratic People's Republic of Korea), and a few territories have a
#' rate of exactly zero in some years.
#'
#' @format A tibble with 5,117 rows (one per country-year) and 18 variables:
#' \describe{
#'   \item{country}{Country or territory name.}
#'   \item{iso3}{ISO 3-letter country code. Unique identifier for a country.}
#'   \item{iso2}{ISO 2-letter country code. Namibia's code is the text "NA",
#'     not a missing value.}
#'   \item{iso_numeric}{ISO numeric country code.}
#'   \item{who_region}{WHO region (factor with 6 levels: Africa, Americas,
#'     Eastern Mediterranean, Europe, South-East Asia, Western Pacific).}
#'   \item{year}{Year of the estimate (integer, 2000 to 2023).}
#'   \item{population}{Estimated total population.}
#'   \item{incidence_rate}{Estimated TB incidence (all forms): new and relapse
#'     cases per 100,000 people per year.}
#'   \item{incidence_n}{Estimated number of incident TB cases (all forms).}
#'   \item{mortality_rate}{Estimated TB mortality (all forms, including deaths
#'     among people living with HIV): deaths per 100,000 people per year.}
#'   \item{mortality_n}{Estimated number of TB deaths (all forms, including
#'     deaths among people living with HIV). The End TB Strategy deaths target
#'     is defined on this number, so [tb_progress_summary()] uses it for the
#'     `"mortality"` indicator.}
#'   \item{mortality_rate_hiv_neg}{Estimated TB mortality among HIV-negative
#'     people, per 100,000 population.}
#'   \item{mortality_n_hiv_neg}{Estimated number of TB deaths among
#'     HIV-negative people.}
#'   \item{mortality_rate_hiv_pos}{Estimated TB mortality among HIV-positive
#'     people, per 100,000 population.}
#'   \item{mortality_n_hiv_pos}{Estimated number of TB deaths among
#'     HIV-positive people.}
#'   \item{case_detection_rate}{Case detection rate, also called TB treatment
#'     coverage: percent of estimated incident cases that were notified.}
#'   \item{notification_rate}{Case notification rate (new, relapse and
#'     unknown-history cases) per 100,000 population.}
#'   \item{case_fatality_ratio}{Estimated TB case fatality ratio (deaths
#'     divided by incident cases).}
#' }
#'
#' @source World Health Organization (WHO), global tuberculosis programme data
#'   (<https://www.who.int/teams/global-tuberculosis-programme/data>), accessed
#'   via the TidyTuesday release of 2025-11-11
#'   (<https://github.com/rfordatascience/tidytuesday/tree/main/data/2025/2025-11-11>,
#'   curated by Darakhshan Nehal from the 'getTBinR' package by Sam Abbott,
#'   <https://github.com/seabbs/getTBinR>). The same WHO estimates are published
#'   on the WHO data portal, for example "Tuberculosis incidence (per 100 000
#'   population)" (<https://data.who.int/indicators/i/13B4226/C288D13>).
#'
#'   **Licence and attribution.** WHO publishes its datasets on data.who.int
#'   under the Creative Commons Attribution 4.0 International licence (CC BY
#'   4.0, <https://creativecommons.org/licenses/by/4.0>) together with
#'   additional WHO terms
#'   (<https://data.who.int/about/data/terms-and-conditions>). This package
#'   follows them: WHO is credited as the source (see the citation below); the
#'   data are not altered in meaning; this package, its outputs and its analyses
#'   are **not endorsed by WHO**; and the WHO name and emblem are not used as
#'   branding. WHO's separate data policy also limits use to public-health,
#'   non-commercial purposes, so the data are used here for educational
#'   purposes only. The package licence (MIT) covers the code only.
#'
#'   **Changes made.** Columns were renamed and re-ordered, a subset of
#'   variables was kept, and `who_region` was converted to a factor. No data
#'   values were changed. See `data-raw/tb_burden.R`.
#'
#'   **Suggested citation.** World Health Organization 2026 data.who.int,
#'   Tuberculosis incidence (per 100 000 population) \[Indicator\].
#'   <https://data.who.int/indicators/i/13B4226/C288D13> (Accessed on 31
#'   October 2026, via the TidyTuesday copy described above).
"tb_burden"

#' WHO End TB Strategy milestones and targets
#'
#' The percentage reductions in TB incidence rate and TB deaths, relative to
#' 2015, that the WHO End TB Strategy sets for 2020, 2025, 2030 and 2035.
#' [tb_required_reduction()] interpolates between these points. See
#' `data-raw/tb_targets.R` for how the table is built.
#'
#' @format A tibble with 10 rows and 4 variables:
#' \describe{
#'   \item{indicator}{Either `"incidence"` (TB incidence *rate*, as in
#'     `tb_burden$incidence_rate`) or `"mortality"` (the *number* of TB deaths,
#'     as in `tb_burden$mortality_n`).}
#'   \item{year}{Milestone or target year (2015, 2020, 2025, 2030, 2035).}
#'   \item{reduction_pct}{Required percentage reduction compared with 2015.
#'     Zero in the baseline year.}
#'   \item{type}{One of `"baseline"`, `"milestone"`, `"SDG target"`,
#'     `"End TB target"`.}
#' }
#'
#' @source World Health Organization (2015). *The End TB Strategy*. Geneva:
#'   WHO. Milestones are reductions in the TB incidence rate and in the
#'   absolute number of TB deaths, each compared with 2015.
#' @examples
#' tb_targets
"tb_targets"
