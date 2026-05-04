# Process multiple IMD files

Reads and combines multiple IMD data files.

## Usage

``` r
process_imd_files(file_paths, var_type, resolution = NULL, years = NULL)
```

## Arguments

- file_paths:

  Character vector of file paths.

- var_type:

  Variable type: "rain", "tmax", or "tmin".

- resolution:

  Resolution (for rainfall): 0.25 or 1.0.

- years:

  Integer vector. Years corresponding to each file.

## Value

data.frame with combined data

## Examples

``` r
if (FALSE) { # \dontrun{
files <- c("imd_tmax_1.0_2023.grd", "imd_tmax_1.0_2024.grd")
data <- process_imd_files(files, "tmax", years = c(2023, 2024))
} # }
```
