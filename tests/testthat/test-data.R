test_that("tb_burden has the documented shape and no duplicated country-years", {
  expect_s3_class(tb_burden, "tbl_df")
  expect_equal(dim(tb_burden), c(5117L, 18L))
  expect_equal(length(unique(tb_burden$iso3)), 215L)
  expect_false(anyDuplicated(tb_burden[c("iso3", "year")]) > 0)
  expect_equal(range(tb_burden$year), c(2000L, 2023L))
  expect_s3_class(tb_burden$who_region, "factor")
  expect_equal(nlevels(tb_burden$who_region), 6L)
})

test_that("Namibia's ISO-2 code is the text 'NA', not a missing value", {
  nam <- tb_burden$iso2[tb_burden$country == "Namibia"]
  expect_true(all(nam == "NA"))
  expect_false(anyNA(tb_burden$iso2))
})

test_that("tb_burden values are plausible", {
  expect_true(all(tb_burden$incidence_rate >= 0, na.rm = TRUE))
  expect_true(all(tb_burden$mortality_n >= 0, na.rm = TRUE))
  expect_true(all(tb_burden$population > 0))
})

test_that("tb_targets holds the WHO End TB milestones", {
  expect_equal(nrow(tb_targets), 10L)
  inc <- tb_targets[tb_targets$indicator == "incidence", ]
  mort <- tb_targets[tb_targets$indicator == "mortality", ]
  expect_equal(inc$reduction_pct, c(0, 20, 50, 80, 90))
  expect_equal(mort$reduction_pct, c(0, 35, 75, 90, 95))
  expect_equal(inc$year, c(2015L, 2020L, 2025L, 2030L, 2035L))
})
