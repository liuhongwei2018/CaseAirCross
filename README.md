# CaseAirCross 🌍⚕️

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**CaseAirCross** is an R package for analyzing short-term health effects of air pollution using case-crossover design. It provides streamlined workflows for spatial exposure assessment and statistical modeling with NetCDF pollution data.

## Installation

Install the latest development version from GitHub:
```r
if (!require("devtools")) install.packages("devtools")
devtools::install_github("liuhongwei2018/CaseAirCross")
```

## Quick Start

### 1. Load Sample Data
```r
library(CaseAirCross)

# Load built-in sample cases
data(sample_cases)
head(sample_cases)  # ID, date, lon, lat columns
```

### 2. Process Pollution Data
```r
# Load PM2.5 NetCDF data (replace with your file path)
pm_data <- load_pollution("path/to/PM2_5_data.nc")

# Match case locations to pollution grid
matched_data <- geo_match(cases = sample_cases, pollution = pm_data)
```

### 3. Run Case-Crossover Analysis
```r
# Fit conditional logistic regression with 0-3 day lags
model <- run_crossover(
  data = matched_data,
  exposure_var = "exposure",
  lags = 0:3
)

# View results
summary(model)
tidy_results <- broom::tidy(model, conf.int = TRUE)
```

## Key Features
- **NetCDF Integration**: Native support for climate/air quality model outputs
- **Spatial Matching**: Bilinear interpolation for precise exposure assignment
- **Temporal Analysis**: Distributed lag models (DLM) for delayed effects
- **Visualization**: Exposure-response curves (development phase)
- **Reproducibility**: Automated report generation with [rmarkdown]

## Contributing

We welcome contributions!  
🔧 Submit issues for bug reports or feature requests  
💻 Fork the repository and create pull requests  
📧 Contact maintainer: [Hongwei Liu](mailto:liuhongwei@zzu.edu.cn)

## License
Distributed under MIT License. See [LICENSE](LICENSE) for details.
