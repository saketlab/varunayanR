# NA

## Usage Examples

### 1. Credential setup

``` r

# Set up your CDS API credentials (do this once)
setup_cds_credentials(key = "your-cds-api-key-uuid-format")

# The key should be in UUID format like: "12345678-1234-1234-1234-123456789abc"
# Get it from: https://cds.climate.copernicus.eu/user
```

### 2. Variable discovery

``` r

# Search for precipitation variables
precip_vars <- search_variable("precipitation")
print(precip_vars)

# Get detailed descriptions
temp_desc <- describe_variables(c("2m_temperature", "skin_temperature"))
print(temp_desc)

# List all available single-level variables
all_single_vars <- list_available_variables("single")
head(all_single_vars, 10)

# List all available pressure-level variables
all_pressure_vars <- list_available_variables("pressure")
print(all_pressure_vars)

# See available pressure levels
pressure_levels <- get_available_pressure_levels()
print(pressure_levels)
```

### 3. Bounding box downloads

``` r

# Download daily temperature and precipitation for northeastern US
ne_data <- era5ify_bbox(
  request_id = "northeast_us_weather",
  variables = c("2m_temperature", "total_precipitation", "10m_u_component_of_wind"),
  start_date = "2023-06-01",
  end_date = "2023-06-07",
  north = 45.0,
  south = 40.0,
  east = -67.0,
  west = -80.0,
  frequency = "daily",
  resolution = 0.25
)

head(ne_data)
```

varunayan automatically handles large date ranges by chunking downloads:

``` r

# This will be automatically chunked into smaller requests
long_term_data <- era5ify_point(
  request_id = "climate_analysis",
  variables = c("2m_temperature", "total_precipitation"),
  start_date = "2020-01-01",
  end_date = "2023-12-31",  # 4 years of data
  lat = 40.7128,
  lon = -74.0060,
  frequency = "monthly"
)
```

Resolution for ERA5 can be customised:

``` r

# Download higher resolution data (0.1 degrees instead of default 0.25)
high_res_data <- era5ify_bbox(
  request_id = "high_resolution",
  variables = c("2m_temperature"),
  start_date = "2023-07-01", 
  end_date = "2023-07-01",
  north = 41.0,
  south = 40.0,
  east = -73.0, 
  west = -74.0,
  resolution = 0.1  # Higher resolution
)
```

### 4. Point location downloads

``` r

# Download hourly data for New York City  
nyc_weather <- era5ify_point(
  request_id = "nyc_hourly",
  variables = c("2m_temperature", "2m_dewpoint_temperature", "surface_pressure"),
  start_date = "2023-07-01",
  end_date = "2023-07-03", 
  lat = 40.7128,
  lon = -74.0060,
  frequency = "hourly"
)

head(nyc_weather)
```

### 5. GeoJSON region downloads

``` r

# First create or obtain a GeoJSON file defining your region
# For example, a simple polygon:
custom_region <- list(
  type = "Feature",
  geometry = list(
    type = "Polygon", 
    coordinates = list(list(
      c(-75, 35), c(-70, 35), c(-70, 40), c(-75, 40), c(-75, 35)
    ))
  ),
  properties = list(name = "custom_region")
)

jsonlite::write_json(custom_region, "custom_region.geojson", pretty = TRUE, auto_unbox = TRUE)

# Download data for the custom region
region_data <- era5ify_geojson(
  request_id = "custom_analysis", 
  variables = c("2m_temperature", "total_precipitation"),
  start_date = "2023-01-01",
  end_date = "2023-01-31",
  json_file = "custom_region.geojson",
  frequency = "daily"
)

head(region_data)
```

### 6. Pressure level data

``` r

# Download atmospheric data at multiple pressure levels
atmosphere_data <- era5ify_bbox(
  request_id = "upper_air_analysis",
  variables = c("temperature", "u_component_of_wind", "v_component_of_wind", "relative_humidity"),
  start_date = "2023-01-01",
  end_date = "2023-01-03",
  north = 45.0,
  south = 35.0, 
  east = -70.0,
  west = -80.0,
  dataset_type = "pressure",
  pressure_levels = c("1000", "850", "500", "200"),
  frequency = "daily"
)

head(atmosphere_data)
```

## Data visualisation

The package integrates well with R’s visualization ecosystem:

``` r

library(ggplot2)
library(dplyr)

# Plot temperature time series
climate_data %>%
  filter(variable == "2m_temperature") %>%
  ggplot(aes(x = datetime, y = value)) +
  geom_line(color = "red") +
  labs(title = "Temperature Time Series",
       x = "Date", 
       y = "Temperature (K)") +
  theme_minimal()

# Create spatial maps
library(sf)

# Convert to spatial data for mapping
spatial_data <- climate_data %>%
  filter(variable == "2m_temperature") %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# Plot spatial distribution
ggplot(spatial_data) +
  geom_sf(aes(color = value)) +
  scale_color_viridis_c(name = "Temperature (K)") +
  theme_minimal()
```
