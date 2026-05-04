# IMD data processing functions Read IMD binary temperature file

Reads IMD binary temperature data (max or min) and converts to
data.frame.

## Usage

``` r
read_imd_temperature(file_path, var_type, year)
```

## Arguments

- file_path:

  Path to IMD binary file (.grd).

- var_type:

  Variable type: "tmax" or "tmin".

- year:

  Year of the data.

## Value

data.frame with columns: date, latitude, longitude, temperature

## Examples

``` r
if (FALSE) { # \dontrun{
tmax_data <- read_imd_temperature("imd_tmax_1.0_2023.grd", "tmax", 2023)
} # }
```
