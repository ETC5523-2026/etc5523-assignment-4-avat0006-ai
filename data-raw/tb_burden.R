# data-raw/tb_burden.R -------------------------------------------------------
# Reproducibly prepares the `tb_burden` dataset shipped in the package.
#
# Source:  WHO global tuberculosis burden estimates, accessed through the
#          TidyTuesday release of 2025-11-11 (which curated a subset of the
#          WHO data via the getTBinR package by Sam Abbott).
# Licence: WHO publishes its data under CC BY 4.0 with additional WHO terms
#          (https://data.who.int/about/data/terms-and-conditions). Credit WHO,
#          do not imply WHO endorsement, and state changes made (renaming only).
# Run from the package root:  source("data-raw/tb_burden.R")
#
# What this script does
#   1. Downloads the raw CSV (only if it is not already in data-raw/).
#   2. Fixes known quirks: Namibia's ISO-2 code is stored as "'NA'" (quoted so
#      it is not read as missing); ids and years are given explicit types.
#   3. Renames the cryptic WHO field names (e_inc_100k, g_whoregion, ...) to
#      readable snake_case names.
#   4. Runs integrity checks, then saves data/tb_burden.rda.
# --------------------------------------------------------------------------

library(readr)
library(dplyr)
library(usethis)

raw_url <- paste0(
  "https://raw.githubusercontent.com/rfordatascience/tidytuesday/main/",
  "data/2025/2025-11-11/who_tb_data.csv"
)
raw_path <- file.path("data-raw", "who_tb_data.csv")

# 1. Import ------------------------------------------------------------------
if (!file.exists(raw_path)) {
  message("Downloading raw WHO TB data from TidyTuesday ...")
  download.file(raw_url, destfile = raw_path, mode = "wb")
}

tb_raw <- read_csv(
  raw_path,
  col_types = cols(
    country = col_character(),
    g_whoregion = col_character(),
    iso_numeric = col_integer(),
    iso2 = col_character(),
    iso3 = col_character(),
    year = col_integer(),
    .default = col_double()
  )
)

# 2 & 3. Clean and rename -------------------------------------------------------
tb_burden <- tb_raw |>
  transmute(
    country,
    iso3,
    iso2 = gsub("'", "", iso2, fixed = TRUE), # "'NA'" -> "NA" (Namibia)
    iso_numeric,
    who_region = factor(g_whoregion),
    year,
    population = e_pop_num,
    incidence_rate = e_inc_100k,
    incidence_n = e_inc_num,
    mortality_rate = e_mort_100k,
    mortality_n = e_mort_num,
    mortality_rate_hiv_neg = e_mort_exc_tbhiv_100k,
    mortality_n_hiv_neg = e_mort_exc_tbhiv_num,
    mortality_rate_hiv_pos = e_mort_tbhiv_100k,
    mortality_n_hiv_pos = e_mort_tbhiv_num,
    case_detection_rate = c_cdr,
    notification_rate = c_newinc_100k,
    case_fatality_ratio = cfr
  ) |>
  arrange(country, year)

tb_burden <- tibble::as_tibble(tb_burden)

# 4. Integrity checks ---------------------------------------------------------
stopifnot(
  !anyDuplicated(tb_burden[c("iso3", "year")]),  # one row per country-year
  !anyNA(tb_burden$country),
  !anyNA(tb_burden$year),
  all(tb_burden$year >= 2000L & tb_burden$year <= 2023L),
  all(tb_burden$incidence_rate >= 0, na.rm = TRUE),
  all(tb_burden$mortality_rate >= 0, na.rm = TRUE),
  all(tb_burden$population > 0)
)

use_data(tb_burden, overwrite = TRUE, compress = "xz")
