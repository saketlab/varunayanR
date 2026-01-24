# Cache management for downloaded NetCDF files

Functions to cache ERA5 and IMD NetCDF files for faster successive
queries Get cache directory path

## Usage

``` r
GetCacheDir(...)

get_cache_dir(create = TRUE)
```

## Arguments

- create:

  Create directory if it doesn't exist (default: TRUE)

## Value

Character string with cache directory path
