# Download ERA5 data and calculate heat stress indices

Download ERA5 temperature, dewpoint, and wind data for a region and
calculate heat stress indices.

## Usage

``` r
GetERA5DailyHeatIndexData(
  request_id,
  start_date,
  end_date,
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

get_era5_daily_heat_index_data(
  request_id,
  start_date,
  end_date,
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

GetERA5DailyHeatData(
  request_id,
  start_date,
  end_date,
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

get_era5_daily_heat_data(
  request_id,
  start_date,
  end_date,
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

- start_date:

  Start date in "YYYY-MM-DD" format

- end_date:

  End date in "YYYY-MM-DD" format

- json_file:

  Path to GeoJSON file defining the region (for geojson method)

- north:

  Northern latitude boundary (for bbox method)

- south:

  Southern latitude boundary (for bbox method)

- east:

  Eastern longitude boundary (for bbox method)

- west:

  Western longitude boundary (for bbox method)

- solar_load:

  Whether to include solar radiation in calculations (default: FALSE).
  When TRUE, downloads solar radiation data and uses it for WBGT and
  UTCI.

- resolution:

  Spatial resolution in degrees (default: 0.25)

- use_cache:

  Whether to use cached data if available (default: TRUE)

- verbose:

  Whether to print progress messages (default: FALSE)

## Value

data.frame with columns: date, latitude, longitude, temp_c, dewpoint_c,
wind_speed, rh, wet_bulb, heat_index, wbgt, utci, humidex, wbgt_risk,
heat_index_risk, utci_stress. When solar_load=TRUE, also includes
solar_radiation.

## Examples

``` r
if (FALSE) { # \dontrun{
heat_data <- GetERA5DailyHeatIndexData(
  request_id = "india_heat_2023",
  start_date = "2023-05-01",
  end_date = "2023-05-31",
  json_file = "india.geojson"
)

# With solar radiation for outdoor WBGT
heat_data <- GetERA5DailyHeatIndexData(
  request_id = "india_heat_2023_solar",
  start_date = "2023-05-01",
  end_date = "2023-05-31",
  json_file = "india.geojson",
  solar_load = TRUE
)
} # }
```
