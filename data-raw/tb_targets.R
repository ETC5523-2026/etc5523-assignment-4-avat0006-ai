# data-raw/tb_targets.R ------------------------------------------------------
# Reproducibly builds `tb_targets`: the WHO End TB Strategy milestones and
# targets, expressed as the percentage reduction required relative to 2015.
#
# Source: WHO (2015), "The End TB Strategy", Geneva: World Health Organization,
# targets table (milestones for 2020 and 2025; SDG target for 2030; End TB
# target for 2035). Values transcribed here and checked against the document.
# Run from the package root:  source("data-raw/tb_targets.R")
# --------------------------------------------------------------------------

library(tibble)
library(usethis)

tb_targets <- tribble(
  ~indicator,  ~year, ~reduction_pct, ~type,
  "incidence", 2015L,  0,             "baseline",
  "incidence", 2020L, 20,             "milestone",
  "incidence", 2025L, 50,             "milestone",
  "incidence", 2030L, 80,             "SDG target",
  "incidence", 2035L, 90,             "End TB target",
  "mortality", 2015L,  0,             "baseline",
  "mortality", 2020L, 35,             "milestone",
  "mortality", 2025L, 75,             "milestone",
  "mortality", 2030L, 90,             "SDG target",
  "mortality", 2035L, 95,             "End TB target"
)

stopifnot(
  !anyDuplicated(tb_targets[c("indicator", "year")]),
  all(diff(tb_targets$reduction_pct[tb_targets$indicator == "incidence"]) > 0),
  all(diff(tb_targets$reduction_pct[tb_targets$indicator == "mortality"]) > 0)
)

use_data(tb_targets, overwrite = TRUE, compress = "xz")
