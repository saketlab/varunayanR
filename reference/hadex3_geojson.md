# Download HadEX3 climate extremes data for a GeoJSON region

Downloads and filters HadEX3 ETCCDI climate extremes data to a
geographic region defined by a GeoJSON polygon.

## Usage

``` r
HadEX3Geojson(...)

hadex3_geojson(
  index,
  start_year,
  end_year,
  geojson_file,
  frequency = "annual",
  baseline = "61-90",
  output_dir = tempdir(),
  use_cache = TRUE
)
```

## Arguments

- ...:

  Arguments passed to the main function (used by aliases).

- index:

  ETCCDI index name (e.g. "TXx", "Rx1day"). See
  [`list_hadex3_indices()`](https://saketlab.github.io/varunayanR/reference/list_hadex3_indices.md).

- start_year:

  Start year (1901-2018).

- end_year:

  End year (1901-2018).

- geojson_file:

  Path to a GeoJSON file defining the region.

- frequency:

  Temporal frequency: "annual" or "monthly" (default: "annual").

- baseline:

  Reference period for percentile-based indices: "61-90" (default) or
  "81-10". Only applies to annual frequency.

- output_dir:

  Directory for temporary files (default:
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html)).

- use_cache:

  Whether to use cached data (default: TRUE).

## Value

data.frame with columns: year (+ month for monthly), latitude,
longitude, value, index.

## Examples

``` r
if (FALSE) { # \dontrun{
data <- hadex3_geojson(
  index = "TXx",
  start_year = 1981, end_year = 2010,
  geojson_file = "india.geojson"
)
} # }
```
