test_that("plot_tb_trajectory returns a ggplot and handles odd input", {
  p <- plot_tb_trajectory(indicator = "incidence", countries = c("Kenya", "India"))
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot2::ggplot_build(p))

  p2 <- plot_tb_trajectory(indicator = "mortality", countries = "Kenya",
                           show_region = FALSE)
  expect_s3_class(p2, "ggplot")

  expect_error(plot_tb_trajectory(countries = character(0)), "at least one")
  expect_error(
    plot_tb_trajectory(indicator = "mortality",
                       countries = "Democratic People's Republic of Korea"),
    "usable 2015 baseline"
  )
})

test_that("plot_tb_peers returns a ggplot and respects the population filter", {
  p <- plot_tb_peers(indicator = "incidence", highlight = "Kenya")
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot2::ggplot_build(p))

  n_hidden <- nrow(plot_tb_peers(indicator = "incidence")$data)
  n_all <- nrow(plot_tb_peers(indicator = "incidence", min_population = 0)$data)
  expect_lt(n_hidden, n_all)

  # A highlighted tiny country is kept even when small countries are hidden
  p_tuv <- plot_tb_peers(indicator = "incidence", highlight = "Tuvalu")
  expect_true("Tuvalu" %in% p_tuv$data$country)
})

test_that("tb_status_table builds a DT widget", {
  s <- tb_progress_summary(indicator = "incidence", countries = c("Kenya", "India"))
  w <- tb_status_table(s)
  expect_s3_class(w, "datatables")
  expect_error(tb_status_table(data.frame(x = 1)), "missing required column")
})

test_that("tb_app_theme returns a bslib theme", {
  expect_s3_class(tb_app_theme(), "bs_theme")
})

test_that("the app is bundled and its server logic works", {
  app_dir <- system.file("app", package = "tbprogress")
  expect_true(nzchar(app_dir))
  expect_true(file.exists(file.path(app_dir, "app.R")))
  expect_true(file.exists(file.path(app_dir, "www", "styles.css")))

  skip_if_not_installed("shiny")
  shiny::testServer(app_dir, {
    session$setInputs(
      indicator = "incidence", countries = c("Kenya", "India"),
      year = 2023, show_region = TRUE, hide_small = TRUE
    )
    expect_equal(nrow(summ()), 2L)
    expect_equal(nrow(usable()), 2L)

    # No countries chosen -> a friendly validation message, not a crash
    session$setInputs(countries = NULL)
    expect_error(summ(), "Choose at least one country", class = "shiny.silent.error")

    # A country WHO has no mortality data for -> informative message
    session$setInputs(indicator = "mortality",
                      countries = "Democratic People's Republic of Korea")
    expect_error(usable(), "No estimate is available", class = "shiny.silent.error")
  })
})
