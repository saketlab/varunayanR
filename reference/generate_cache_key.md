# Generate cache key for download parameters

Generate cache key for download parameters

## Usage

``` r
generate_cache_key(
  source,
  variables = NULL,
  start_date,
  end_date,
  area = NULL,
  resolution = NULL,
  dataset_type = NULL,
  var_type = NULL,
  pressure_levels = NULL
)
```

## Arguments

- source:

  Data source: "era5" or "imd"

- variables:

  Variable names

- start_date:

  Start date

- end_date:

  End date

- area:

  Bounding box for ERA5

- resolution:

  Spatial resolution

- dataset_type:

  For ERA5: "single" or "pressure"

- var_type:

  For IMD: "tmax", "tmin", or "rainfall"

- pressure_levels:

  Pressure levels for ERA5 pressure data

## Value

Character string with cache key
