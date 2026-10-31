# A small, fully controlled dataset so every status can be checked by hand
toy <- function() {
  mk <- function(country, iso3, v2015, v2023, pop = 5e6) {
    rows <- data.frame(
      country = country, iso3 = iso3, who_region = "Africa",
      year = c(2015L, 2023L), population = pop,
      incidence_rate = c(v2015, v2023), mortality_n = c(v2015, v2023),
      stringsAsFactors = FALSE
    )
    rows
  }
  rbind(
    mk("A", "AAA", 100, 50),   # 50% reduction; needed by 2023 = 38  -> On track
    mk("B", "BBB", 100, 80),   # 20% reduction                       -> Behind
    mk("C", "CCC", 100, 120),  # -20%                                -> Rising
    mk("D", "DDD", 0, 5),      # zero baseline                       -> No data
    mk("E", "EEE", 100, NA)    # missing current value               -> No data
  )
}

test_that("tb_required_reduction interpolates between milestone years", {
  expect_equal(tb_required_reduction(c(2015, 2020, 2025, 2030), "incidence"),
               c(0, 20, 50, 80))
  expect_equal(tb_required_reduction(2023, "incidence"), 38)      # 20 + 3/5 * 30
  expect_equal(tb_required_reduction(2023, "mortality"), 59)      # 35 + 3/5 * 40
  expect_equal(tb_required_reduction(2010, "incidence"), 0)       # before baseline
  expect_equal(tb_required_reduction(2050, "mortality"), 95)      # after last target
})

test_that("tb_required_reduction rejects bad input", {
  expect_error(tb_required_reduction("2023"), "numeric")
  expect_error(tb_required_reduction(2023, "cases"), "arg")
})

test_that("tb_index sets the baseline to 100 and handles zero or missing baselines", {
  idx <- tb_index(toy(), "incidence")
  base <- idx[idx$year == 2015L & idx$country == "A", ]
  expect_equal(base$index, 100)
  expect_equal(idx$index[idx$year == 2023L & idx$country == "A"], 50)
  expect_equal(idx$pct_change[idx$year == 2023L & idx$country == "C"], 20)
  expect_true(is.na(idx$index[idx$country == "D"][1]))           # zero baseline
  expect_true(is.na(idx$index[idx$year == 2023L & idx$country == "E"]))
})

test_that("tb_index filters by country and validates the data", {
  idx <- tb_index(toy(), "incidence", countries = c("A", "B"))
  expect_setequal(idx$country, c("A", "B"))
  expect_error(tb_index(data.frame(x = 1)), "missing required column")
  expect_error(tb_index("not a data frame"), "data frame")
})

test_that("tb_progress_summary assigns the right status to each case", {
  s <- tb_progress_summary(toy(), "incidence", assess_year = 2023)
  st <- stats::setNames(as.character(s$status), s$country)
  expect_equal(st[["A"]], "On track")
  expect_equal(st[["B"]], "Behind")
  expect_equal(st[["C"]], "Rising")
  expect_equal(st[["D"]], "No data")
  expect_equal(st[["E"]], "No data")
  expect_equal(s$reduction_pct[s$country == "A"], 50)
  expect_equal(s$gap_pp[s$country == "A"], 50 - 38)
  expect_equal(unique(s$required_reduction_pct), 38)
  expect_s3_class(s$status, "factor")
  expect_equal(levels(s$status), c("On track", "Behind", "Rising", "No data"))
})

test_that("tb_progress_summary defaults to the latest year and errors clearly", {
  s <- tb_progress_summary(toy(), "incidence")
  expect_equal(unique(s$assess_year), 2023L)
  expect_error(
    tb_progress_summary(toy(), "incidence", countries = "Nowhere"),
    "No rows left"
  )
})

test_that("real data: every country gets exactly one status", {
  s <- tb_progress_summary(indicator = "mortality", assess_year = 2023)
  expect_equal(nrow(s), 215L)
  expect_false(anyNA(s$status))
  # North Korea has no mortality estimates at all
  prk <- s[s$country == "Democratic People's Republic of Korea", ]
  expect_equal(as.character(prk$status), "No data")
})
