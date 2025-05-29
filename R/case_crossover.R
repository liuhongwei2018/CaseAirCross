#' Case-Crossover Analysis
#'
#' Time-stratified case-crossover analysis with exposure lag effects
#' @param data Input dataset containing case identifiers, dates and exposures
#' @param case_date Column name for case occurrence dates
#' @param exp_vars Exposure variables to analyze
#' @param time_stratify Temporal stratification ("week", "month", or custom function)
#' @param lag Exposure lag days (0 for same-day)
#' @param parallel Enable parallel processing
#' @return List containing model objects and diagnostics
#' @importFrom survival clogit
#' @importFrom lme4 glmer
#' @export
case_crossover <- function(data, case_date = "date", exp_vars = "PM2.5",
                           time_stratify = "week", lag = 0:3, parallel = TRUE) {

  # Generate control dates
  generate_controls <- function(dates, lag) {
    tibble::tibble(
      case_date = rep(dates, each = length(lag)),
      control_date = rep(dates, each = length(lag)) - lag,
      lag_days = rep(lag, times = length(dates))
    ) %>%
      dplyr::filter(control_date >= min(dates) - max(lag))
  }

  # Parallel setup
  if (parallel) {
    if (!requireNamespace("future", quietly = TRUE)) {
      stop("future package required for parallel processing")
    }
    future::plan(future::multisession)
  }

  # Build case-control dataset
  case_control_data <- furrr::future_map_dfr(
    unique(data$case_id),
    function(id) {
      case_data <- dplyr::filter(data, case_id == id)
      controls <- generate_controls(case_data[[case_date]], lag) %>%
        dplyr::left_join(data, by = setNames(case_date, "control_date"))

      dplyr::bind_rows(
        case_data %>% dplyr::mutate(period = "case", lag_days = NA_real_),
        controls %>% dplyr::mutate(period = "control")
      )
    }
  )

  # Temporal stratification
  if (is.function(time_stratify)) {
    case_control_data$stratum <- time_stratify(case_control_data$case_date)
  } else {
    case_control_data <- case_control_data %>%
      dplyr::mutate(
        stratum = dplyr::case_when(
          time_stratify == "week" ~ format(case_date, "%Y-W%W"),
          time_stratify == "month" ~ format(case_date, "%Y-%m")
        )
      )
  }

  # Conditional logistic regression
  model_formula <- stats::reformulate(
    termlabels = exp_vars,
    response = "period",
    intercept = FALSE
  )

  # Fit primary model
  model <- survival::clogit(
    model_formula,
    data = case_control_data,
    strata = stratum
  )

  # Return comprehensive results
  list(
    model = model,
    diagnostics = list(
      lag_distribution = table(case_control_data$lag_days),
      temporal_strata = length(unique(case_control_data$stratum))
    ),
    dataset = case_control_data
  )
}
