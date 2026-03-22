# Quickstart Guide

``` r
library(varunayan)
```

## ERA5 Data

ERA5 provides global climate reanalysis data. Requires [CDS API
credentials](https://cds.climate.copernicus.eu/how-to-api).

``` r
# One-time setup
setup_cds_credentials(key = "your-personal-access-token")
```

### Bounding Box

``` r
df <- era5ify_bbox(
  request_id = "mumbai_temp",
  variables = c("2m_temperature", "total_precipitation"),
  start_date = "2024-01-01",
  end_date = "2024-01-31",
  north = 20, south = 18, east = 74, west = 72,
  frequency = "daily"
)
```

### GeoJSON Region

``` r
df <- era5ify_geojson(
  request_id = "india_weather",
  variables = c("2m_temperature"),
  start_date = "2024-01-01",
  end_date = "2024-01-07",
  json_file = "india.geojson",
  frequency = "daily"
)
```

### Point Location

``` r
df <- era5ify_point(
  request_id = "delhi_temp",
  variables = c("2m_temperature"),
  start_date = "2024-01-01",
  end_date = "2024-01-31",
  lat = 28.6139, lon = 77.2090,
  frequency = "daily"
)
```

## IMD Data

IMD provides high-resolution gridded data for India. No credentials
required.

### Rainfall

``` r
# 0.25 degree resolution rainfall
df <- imd_rainfall_bbox(
  request_id = "maharashtra_rain",
  start_year = 2023,
  end_year = 2023,
  north = 22, south = 16, east = 80, west = 73,
  resolution = 0.25,
  frequency = "monthly"
)
```

### Temperature

``` r
# Maximum temperature
df <- imd_temperature_bbox(
  request_id = "delhi_tmax",
  start_year = 2023,
  end_year = 2023,
  north = 30, south = 27, east = 78, west = 76,
  var_type = "tmax"
)
```

### GeoJSON Region

``` r
df <- imd_rainfall_geojson(
  request_id = "kerala_rain",
  start_year = 2023,
  end_year = 2023,
  geojson_file = "kerala.geojson",
  resolution = 0.25
)
```

## Variable Discovery

``` r
# Search variables
search_variable("temperature")
#>              variable_name                  description units dataset_type
#> 1  2m_dewpoint_temperature 2 metre dewpoint temperature     K       single
#> 2           2m_temperature          2 metre temperature     K       single
#> 3         skin_temperature             Skin temperature     K       single
#> 4 soil_temperature_level_1     Soil temperature level 1     K       single
#> 5 soil_temperature_level_2     Soil temperature level 2     K       single
#> 6 soil_temperature_level_3     Soil temperature level 3     K       single
#> 7 soil_temperature_level_4     Soil temperature level 4     K       single
#> 8              temperature                  Temperature     K     pressure
#>                   category
#> 1 temperature_and_pressure
#> 2 temperature_and_pressure
#> 3 temperature_and_pressure
#> 4           soil_variables
#> 5           soil_variables
#> 6           soil_variables
#> 7           soil_variables
#> 8    atmospheric_variables

# Get descriptions
describe_variables(c("2m_temperature", "total_precipitation"))
#>         variable_name         description units dataset_type
#> 1      2m_temperature 2 metre temperature     K       single
#> 2 total_precipitation Total precipitation     m       single
#>                   category
#> 1 temperature_and_pressure
#> 2  precipitation_variables

# List all
head(list_available_variables("single"), 10)
#>  [1] "10m_u_component_of_wind"   "10m_v_component_of_wind"  
#>  [3] "2m_dewpoint_temperature"   "2m_temperature"           
#>  [5] "convective_precipitation"  "evaporation"              
#>  [7] "high_cloud_cover"          "large_scale_precipitation"
#>  [9] "low_cloud_cover"           "mean_sea_level_pressure"
```

## Cache Management

``` r
# View cache
show_cache_info()
```
