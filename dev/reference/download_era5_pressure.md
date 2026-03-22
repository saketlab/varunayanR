# Download ERA5 pressure-level data using ecmwfr

Download ERA5 pressure-level data using ecmwfr

## Usage

``` r
download_era5_pressure(
  variables,
  pressure_levels,
  start_date,
  end_date,
  area = NULL,
  resolution = 0.25,
  frequency = "hourly",
  output_file,
  use_cache = TRUE,
  verbose = FALSE
)
```

## Arguments

- variables:

  Character vector of variable names

- pressure_levels:

  Character vector of pressure levels (e.g., c("1000", "850", "500"))

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

- use_cache:

  Use cached data if available (default: TRUE)

- verbose:

  Logical indicating whether to print progress messages

## Value

Character string path to downloaded file
