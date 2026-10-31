#' Colours used across the package (colour-blind-safe Okabe-Ito palette)
#' @noRd
tb_colours <- list(
  country = "#0072B2",
  region = "#6B7280",
  path = "#D55E00",
  highlight = "#0072B2",
  muted = "#B8BEC6",
  ink = "#1B2A32"
)

#' A clean ggplot2 theme shared by the package's plots
#' @noRd
theme_tb <- function(base_size = 13) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      text = ggplot2::element_text(colour = tb_colours$ink),
      plot.title = ggplot2::element_text(face = "bold", size = base_size + 3),
      plot.subtitle = ggplot2::element_text(colour = "#4B5963"),
      plot.caption = ggplot2::element_text(colour = "#6B7280", size = base_size - 3,
                                           hjust = 0),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = "#E5E7EB"),
      strip.text = ggplot2::element_text(face = "bold", hjust = 0, size = base_size),
      legend.position = "bottom",
      legend.title = ggplot2::element_blank(),
      legend.key.width = ggplot2::unit(1.8, "lines"),
      plot.margin = ggplot2::margin(10, 14, 10, 10)
    )
}

#' Plot countries' TB burden against the WHO End TB milestone path
#'
#' One small panel per country. Each panel shows the chosen indicator indexed
#' to 2015 (= 100), optionally the median index for the country's WHO region,
#' and the path the WHO End TB milestones require (dashed). A country whose
#' line is **below** the dashed path is ahead of the milestones.
#'
#' @inheritParams tb_index
#' @param countries Character vector of country names to plot (required). Names
#'   must match `data$country`; countries with no usable 2015 baseline are
#'   dropped.
#' @param show_region Logical. Add the median index of all countries in the
#'   same WHO region (each country counts equally, regardless of population)?
#'
#' @return A [ggplot2::ggplot()] object.
#' @export
#' @examples
#' plot_tb_trajectory(indicator = "incidence",
#'                    countries = c("Kenya", "India", "Brazil"))
plot_tb_trajectory <- function(data = tbprogress::tb_burden,
                               indicator = c("incidence", "mortality"),
                               countries,
                               show_region = TRUE) {
  indicator <- match.arg(indicator)
  info <- tb_indicator_info(indicator)
  if (missing(countries) || length(countries) == 0) {
    stop("`countries` must name at least one country.", call. = FALSE)
  }

  idx_all <- tb_index(data, indicator, tb_baseline_year)
  idx_all <- idx_all[!is.na(idx_all$index), ]
  idx <- idx_all[idx_all$country %in% countries, ]
  if (nrow(idx) == 0) {
    stop(
      "None of the selected countries has a usable 2015 baseline for this indicator.",
      call. = FALSE
    )
  }
  levels_country <- intersect(countries, unique(idx$country))
  idx$country <- factor(idx$country, levels = levels_country)

  series_levels <- c("Country", "WHO region median", "WHO End TB milestone path")

  parts <- list(data.frame(
    country = idx$country, year = idx$year, index = idx$index,
    series = "Country", stringsAsFactors = FALSE
  ))

  if (isTRUE(show_region)) {
    reg <- stats::aggregate(index ~ who_region + year, data = idx_all,
                            FUN = stats::median)
    ctry_reg <- unique(data.frame(
      country = as.character(idx$country), who_region = idx$who_region,
      stringsAsFactors = FALSE
    ))
    reg_df <- merge(ctry_reg, reg, by = "who_region")
    parts[[length(parts) + 1]] <- data.frame(
      country = reg_df$country, year = reg_df$year, index = reg_df$index,
      series = "WHO region median", stringsAsFactors = FALSE
    )
  }

  path_years <- seq(tb_baseline_year, 2030L)
  path <- expand.grid(
    country = levels_country, year = path_years, stringsAsFactors = FALSE
  )
  path$index <- 100 - tb_required_reduction(path$year, indicator)
  path$series <- "WHO End TB milestone path"
  parts[[length(parts) + 1]] <- path

  plot_df <- do.call(rbind, parts)
  plot_df$country <- factor(plot_df$country, levels = levels_country)
  plot_df$series <- factor(plot_df$series, levels = series_levels)

  milestones <- path[path$year %in% c(2020L, 2025L, 2030L), ]

  cols <- c(tb_colours$country, tb_colours$region, tb_colours$path)
  names(cols) <- series_levels
  ltys <- c("solid", "dotted", "dashed")
  names(ltys) <- series_levels
  lwds <- c(1.3, 1, 1)
  names(lwds) <- series_levels

  ggplot2::ggplot(
    plot_df,
    ggplot2::aes(
      x = .data$year, y = .data$index,
      colour = .data$series, linetype = .data$series, linewidth = .data$series
    )
  ) +
    ggplot2::geom_hline(yintercept = 100, colour = "#D1D5DB", linewidth = 0.4) +
    ggplot2::geom_line() +
    ggplot2::geom_point(
      data = milestones, ggplot2::aes(x = .data$year, y = .data$index),
      inherit.aes = FALSE, colour = tb_colours$path, size = 2
    ) +
    ggplot2::scale_colour_manual(values = cols, name = NULL) +
    ggplot2::scale_linetype_manual(values = ltys, name = NULL) +
    ggplot2::scale_linewidth_manual(values = lwds, name = NULL) +
    ggplot2::scale_x_continuous(breaks = seq(2000, 2030, 5), limits = c(2000, 2030)) +
    ggplot2::expand_limits(y = 0) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$country),
      scales = "free_y", ncol = min(2L, length(levels_country))
    ) +
    ggplot2::labs(
      title = paste0(info$label, " relative to 2015"),
      subtitle = "Below the dashed orange path = ahead of the WHO End TB milestones",
      x = NULL,
      y = "Index (2015 = 100)",
      caption = paste0(
        "Source: WHO global TB burden estimates (via TidyTuesday 2025-11-11). ",
        "Dots mark the 2020, 2025 and 2030 milestones;\n",
        "the path is interpolated linearly between WHO milestone years. ",
        "Each panel has its own y-axis."
      )
    ) +
    theme_tb()
}

#' Compare countries' reduction since 2015 across WHO regions
#'
#' A strip plot with one dot per country, grouped by WHO region. The horizontal
#' position is the percentage reduction since 2015 in the assessment year
#' (right = burden has fallen; left = burden has risen). The dashed vertical
#' line is the reduction the WHO End TB milestone path requires by that year,
#' so every dot to its right is on track. Highlighted countries are labelled.
#'
#' @inheritParams tb_progress_summary
#' @param highlight Optional character vector of country names to label.
#' @param min_population Countries with fewer than this many people in the
#'   assessment year are left out. Percentage changes in very small
#'   populations are volatile (a handful of cases can swing the rate), so the
#'   default (`1e6`) hides them; use `0` to keep every country.
#' @param axis_limits Numeric length-2 vector: the range of the horizontal axis
#'   in percent. Countries outside this range are not drawn; the number hidden
#'   is reported in the plot caption.
#'
#' @return A [ggplot2::ggplot()] object.
#' @export
#' @examples
#' plot_tb_peers(indicator = "incidence", highlight = c("Kenya", "India"))
plot_tb_peers <- function(data = tbprogress::tb_burden,
                          indicator = c("incidence", "mortality"),
                          assess_year = NULL,
                          highlight = NULL,
                          min_population = 1e6,
                          axis_limits = c(-100, 100)) {
  indicator <- match.arg(indicator)
  info <- tb_indicator_info(indicator)
  s <- tb_progress_summary(data, indicator, assess_year)
  ay <- s$assess_year[1]
  required <- s$required_reduction_pct[1]

  s <- s[!is.na(s$reduction_pct), ]
  keep_pop <- is.na(s$population) | s$population >= min_population
  # Always keep highlighted countries, even if small, so they are never silently lost.
  s <- s[keep_pop | s$country %in% highlight, ]
  if (nrow(s) == 0) {
    stop("No countries have enough data to plot for this selection.", call. = FALSE)
  }

  s$region <- factor(as.character(s$who_region))
  s$y <- as.numeric(s$region)
  # Deterministic jitter (no random numbers, so the plot never changes between runs)
  rank_id <- match(s$iso3, sort(unique(s$iso3)))
  s$y <- s$y + ((rank_id * 0.61803398875) %% 1 - 0.5) * 0.7

  s$off_scale <- s$reduction_pct < axis_limits[1] | s$reduction_pct > axis_limits[2]
  n_off <- sum(s$off_scale)
  s$highlighted <- s$country %in% highlight

  ggplot2::ggplot(s, ggplot2::aes(x = .data$reduction_pct, y = .data$y)) +
    ggplot2::geom_vline(xintercept = 0, colour = "#D1D5DB") +
    ggplot2::geom_vline(
      xintercept = required, colour = tb_colours$path,
      linetype = "dashed", linewidth = 0.9
    ) +
    ggplot2::geom_point(
      data = s[!s$highlighted, ],
      colour = tb_colours$muted, alpha = 0.75, size = 2.2
    ) +
    ggplot2::geom_point(
      data = s[s$highlighted, ],
      colour = tb_colours$highlight, size = 3.8, shape = 21,
      fill = tb_colours$highlight, stroke = 1.2
    ) +
    ggplot2::geom_text(
      data = s[s$highlighted, ],
      ggplot2::aes(label = .data$country),
      colour = tb_colours$highlight, fontface = "bold",
      vjust = -1, size = 3.8, check_overlap = TRUE
    ) +
    ggplot2::annotate(
      "text", x = required, y = max(s$y) + 0.75,
      label = paste0("Needed by ", ay, ": ", round(required), "%"),
      colour = tb_colours$path, hjust = -0.05, size = 3.8, fontface = "bold"
    ) +
    ggplot2::scale_y_continuous(
      breaks = seq_along(levels(s$region)), labels = levels(s$region),
      expand = ggplot2::expansion(add = c(0.5, 1))
    ) +
    ggplot2::scale_x_continuous(labels = function(x) paste0(x, "%")) +
    ggplot2::coord_cartesian(xlim = axis_limits) +
    ggplot2::labs(
      title = paste0("Reduction in ", info$phrase, ", 2015 to ", ay),
      subtitle = paste0(
        "Each dot is a country. Right of the dashed line = on track; ",
        "left of 0% = burden has risen."
      ),
      x = paste0("Change since 2015 (positive = reduction)"),
      y = NULL,
      caption = paste0(
        "Source: WHO global TB burden estimates (via TidyTuesday 2025-11-11). ",
        if (min_population > 0) {
          paste0("Countries under ", format(min_population, big.mark = ",", scientific = FALSE),
                 " people are hidden unless highlighted.")
        } else {
          "All countries shown."
        },
        if (n_off > 0) {
          paste0(
            "\n", n_off, if (n_off == 1) " country falls" else " countries fall",
            " outside the axis range and ",
            if (n_off == 1) "is" else "are", " not drawn."
          )
        } else {
          ""
        }
      )
    ) +
    theme_tb() +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_line(colour = "#EEF0F2"))
}
