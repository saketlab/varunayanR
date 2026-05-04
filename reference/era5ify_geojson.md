# PascalCase Aliases

PascalCase aliases for all exported functions for backward
compatibility.

## Usage

``` r
ERA5ifyGeojson(...)

era5ify_geojson(
  request_id,
  variables,
  start_date,
  end_date,
  json_file,
  dataset_type = "single",
  pressure_levels = NULL,
  frequency = "hourly",
  resolution = 0.25,
  save_raw = FALSE,
  output_dir = tempdir(),
  use_cache = TRUE,
  convert_units = TRUE,
  verbose = FALSE
)
```

## Arguments

- ...:

  Arguments passed to the main function (used by aliases).

- request_id:

  Unique identifier for the data request

- variables:

  List of ERA5 variables to download

- start_date:

  Start date in "YYYY-MM-DD" format

- end_date:

  End date in "YYYY-MM-DD" format

- json_file:

  Path to GeoJSON file defining the region

- dataset_type:

  Type of dataset ("single" or "pressure")

- pressure_levels:

  Pressure levels for pressure dataset

- frequency:

  Temporal frequency ("hourly", "daily", "monthly")

- resolution:

  Spatial resolution in degrees (default: 0.25)

- save_raw:

  Whether to save raw downloaded files

- output_dir:

  Directory to save files (default: tempdir())

- use_cache:

  Whether to use cached data if available (default: TRUE)

- convert_units:

  Whether to convert units to user-friendly formats (default: TRUE).
  When TRUE, temperature variables are returned in Celsius (converted
  from Kelvin) and precipitation variables are returned in mm (converted
  from meters).

- verbose:

  Whether to print detailed progress messages

## Value

data.frame with processed climate data. When `convert_units = TRUE`:

- Temperature variables (e.g., 2m_temperature): Celsius

- Precipitation variables (e.g., total_precipitation): mm

- Other variables: original ERA5 units

## Examples

``` r
if (FALSE) { # \dontrun{
setup_cds_credentials(key = "your-cds-api-key")

data <- era5ify_geojson(
  request_id = "my_request",
  variables = c("2m_temperature", "total_precipitation"),
  start_date = "2023-01-01",
  end_date = "2023-01-31",
  json_file = "region.geojson"
)
# Temperature is in Celsius, precipitation is in mm
} # }
```
