# Download CRU TS climate data for a GeoJSON region

Downloads and filters CRU TS v4.07 monthly gridded climate data to a
geographic region defined by a GeoJSON polygon.

## Usage

``` r
CRUTSGeojson(...)

cru_ts_geojson(
  variable,
  start_year,
  end_year,
  geojson_file,
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

- start_year:

  Start year (1901-2022).

- end_year:

  End year (1901-2022).

- geojson_file:

  Path to a GeoJSON file defining the region.

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
data <- cru_ts_geojson(
  variable = "tmp",
  start_year = 1981, end_year = 2010,
  geojson_file = "india.geojson"
)
} # }
```
