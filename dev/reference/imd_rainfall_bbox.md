# IMD data download and processing for custom regions Download and process IMD rainfall data for a bounding box

Downloads IMD gridded rainfall data and filters it to a specified
bounding box.

## Usage

``` r
IMDRainfallBbox(...)

imd_rainfall_bbox(
  request_id,
  start_year,
  end_year,
  north,
  south,
  east,
  west,
  resolution = 0.25,
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

  Start year.

- end_year:

  End year.

- north:

  Northern latitude boundary.

- south:

  Southern latitude boundary.

- east:

  Eastern longitude boundary.

- west:

  Western longitude boundary.

- resolution:

  Spatial resolution: 0.25 or 1.0 degrees (default: 0.25).

- frequency:

  Temporal frequency: "daily", "monthly", "yearly" (default: "daily").

- save_raw:

  Whether to save raw downloaded files (default: FALSE).

- output_dir:

  Directory to save files (default: tempdir()).

- use_cache:

  Whether to use cached data if available (default: TRUE).

## Value

data.frame with processed rainfall data

## Examples

``` r
if (FALSE) { # \dontrun{
data <- imd_rainfall_bbox(
  request_id = "maharashtra_rain",
  start_year = 2023,
  end_year = 2024,
  north = 22, south = 16,
  east = 80, west = 73,
  resolution = 0.25,
  frequency = "monthly"
)
} # }
```
