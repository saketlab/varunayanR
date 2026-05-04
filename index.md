# varunayanR

[![R-CMD-check](https://github.com/saketlab/varunayanR/workflows/R-CMD-check/badge.svg)](https://github.com/saketlab/varunayanR/actions)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**varunayanR** is an R package for downloading and processing **ERA5
reanalysis** data from [Copernicus Climate Data
Store](https://cds.climate.copernicus.eu/) and **IMD gridded climate
data** from the [Indian Meteorological
Department](https://www.imdpune.gov.in/). It provides an easy to use R
interface for extracting temperature, precipitation, and other climate
variables for any region using bounding boxes, GeoJSON polygons, or
point coordinates.

## Installation

``` r
# Install from GitHub
# install.packages("devtools")
devtools::install_github("saketlab/varunayanR")
```

## Quick Start

### ERA5 climate data

``` r
library(varunayan)

# Setup CDS credentials (one-time)
# Get your API key from: https://cds.climate.copernicus.eu/how-to-api
setup_cds_credentials(key = "your-cds-api-key")

# Download ERA5 temperature and precipitation for Mumbai
temperature_data <- era5ify_bbox(
  request_id = "mumbai_temp",
  variables = c("2m_temperature", "total_precipitation"),
  start_date = "2023-01-01",
  end_date = "2023-12-31",
  north = 19.2, south = 18.9,
  east = 72.9, west = 72.8,
  frequency = "daily"
)

head(temperature_data)
```

### IMD rainfall data

``` r
# Download IMD gridded rainfall data for Maharashtra
rainfall_data <- imd_rainfall_bbox(
  request_id = "maharashtra_rain",
  start_year = 2023,
  end_year = 2024,
  north = 22, south = 16,
  east = 80, west = 73,
  resolution = 0.25,
  frequency = "monthly"
)
```

### GeoJSON regions

``` r
# Download data for regions defined by GeoJSON
data <- era5ify_geojson(
  request_id = "indian_states",
  variables = c("2m_temperature", "surface_pressure"),
  start_date = "2024-01-01",
  end_date = "2024-01-31",
  json_file = "path/to/states.geojson",
  frequency = "daily"
)
```

## Use cases

### Monsoon analysis

``` r
# Download 20 years of rainfall data for monsoon research
rainfall <- imd_rainfall_bbox(
  request_id = "monsoon_study",
  start_year = 2000,
  end_year = 2020,
  north = 28, south = 8,
  east = 92, west = 68,
  resolution = 0.25,
  frequency = "monthly"
)

# Analyze monsoon patterns (June-September)
library(dplyr)
monsoon <- rainfall %>%
  filter(month(date) %in% 6:9) %>%
  group_by(year(date), latitude, longitude) %>%
  summarise(monsoon_total = sum(rainfall))
```

### Atmospheric data at pressure levels

``` r
# Download ERA5 data at multiple atmospheric levels
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

## Documentation

- [Quickstart
  Guide](https://saketlab.github.io/varunayanR/articles/quickstart.html)
- [Visualising data
  grids](https://saketlab.github.io/varunayanR/articles/spatial-aggregation.html)
- [ERA5 vs IMD
  Comparison](https://saketlab.github.io/varunayanR/articles/era5-vs-imd-comparison.html)
- [Function
  Reference](https://saketlab.github.io/varunayanR/reference/index.html)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see
[LICENSE](https://saketlab.github.io/varunayanR/LICENSE) file for
details.
