# Read IMD NetCDF rainfall file

Reads IMD NetCDF rainfall data and converts to data.frame.

## Usage

``` r
read_imd_rainfall(file_path, resolution, year)
```

## Arguments

- file_path:

  Path to IMD NetCDF file (.nc).

- resolution:

  Spatial resolution: 0.25 or 1.0.

- year:

  Year of the data.

## Value

data.frame with columns: date, latitude, longitude, rainfall

## Examples

``` r
if (FALSE) { # \dontrun{
rain_data <- read_imd_rainfall("imd_rainfall_0.25_2023.nc", 0.25, 2023)
} # }
```
