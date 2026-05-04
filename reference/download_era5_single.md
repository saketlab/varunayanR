# Download ERA5 single-level data using ecmwfr

Download ERA5 single-level data using ecmwfr

## Usage

``` r
download_era5_single(
  variables,
  start_date,
  end_date,
  area = NULL,
  resolution = 0.25,
  frequency = "hourly",
  output_file,
  timeout = 3600,
  retry_attempts = 5,
  use_cache = TRUE,
  verbose = FALSE
)
```

## Arguments

- variables:

  Character vector of variable names

- start_date:

  Date object or character string (YYYY-MM-DD)

- end_date:

  Date object or character string (YYYY-MM-DD)

- area:

  Numeric vector of 4 elements: c(north, west, south, east) in decimal
  degrees

- resolution:

  Numeric value for grid resolution (default: 0.25 degrees)

- frequency:

  Character string: "hourly", "daily", "monthly"

- output_file:

  Character string path for output NetCDF file

- timeout:

  Numeric value for request timeout in seconds (default: 3600)

- retry_attempts:

  Integer number of retry attempts (default: 5)

- use_cache:

  Use cached data if available (default: TRUE)

- verbose:

  Logical indicating whether to print progress messages

## Value

Character string path to downloaded file
