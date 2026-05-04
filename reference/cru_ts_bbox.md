# Download CRU TS climate data for a bounding box

Downloads and filters CRU TS v4.07 monthly gridded climate data to a
geographic bounding box. Data covers global land areas at 0.5 degree
resolution, 1901-2022.

## Usage

``` r
CRUTSBbox(...)

cru_ts_bbox(
  variable,
  start_year,
  end_year,
  north,
  south,
  east,
  west,
  output_dir = tempdir(),
  use_cache = TRUE,
  ...
)
```

## Arguments

- ...:

  Arguments passed to the main function (used by aliases).

- variable:

  CRU TS variable code. See
  [`list_cru_ts_variables()`](https://saketlab.github.io/varunayanR/reference/list_cru_ts_variables.md).
  Common values: "tmp" (mean temperature), "pre" (precipitation), "tmx"
  (max temperature), "tmn" (min temperature).

- start_year:

  Start year (1901-2022).

- end_year:

  End year (1901-2022).

- north:

  Northern latitude boundary.

- south:

  Southern latitude boundary.

- east:

  Eastern longitude boundary.

- west:

  Western longitude boundary.

- output_dir:

  Directory for temporary files (default:
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html)).

- use_cache:

  Whether to use cached data (default: TRUE).

## Value

data.frame with columns: year, month, latitude, longitude, value,
variable.

## Examples

``` r
if (FALSE) { # \dontrun{
# Monthly mean temperature for India 2010-2020
data <- cru_ts_bbox(
  variable = "tmp",
  start_year = 2010, end_year = 2020,
  north = 35, south = 8, east = 97, west = 68
)

# Precipitation for Europe 1981-2010
data <- cru_ts_bbox(
  variable = "pre",
  start_year = 1981, end_year = 2010,
  north = 71, south = 36, east = 40, west = -10
)
} # }
```
