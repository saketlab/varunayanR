# Download daily ERA5 wind data

Downloads 10m wind components and calculates wind speed.

## Usage

``` r
GetERA5DailyWind(
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

get_era5_daily_wind(
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

data.frame with date, latitude, longitude, wind_speed

## Examples

``` r
if (FALSE) { # \dontrun{
wind <- GetERA5DailyWind(
  request_id = "india_wind",
  start_date = "2023-05-01",
  end_date = "2023-05-31",
  json_file = "india.geojson"
)
} # }
```
