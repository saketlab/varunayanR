# Download IMD gridded temperature data

Downloads daily gridded temperature data (max or min) from IMD.
Temperature data is at 1.0 degree resolution only.

## Usage

``` r
download_imd_temperature(
  start_year,
  end_year,
  var_type = "tmax",
  output_dir = tempdir(),
  use_cache = TRUE
)
```

## Arguments

- start_year:

  Start year.

- end_year:

  End year.

- var_type:

  Type of temperature: "tmax" or "tmin".

- output_dir:

  Directory to save downloaded files.

- use_cache:

  Whether to use cached data if available (default: TRUE).

## Value

Character vector of downloaded file paths

## Examples

``` r
if (FALSE) { # \dontrun{
# Download max temperature for 2023-2025
files <- download_imd_temperature(
  start_year = 2023,
  end_year = 2025,
  var_type = "tmax"
)
} # }
```
