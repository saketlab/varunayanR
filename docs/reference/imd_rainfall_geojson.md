# Download and process IMD rainfall data for a GeoJSON region

Download and process IMD rainfall data for a GeoJSON region

## Usage

``` r
IMDRainfallGeojson(...)

imd_rainfall_geojson(
  request_id,
  start_year,
  end_year,
  geojson_file,
  resolution = 0.25,
  frequency = "daily",
  save_raw = FALSE,
  output_dir = tempdir(),
  use_cache = TRUE
)
```

## Arguments

- request_id:

  Unique identifier for the request.

- start_year:

  Start year (1901-2024).

- end_year:

  End year (1901-2024).

- geojson_file:

  Path to GeoJSON file.

- resolution:

  Spatial resolution: 0.25 or 1.0 degrees (default: 0.25).

- frequency:

  Temporal frequency (default: "daily").

- save_raw:

  Whether to save raw files (default: FALSE).

- output_dir:

  Directory to save files (default: tempdir()).

## Value

data.frame with processed rainfall data
