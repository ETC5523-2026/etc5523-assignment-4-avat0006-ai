# tbprogress: Tracking country progress towards the WHO End TB milestones

<!-- badges: start -->
[![pkgdown site](https://img.shields.io/badge/docs-pkgdown-0B5C6B)](https://etc5523-2026.github.io/etc5523-assignment-4-avat0006-ai/)
<!-- badges: end -->

**Documentation website: <https://etc5523-2026.github.io/etc5523-assignment-4-avat0006-ai/>**

## Purpose

`tbprogress` is an R package that bundles World Health Organization (WHO)
estimates of tuberculosis (TB) incidence and mortality for **215 countries and
territories, 2000-2023**, a few functions for analysing them, and a **Shiny
app** for exploring them.

The app is designed for **a public-health analyst or policy student** who wants
to answer one question:

> Is a country's TB burden falling fast enough to meet the WHO End TB
> milestones, and how does it compare with its region?

The WHO End TB Strategy asks countries to cut the TB incidence rate and the
number of TB deaths by set percentages compared with 2015 (for example, a 50%
cut in the incidence rate and a 75% cut in deaths by 2025). The app lets you
pick up to five countries, see their trajectories against the milestone path,
and check whether each is **on track**, **behind** or **rising**.

## Installation

Install the package from GitHub (you need the `remotes` package, available from
CRAN):

```r
# install.packages("remotes")
remotes::install_github("ETC5523-2026/etc5523-assignment-4-avat0006-ai")
```

The package needs R 4.1 or newer. Its dependencies (`shiny`, `bslib`, `DT`,
`dplyr`, `ggplot2`, `rlang`, `tibble`) are installed automatically.

## Launch the app

```r
library(tbprogress)
run_tb_app()
```

The app opens in your browser. It uses only the data inside the installed
package, so it needs no internet connection and no extra files. It has three
tabs:

- **Progress**: a headline count of countries on track, a trajectory chart for
  each selected country against the WHO milestone path, and a status table.
- **Peers**: where each country sits among all countries in its WHO region.
- **Guide**: what each control does, how to read each output, and the caveats.

See the [Getting started
vignette](https://etc5523-2026.github.io/etc5523-assignment-4-avat0006-ai/articles/getting-started.html)
for a guided walk-through.

## Using the functions without the app

```r
library(tbprogress)

# Which countries are on track for the WHO deaths milestone in 2023?
s <- tb_progress_summary(indicator = "mortality", assess_year = 2023)
table(s$status)

# Plot three countries against the milestone path
plot_tb_trajectory(indicator = "incidence",
                   countries = c("Kenya", "India", "Brazil"))
```

| Function | What it does |
|:---------|:-------------|
| `run_tb_app()` | Launches the Shiny app. |
| `tb_progress_summary()` | Per-country reduction since 2015 versus the reduction WHO requires, with a status. |
| `tb_index()` | Rescales a country's burden so 2015 = 100. |
| `tb_required_reduction()` | The reduction the WHO milestone path requires in any year. |
| `plot_tb_trajectory()`, `plot_tb_peers()` | The two charts used in the app. |
| `tb_status_table()`, `tb_app_theme()` | The table and theme used in the app. |

## The data

Two datasets are included (see `?tb_burden` and `?tb_targets` for every
variable):

- `tb_burden`: 5,117 rows (one per country-year) and 18 variables, including
  `incidence_rate` (new cases per 100,000 people), `mortality_n` (estimated TB
  deaths), `population` and `who_region`.
- `tb_targets`: the WHO End TB milestones (percentage reductions required
  compared with 2015).

### Source, licence and attribution

- **Source:** World Health Organization (WHO), global tuberculosis programme
  data (<https://www.who.int/teams/global-tuberculosis-programme/data>). The
  same WHO estimates are published on the [WHO data
  portal](https://data.who.int/indicators/i/13B4226/C288D13). The CSV used here
  was obtained from the [TidyTuesday 2025-11-11
  release](https://github.com/rfordatascience/tidytuesday/tree/main/data/2025/2025-11-11),
  curated by Darakhshan Nehal from the
  [getTBinR](https://github.com/seabbs/getTBinR) package by Sam Abbott.
- **Milestones:** WHO (2015), *The End TB Strategy*, Geneva: World Health
  Organization.
- **Data licence:** WHO publishes its data on data.who.int under the [Creative
  Commons Attribution 4.0 International licence (CC BY
  4.0)](https://creativecommons.org/licenses/by/4.0) with [additional WHO
  terms](https://data.who.int/about/data/terms-and-conditions). This package
  complies with those terms:
  - WHO is credited as the source (citation below).
  - The meaning of the data is not altered. Changes made: columns were renamed,
    a subset of variables was kept, and `who_region` was made a factor. No data
    values were changed (see `data-raw/tb_burden.R`).
  - **This package, its app and its analyses are not endorsed by or affiliated
    with WHO.** The WHO name and emblem are not used as branding.
  - WHO's separate data policy also limits use to public-health,
    non-commercial purposes, so the data are used here for educational
    purposes only.
- **Suggested citation:** World Health Organization 2026 data.who.int,
  Tuberculosis incidence (per 100 000 population) \[Indicator\].
  <https://data.who.int/indicators/i/13B4226/C288D13> (Accessed on 31 October
  2026, via the TidyTuesday copy described above).
- **Package licence:** the **code** is released under the MIT licence (see
  `LICENSE`). That licence does not extend to the WHO data.

These are modelled estimates. The WHO uncertainty intervals are not part of the
dataset used here, so small differences should be interpreted with caution.

### Reproducing the data

The scripts in `data-raw/` rebuild the package data from the raw CSV
(`data-raw/who_tb_data.csv`), downloading it first if it is missing:

```r
source("data-raw/tb_burden.R")   # builds data/tb_burden.rda
source("data-raw/tb_targets.R")  # builds data/tb_targets.rda
```

## Author

Amisha Vatsa, Monash University, ETC5523 Communicating with Data.

## Generative AI declaration

**Generative AI declaration:** Claude (Anthropic) was used as a learning and editing reference to help clarify concepts, address specific technical questions, and refine draft phrasing. I critically evaluated all AI suggestions, wrote and tested the code, and finalized all text myself. I am fully responsible for the submitted work.
