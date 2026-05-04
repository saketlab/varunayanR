# Download HadEX3 climate extremes data for a bounding box

Downloads and filters HadEX3 ETCCDI climate extremes data to a
geographic bounding box. Data covers 1901-2018 at 1.25 x 1.875 degree
resolution.

## Usage

``` r
HadEX3Bbox(...)

hadex3_bbox(
  index,
  start_year,
  end_year,
  north,
  south,
  east,
  west,
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

- north:

  Northern latitude boundary.

- south:

  Southern latitude boundary.

- east:

  Eastern longitude boundary.

- west:

  Western longitude boundary.

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
# Annual maximum daily maximum temperature for Europe 1981-2010
data <- hadex3_bbox(
  index = "TXx",
  start_year = 1981, end_year = 2010,
  north = 71, south = 36, east = 40, west = -10
)

# Monthly Rx1day for India
data <- hadex3_bbox(
  index = "Rx1day",
  start_year = 2000, end_year = 2018,
  north = 35, south = 8, east = 97, west = 68,
  frequency = "monthly"
)
} # }
```
