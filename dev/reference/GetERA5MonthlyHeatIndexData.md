# Get monthly ERA5 heat stress index data

Wrapper for GetERA5DailyHeatIndexData that takes year and month
parameters and returns monthly aggregated heat stress indices.

## Usage

``` r
GetERA5MonthlyHeatIndexData(
  request_id,
  year,
  month,
  json_file = NULL,
  north = NULL,
  south = NULL,
  east = NULL,
  west = NULL,
  solar_load = FALSE,
  resolution = 0.25,
  use_cache = TRUE,
  verbose = FALSE
)

get_era5_monthly_heat_index_data(
  request_id,
  year,
  month,
  json_file = NULL,
  north = NULL,
  south = NULL,
  east = NULL,
  west = NULL,
  solar_load = FALSE,
  resolution = 0.25,
  use_cache = TRUE,
  verbose = FALSE
)

GetERA5MonthlyHeatData(
  request_id,
  year,
  month,
  json_file = NULL,
  north = NULL,
  south = NULL,
  east = NULL,
  west = NULL,
  solar_load = FALSE,
  resolution = 0.25,
  use_cache = TRUE,
  verbose = FALSE
)

get_era5_monthly_heat_data(
  request_id,
  year,
  month,
  json_file = NULL,
  north = NULL,
  south = NULL,
  east = NULL,
  west = NULL,
  solar_load = FALSE,
  resolution = 0.25,
  use_cache = TRUE,
  verbose = FALSE
)
```

## Arguments

- request_id:

  Unique identifier for the data request

- year:

  Year (e.g., 2023)

- month:

  Month (1-12)

- json_file:

  Path to GeoJSON file defining the region

- north, south, east, west:

  Bounding box coordinates (alternative to json_file)

- solar_load:

  Whether to include solar radiation (default: FALSE)

- resolution:

  Spatial resolution in degrees (default: 0.25)

- use_cache:

  Whether to use cached data (default: TRUE)

- verbose:

  Whether to print progress messages (default: FALSE)

## Value

data.frame with monthly mean values for each grid point

## Examples

``` r
if (FALSE) { # \dontrun{
heat_may <- GetERA5MonthlyHeatIndexData(
  request_id = "india_may2023",
  year = 2023,
  month = 5,
  json_file = "india.geojson"
)
} # }
```
