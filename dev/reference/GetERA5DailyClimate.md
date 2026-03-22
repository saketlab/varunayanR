# Download daily ERA5 climate data

Flexible function to download ERA5 climate variables for a region.
Supports temperature, humidity, wet bulb, wind, and solar radiation.

## Usage

``` r
GetERA5DailyClimate(
  request_id,
  start_date,
  end_date,
  variables = c("temperature", "humidity"),
  json_file = NULL,
  north = NULL,
  south = NULL,
  east = NULL,
  west = NULL,
  resolution = 0.25,
  use_cache = TRUE,
  verbose = FALSE
)

get_era5_daily_climate(
  request_id,
  start_date,
  end_date,
  variables = c("temperature", "humidity"),
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

- variables:

  Character vector of variables to download. Options: "temperature",
  "humidity", "wet_bulb", "wind", "solar"

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

data.frame with date, latitude, longitude, and requested variables

## Examples

``` r
if (FALSE) { # \dontrun{
# Get temperature and humidity
climate <- GetERA5DailyClimate(
  request_id = "india_climate",
  start_date = "2023-05-01",
  end_date = "2023-05-31",
  variables = c("temperature", "humidity"),
  json_file = "india.geojson"
)
} # }
```
