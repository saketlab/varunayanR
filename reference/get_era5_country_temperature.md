# Get ERA5 country-level temperature data

Download and aggregate ERA5 temperature data for a country. Resolves the
country boundary, downloads monthly data via
[`era5ify_geojson()`](https://saketlab.github.io/varunayanR/reference/era5ify_geojson.md),
and returns area-weighted (cosine-latitude) country-level averages by
year and month.

## Usage

``` r
GetERA5CountryTemperature(...)

get_era5_country_temperature(
  country,
  start_date,
  end_date,
  variables = "mean",
  request_id = NULL,
  resolution = 0.25,
  verbose = FALSE,
  ...
)
```

## Arguments

- ...:

  Additional arguments passed to
  [`era5ify_geojson()`](https://saketlab.github.io/varunayanR/reference/era5ify_geojson.md).

- country:

  One of: a country name string (resolved via
  [`maps::map()`](https://rdrr.io/pkg/maps/man/map.html)), a path to a
  GeoJSON file, or an `sf` object. Common aliases like `"USA"` and
  `"UK"` are handled automatically.

- start_date:

  Start date in `"YYYY-MM-DD"` format.

- end_date:

  End date in `"YYYY-MM-DD"` format.

- variables:

  Character vector of temperature shorthand names or ERA5 variable
  names. Shorthands: `"mean"` (2m_temperature), `"max"`
  (maximum_2m_temperature_since_previous_post_processing), `"min"`
  (minimum_2m_temperature_since_previous_post_processing). Default:
  `"mean"`.

- request_id:

  Optional request identifier. Auto-generated from the country name if
  not provided.

- resolution:

  Spatial resolution in degrees (default: 0.25).

- verbose:

  Whether to print detailed progress messages.

## Value

A data.frame with columns `year`, `month`, and one column per requested
variable (e.g., `temperature_mean`, `temperature_max`,
`temperature_min`). Temperature values are in Celsius.

## Examples

``` r
if (FALSE) { # \dontrun{
# Monthly mean temperature for India
get_era5_country_temperature("India", "2023-06-01", "2023-06-30")

# Mean and max temperature for USA
get_era5_country_temperature("USA", "2023-01-01", "2023-12-31",
  variables = c("mean", "max")
)

# Using an sf object directly
library(sf)
poly <- st_read("my_country.geojson")
get_era5_country_temperature(poly, "2023-01-01", "2023-06-30")
} # }
```
