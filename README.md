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

library(CaseAirCross)

# Load PM2.5 NetCDF
pm_data <- load_pollution("data/CHAP_PM2.5_20200101.nc")

# Prepare case data
cases <- data.frame(
  id = 1:5,
  date = as.POSIXct(rep("2020-01-01", 5)),
  lon = runif(5, min(pm_data$lon), max(pm_data$lon)),
  lat = runif(5, min(pm_data$lat), max(pm_data$lat))
)

# Match exposure
matched <- geo_match(cases, pm_data)

# Run case-crossover
results <- case_crossover(data = matched, exp_vars = "exposure", lag = 0:3)
summary(results$model)


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
