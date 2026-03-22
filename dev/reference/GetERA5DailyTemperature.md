# Download daily ERA5 temperature data

Download daily ERA5 temperature data

## Usage

``` r
GetERA5DailyTemperature(
  request_id,
  start_date,
  end_date,
  json_file = NULL,
  north = NULL,
  south = NULL,
  east = NULL,
  west = NULL,
  resolution = 0.25,
  use_cache = TRUE,
  verbose = FALSE
)

get_era5_daily_temperature(
  request_id,
  start_date,
  end_date,
  json_file = NULL,
  north = NULL,
  south = NULL,
  east = NULL,
  west = NULL,
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

  Path to GeoJSON file defining the region

- north, south, east, west:

  Bounding box coordinates (alternative to json_file)

- resolution:

  Spatial resolution in degrees (default: 0.25)

- use_cache:

  Whether to use cached data (default: TRUE)

- verbose:

  Whether to print progress messages (default: FALSE)

## Value

data.frame with date, latitude, longitude, temp_c

## Examples

``` r
if (FALSE) { # \dontrun{
temp <- GetERA5DailyTemperature(
  request_id = "india_temp",
  start_date = "2023-05-01",
  end_date = "2023-05-31",
  json_file = "india.geojson"
)
} # }
```
