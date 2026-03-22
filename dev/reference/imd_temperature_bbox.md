# Download and process IMD temperature data for a bounding box

Download and process IMD temperature data for a bounding box

## Usage

``` r
IMDTemperatureBbox(...)

imd_temperature_bbox(
  request_id,
  start_year,
  end_year,
  north,
  south,
  east,
  west,
  var_type = "tmax",
  frequency = "daily",
  save_raw = FALSE,
  output_dir = tempdir(),
  use_cache = TRUE
)
```

## Arguments

- ...:

  Arguments passed to the main function (used by aliases).

- request_id:

  Unique identifier for the request.

- start_year:

  Start year (1951-2024).

- end_year:

  End year (1951-2024).

- north:

  Northern latitude boundary.

- south:

  Southern latitude boundary.

- east:

  Eastern longitude boundary.

- west:

  Western longitude boundary.

- var_type:

  Temperature type: "tmax" or "tmin".

- frequency:

  Temporal frequency (default: "daily").

- save_raw:

  Whether to save raw files (default: FALSE).

- output_dir:

  Directory to save files (default: tempdir()).

- use_cache:

  Whether to use cached data if available (default: TRUE).

## Value

data.frame with processed temperature data

## Examples

``` r
if (FALSE) { # \dontrun{
data <- imd_temperature_bbox(
  request_id = "delhi_tmax",
  start_year = 2023,
  end_year = 2024,
  north = 29, south = 28,
  east = 78, west = 76,
  var_type = "tmax"
)
} # }
```
