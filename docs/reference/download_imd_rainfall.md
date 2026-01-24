# IMD data download functions

Functions for downloading gridded data from India Meteorological
Department (IMD) Based on analysis of actual IMD data format. Download
IMD gridded rainfall data

## Usage

``` r
download_imd_rainfall(
  start_year,
  end_year,
  resolution = 0.25,
  output_dir = tempdir(),
  use_cache = TRUE
)
```

## Arguments

- start_year:

  Start year.

- end_year:

  End year.

- resolution:

  Spatial resolution: 0.25 or 1.0 degrees.

- output_dir:

  Directory to save downloaded files.

## Value

Character vector of downloaded file paths

## Details

Downloads daily gridded rainfall data from IMD at specified resolution.

## Examples

``` r
if (FALSE) { # \dontrun{
# Download 0.25 degree rainfall for 2023-2025
files <- download_imd_rainfall(
  start_year = 2023,
  end_year = 2025,
  resolution = 0.25
)
} # }
```
