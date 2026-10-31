# TB Progress Tracker ---------------------------------------------------------
#
# Intended user:  a public-health analyst or policy student who needs to judge
#                 how a country's tuberculosis (TB) burden is trending.
# Question:       Is this country's TB burden falling fast enough to meet the
#                 WHO End TB milestones, and how does it compare with its
#                 WHO region and with other countries?
#
# Data: bundled in the installed package (tbprogress::tb_burden). The app does
# not read any CSV or other external file when it runs.
# -----------------------------------------------------------------------------

library(shiny)
library(bslib)

tb <- tbprogress::tb_burden

latest_year <- max(tb$year)
max_countries <- 5L
default_countries <- c("Kenya", "South Africa", "India", "Brazil")

# Countries grouped by WHO region, for the searchable drop-down
country_choices <- lapply(
  split(tb$country[!duplicated(tb$iso3)], as.character(tb$who_region[!duplicated(tb$iso3)])),
  sort
)
default_countries <- intersect(default_countries, unlist(country_choices))

indicator_phrase <- c(
  incidence = "the TB incidence rate",
  mortality = "the number of TB deaths"
)

# Small helper: one coloured count in the headline strip --------------------------
stat_box <- function(label, value, class) {
  div(
    class = paste("stat", class),
    div(class = "stat-value", value),
    div(class = "stat-label", label)
  )
}

# ---- UI ----------------------------------------------------------------------
ui <- page_navbar(
  title = "TB Progress Tracker",
  id = "main_nav",
  window_title = "TB Progress Tracker",
  theme = tbprogress::tb_app_theme(),
  bg = "#0B3C49",
  inverse = TRUE,
  fillable = FALSE,
  header = tagList(
    tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")),
    div(
      class = "question-banner",
      div(
        class = "banner-inner",
        span(class = "banner-label", "For"),
        "public-health analysts and policy students.",
        span(class = "banner-label banner-gap", "Question"),
        "Is a country's TB burden falling fast enough to meet the WHO End TB",
        "milestones, and how does it compare with its region?"
      )
    )
  ),
  sidebar = sidebar(
    width = 330,
    title = "Choose what to explore",

    radioButtons(
      "indicator", "1. Indicator",
      choiceNames = list(
        "Incidence rate (new cases per 100,000 people)",
        "TB deaths (number per year)"
      ),
      choiceValues = c("incidence", "mortality"),
      selected = "incidence"
    ),

    selectizeInput(
      "countries", paste0("2. Countries (up to ", max_countries, ")"),
      choices = country_choices,
      selected = default_countries,
      multiple = TRUE,
      options = list(
        maxItems = max_countries,
        placeholder = "Type to search for a country"
      )
    ),

    sliderInput(
      "year", "3. Assess progress in year",
      min = 2016, max = latest_year, value = latest_year, step = 1, sep = ""
    ),

    checkboxInput(
      "show_region", "4. Compare with the WHO region median", value = TRUE
    ),

    conditionalPanel(
      "input.main_nav == 'Peers'",
      checkboxInput(
        "hide_small", "5. Hide countries under 1 million people", value = TRUE
      )
    ),

    div(
      class = "sidebar-hint",
      "Not sure what a control does? Open the ", tags$strong("Guide"), " tab."
    )
  ),

  # ---- Tab 1: Progress ---------------------------------------------------------
  nav_panel(
    "Progress",
    uiOutput("headline"),
    card(
      class = "tb-card",
      card_header("Trajectory against the WHO End TB milestone path"),
      plotOutput("trajectory", height = "auto"),
      div(
        class = "how-to-read",
        tags$strong("How to read this: "),
        "each panel rescales a country so that 2015 = 100. A line that falls",
        "below the dashed orange path is ahead of the WHO milestones; a line",
        "above it is behind. The dotted grey line is the typical country in the",
        "same WHO region."
      )
    ),
    card(
      class = "tb-card",
      card_header(textOutput("table_title", inline = TRUE)),
      DT::DTOutput("status_table"),
      div(
        class = "how-to-read",
        tags$strong("How to read this: "),
        "the gap is the reduction achieved minus the reduction needed, in",
        "percentage points. A positive gap means the country is ahead of the",
        "milestone path."
      ),
      uiOutput("excluded_note")
    )
  ),

  # ---- Tab 2: Peers ------------------------------------------------------------
  nav_panel(
    "Peers",
    card(
      class = "tb-card",
      card_header("How does each country compare with its peers?"),
      plotOutput("peers", height = "560px"),
      div(
        class = "how-to-read",
        tags$strong("How to read this: "),
        "every dot is one country, grouped by WHO region. Dots to the right of",
        "the dashed orange line have achieved the reduction the milestone path",
        "requires by the chosen year. Your selected countries are labelled in",
        "blue, so you can see whether a country is unusual for its region or",
        "typical of it."
      )
    )
  ),

  # ---- Tab 3: Guide ------------------------------------------------------------
  nav_panel(
    "Guide",
    layout_columns(
      col_widths = c(6, 6),
      card(
        class = "tb-card",
        card_header("What this app is for"),
        p(
          "The WHO End TB Strategy asks every country to cut TB incidence and",
          "TB deaths sharply compared with 2015. This app helps you judge",
          "whether a country is on that path, and whether its progress is",
          "unusual compared with its region."
        ),
        tags$ul(
          tags$li(tags$strong("Intended user: "),
                  "a public-health analyst or policy student comparing countries."),
          tags$li(tags$strong("Question: "),
                  "is this country's TB burden falling fast enough to meet the",
                  "WHO End TB milestones, and how does it compare with its",
                  "region?")
        ),
        p(
          "WHO milestones (compared with 2015): incidence rate down 20% by",
          "2020, 50% by 2025, 80% by 2030; TB deaths down 35%, 75% and 90% in",
          "the same years. Between milestone years the app draws a straight",
          "line, so it can say what was 'needed' in any year."
        )
      ),
      card(
        class = "tb-card",
        card_header("The controls"),
        tags$dl(
          tags$dt("1. Indicator"),
          tags$dd(
            "Which burden to track. ", tags$em("Incidence rate"), " is new TB",
            "cases per 100,000 people (a rate, so countries of different size",
            "are comparable). ", tags$em("TB deaths"), " is the estimated",
            "number of deaths per year, which is how WHO defines its deaths",
            "target."
          ),
          tags$dt("2. Countries"),
          tags$dd(
            "Pick up to five countries to analyse. Type to search; countries",
            "are grouped by WHO region."
          ),
          tags$dt("3. Assess progress in year"),
          tags$dd(
            "The year to judge. The status table and peer chart compare that",
            "year with 2015, and with the reduction WHO's milestone path",
            "requires by then. Move it back to see whether a country was ever",
            "on track."
          ),
          tags$dt("4. Compare with the WHO region median"),
          tags$dd(
            "Adds a dotted grey line: the median index of all countries in the",
            "same WHO region. Each country counts equally, whatever its size."
          ),
          tags$dt("5. Hide countries under 1 million people (Peers tab)"),
          tags$dd(
            "Rates and counts in tiny populations swing wildly (a few cases can",
            "move a percentage by hundreds of points). Leave this on to keep",
            "the peer chart readable; your selected countries always stay."
          )
        )
      )
    ),
    layout_columns(
      col_widths = c(6, 6),
      card(
        class = "tb-card",
        card_header("Reading the outputs"),
        tags$dl(
          tags$dt("Headline strip"),
          tags$dd(
            "Counts how many of your selected countries are On track, Behind or",
            "Rising in the chosen year, and who has the largest reduction."
          ),
          tags$dt("Trajectory chart"),
          tags$dd(
            "Shows the whole 2000-2023 story for each country, indexed so that",
            "2015 = 100. Compare the solid blue line with the dashed orange",
            "path: being below the path means ahead of the milestones. The",
            "path continues to 2030 so you can see how far there is to go."
          ),
          tags$dt("Status table"),
          tags$dd(
            tags$strong("2015 value / year value"), ": the indicator in 2015 and",
            "in the chosen year. ", tags$strong("Reduction since 2015"),
            ": how much it has fallen (negative = it has risen). ",
            tags$strong("Needed"), ": the reduction the WHO path requires by",
            "that year. ", tags$strong("Gap"), ": reduction minus needed (positive",
            "= ahead). ", tags$strong("Status"), ": On track (reduction at least",
            "what is needed), Behind (falling, but too slowly), Rising (higher",
            "than 2015) or No data."
          ),
          tags$dt("Peer chart"),
          tags$dd(
            "Places every country on the same scale, so you can tell whether a",
            "country's progress is typical of its region or an outlier."
          )
        )
      ),
      card(
        class = "tb-card",
        card_header("Caveats and data source"),
        tags$ul(
          tags$li(
            "These are modelled WHO ", tags$em("estimates"), ". The uncertainty",
            "intervals are not in this dataset, so treat small gaps (a few",
            "percentage points) as 'about on the path', not as a verdict."
          ),
          tags$li(
            "Reductions use 2015 as the baseline. If a country's 2015 value is",
            "zero or missing, a reduction cannot be calculated and it shows as",
            "No data."
          ),
          tags$li(
            "The region median is unweighted: a small country counts as much",
            "as a large one."
          ),
          tags$li(
            "WHO sets milestones only for 2020, 2025, 2030 and 2035; values in",
            "between are interpolated by this app."
          ),
          tags$li(
            tags$strong("Source: "), "World Health Organization (WHO), global",
            "tuberculosis programme data, accessed via the TidyTuesday release",
            "of 2025-11-11 (curated from the getTBinR package by Sam Abbott).",
            "WHO publishes these data under the Creative Commons Attribution",
            "4.0 licence (CC BY 4.0) with additional WHO terms. Column names",
            "were changed for readability; no values were altered. This app",
            "is not endorsed by or affiliated with WHO, and it is for",
            "educational use."
          )
        )
      )
    )
  )
)

# ---- Server ------------------------------------------------------------------
server <- function(input, output, session) {

  # Friendly message shown by every output until at least one country is chosen
  need_countries <- function() {
    validate(
      need(
        length(input$countries) > 0,
        "Choose at least one country in the sidebar to see how it is doing."
      )
    )
  }

  # One row per selected country: reduction since 2015, needed, status, ...
  summ <- reactive({
    need_countries()
    tbprogress::tb_progress_summary(
      tb,
      indicator = input$indicator,
      assess_year = input$year,
      countries = input$countries
    )
  })

  # Selected countries that actually have data (a 2015 baseline and a value now)
  usable <- reactive({
    s <- summ()
    ok <- s[s$status != "No data", ]
    validate(
      need(
        nrow(ok) > 0,
        paste0(
          "No estimate is available for ",
          paste(s$country, collapse = ", "),
          " with this indicator and year: WHO has no 2015 baseline or no ",
          "value for ", input$year, " (or the 2015 value is zero, so a ",
          "percentage change cannot be calculated). Try another country, ",
          "indicator or year."
        )
      )
    )
    ok[match(intersect(input$countries, ok$country), ok$country), ]
  })

  # Headline strip ----------------------------------------------------------------
  output$headline <- renderUI({
    # If there is nothing to summarise, stay quiet here: the explanatory
    # message is shown once, in the chart card below, not repeated.
    ok <- tryCatch(usable(), shiny.silent.error = function(e) NULL)
    if (is.null(ok)) return(NULL)
    n_on <- sum(ok$status == "On track")
    n_behind <- sum(ok$status == "Behind")
    n_rising <- sum(ok$status == "Rising")
    needed <- round(ok$required_reduction_pct[1])
    best <- ok[which.max(ok$reduction_pct), ]

    div(
      class = "headline",
      div(
        class = "stat-strip",
        stat_box("On track", n_on, "stat-ok"),
        stat_box("Behind", n_behind, "stat-behind"),
        stat_box("Rising", n_rising, "stat-rising")
      ),
      # Built as one HTML string: separate tag children are rendered on separate
      # lines, which a browser shows as stray spaces before punctuation.
      p(
        class = "headline-text",
        HTML(paste0(
          "By ", input$year, ", WHO's milestone path needs ",
          indicator_phrase[[input$indicator]], " to be down <strong>",
          needed, "%</strong> from 2015. Of the ", nrow(ok),
          " selected ", if (nrow(ok) == 1) "country" else "countries",
          " with data, <strong>", n_on, "</strong> ",
          if (n_on == 1) "is" else "are", " on track. ",
          if (best$reduction_pct > 0) {
            paste0(
              "Largest reduction: <strong>", htmltools::htmlEscape(best$country),
              "</strong> (", sprintf("%.1f%%", best$reduction_pct), ")."
            )
          } else {
            paste0(
              "None of the selected countries has a lower burden than in ",
              "2015 (closest: <strong>", htmltools::htmlEscape(best$country),
              "</strong>, ", sprintf("%+.1f%%", -best$reduction_pct),
              " compared with 2015)."
            )
          }
        ))
      )
    )
  })

  # Trajectory plot ---------------------------------------------------------------
  output$trajectory <- renderPlot(
    {
      ok <- usable()
      tbprogress::plot_tb_trajectory(
        tb,
        indicator = input$indicator,
        countries = ok$country,
        show_region = input$show_region
      )
    },
    height = function() {
      n <- length(input$countries)
      rows <- if (n <= 2) 1 else ceiling(n / 2)
      170 + 250 * rows
    },
    res = 100
  )

  # Status table ------------------------------------------------------------------
  output$table_title <- renderText({
    paste0("Where each country stands in ", input$year)
  })

  output$status_table <- DT::renderDT({
    s <- summ()
    tbprogress::tb_status_table(s)
  })

  # Note listing any selected country that was left out of the charts
  output$excluded_note <- renderUI({
    s <- summ()
    missing <- s$country[s$status == "No data"]
    if (length(missing) == 0) return(NULL)
    div(
      class = "weak-note",
      HTML(paste0(
        "<strong>Not charted:</strong> ",
        htmltools::htmlEscape(paste(missing, collapse = ", ")),
        ". WHO has no 2015 baseline or no ", input$year,
        " estimate for this indicator (or the 2015 value is zero), so a",
        " reduction cannot be calculated."
      ))
    )
  })

  # Peers plot ----------------------------------------------------------------------
  output$peers <- renderPlot(
    {
      need_countries()
      tbprogress::plot_tb_peers(
        tb,
        indicator = input$indicator,
        assess_year = input$year,
        highlight = input$countries,
        min_population = if (isTRUE(input$hide_small)) 1e6 else 0
      )
    },
    res = 100
  )
}

shinyApp(ui, server)
