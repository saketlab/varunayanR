# varunayanR

[![R-CMD-check](https://github.com/saketlab/varunayanR/workflows/R-CMD-check/badge.svg)](https://github.com/saketlab/varunayanR/actions)
[![CRAN
status](https://www.r-pkg.org/badges/version/varunayan)](https://CRAN.R-project.org/package=varunayan)
[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

varunayanR makes it effortless to download and process **ERA5**
reanalysis and **IMD** gridded climate data for any geographical region.
Get analysis-ready data frames with just a few lines of code.

## Quick Start

### Installation

``` r

# Install from GitHub
# install.packages("devtools")
devtools::install_github("saketlab/varunayanR")
```

### Basic Usage

``` r

library(varunayan)

# 1. Setup CDS credentials (ERA5 only, one-time)
setup_cds_credentials(key = "your-cds-api-key")
# Get your key from: https://cds.climate.copernicus.eu/api-how-to

# 2. Download ERA5 data for a bounding box
temperature_data <- era5ify_bbox(
  request_id = "mumbai_temp",
  variables = c("2m_temperature", "total_precipitation"),
  start_date = "2023-01-01",
  end_date = "2023-12-31",
  north = 19.2, south = 18.9,
  east = 72.9, west = 72.8,
  frequency = "daily"
)

# 3. Download IMD rainfall data
rainfall_data <- imd_rainfall_bbox(
  request_id = "maharashtra_rain",
  start_year = 2023,
  end_year = 2024,
  north = 22, south = 16,
  east = 80, west = 73,
  resolution = 0.25,
  frequency = "monthly"
)

# Data is ready to analyze!
head(temperature_data)
#>         date latitude longitude 2m_temperature total_precipitation
#> 1 2023-01-01   19.000    72.750         293.15                0.0
#> 2 2023-01-01   19.000    72.875         293.20                0.5
#> ...
```

### Download Data for Custom GeoJSON Region

``` r

# Use any GeoJSON file
data <- era5ify_geojson(
  request_id = "indian_states",
  variables = c("2m_temperature", "surface_pressure"),
  start_date = "2024-01-01",
  end_date = "2024-01-31",
  json_file = "path/to/states.geojson",
  frequency = "daily"
)
```

### Multi-Year IMD Analysis

``` r

# Download 20 years of rainfall data
rainfall <- imd_rainfall_bbox(
  request_id = "monsoon_study",
  start_year = 2000,
  end_year = 2020,
  north = 28, south = 8,
  east = 92, west = 68,
  resolution = 0.25,
  frequency = "monthly"
)

# Analyze monsoon patterns
library(dplyr)
monsoon <- rainfall %>%
  filter(month(date) %in% 6:9) %>%
  group_by(year(date), latitude, longitude) %>%
  summarise(monsoon_total = sum(rainfall))
```

### Pressure-level data

``` r

# Download ERA5 atmospheric data at multiple levels
atmos_data <- era5ify_bbox(
  request_id = "atmosphere",
  variables = c("temperature", "geopotential", "u_component_of_wind"),
  start_date = "2024-01-01",
  end_date = "2024-01-05",
  north = 30, south = 20,
  east = 80, west = 70,
  dataset_type = "pressure",
  pressure_levels = c("1000", "850", "500", "200")
)
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
For major changes, please open an issue first to discuss what you would
like to change.

## Citation

If you use varunayanR in your research, please cite:

``` bibtex
@software{varunayanr2024,
  author = {Jagtap, Atharva and Choudhary, Saket},
  title = {varunayanR: Analysis-ready Climate Data for Custom Regions},
  year = {2024},
  url = {https://github.com/saketlab/varunayanR},
  version = {0.1.0}
}
```

## License

MIT License - see
[LICENSE](https://saketlab.github.io/varunayanR/LICENSE) file for
details.

------------------------------------------------------------------------
