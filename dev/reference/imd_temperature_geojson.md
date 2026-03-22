# Download and process IMD temperature data for a GeoJSON region

Download and process IMD temperature data for a GeoJSON region

## Usage

``` r
IMDTemperatureGeojson(...)

imd_temperature_geojson(
  request_id,
  start_year,
  end_year,
  geojson_file,
  var_type = "tmax",
  frequency = "daily",
  save_raw = FALSE,
  output_dir = tempdir(),
  use_cache = TRUE
)
```

## Arguments

- ...:

  Arguments passed to the main function (used by aliases).

- request_id:

  Unique identifier.

- start_year:

  Start year (1951-2024).

- end_year:

  End year (1951-2024).

- geojson_file:

  Path to GeoJSON file.

- var_type:

  Temperature type: "tmax" or "tmin".

- frequency:

  Temporal frequency (default: "daily").

- save_raw:

  Whether to save raw files (default: FALSE).

- output_dir:

  Directory for output (default: tempdir()).

- use_cache:

  Whether to use cached data if available (default: TRUE).

## Value

data.frame with processed temperature data
