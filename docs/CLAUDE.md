# varunayanR - R Native Implementation of Varunayan

## About this package

**varunayanR** is an R native rewrite of the [varunayan Python
package](https://github.com/saketlab/varunayan), designed for
downloading and processing ERA5 climate data for custom geographical
regions. This package provides analysis-ready climate data using the
ecmwfr package to interface with the Copernicus Climate Data Store.

## Package structure

### Core modules

#### 1. **Core functions** (`R/core.R`)

Main user-facing functions for ERA5 data download and processing: -
[`era5ify_geojson()`](https://saketlab.github.io/varunayanR/reference/era5ify_geojson.md):
Download data for GeoJSON-defined regions -
[`era5ify_bbox()`](https://saketlab.github.io/varunayanR/reference/era5ify_bbox.md):
Download data for bounding box regions -
[`era5ify_point()`](https://saketlab.github.io/varunayanR/reference/era5ify_point.md):
Download data for specific point locations

**Key features:** - Temporal chunking for large date ranges (handles
\>31 days automatically) - Support for both single-level and
pressure-level datasets - Automatic spatial filtering using GeoJSON
polygons - Temporal aggregation (hourly, daily, monthly, yearly)

#### 2. **Download functions** (`R/download.R`)

ERA5 data download using ecmwfr: -
[`setup_cds_credentials()`](https://saketlab.github.io/varunayanR/reference/setup_cds_credentials.md):
Configure CDS API credentials -
[`download_era5_single()`](https://saketlab.github.io/varunayanR/reference/download_era5_single.md):
Download single-level data -
[`download_era5_pressure()`](https://saketlab.github.io/varunayanR/reference/download_era5_pressure.md):
Download pressure-level data -
[`validate_era5_variables()`](https://saketlab.github.io/varunayanR/reference/validate_era5_variables.md):
Validate variable names

**Implementation notes:** - Uses `ecmwfr` package (not cdsapi like
Python version) - Implements retry logic with configurable timeouts -
Handles ZIP file extraction automatically - Supports both direct NetCDF
and ZIP archive downloads

#### 3. **Processing functions** (`R/processing.R`)

NetCDF data processing and transformation: -
[`process_netcdf_to_dataframe()`](https://saketlab.github.io/varunayanR/reference/process_netcdf_to_dataframe.md):
Convert NetCDF to data.frame -
[`filter_netcdf_by_geojson()`](https://saketlab.github.io/varunayanR/reference/filter_netcdf_by_geojson.md):
Spatial filtering with GeoJSON -
[`filter_netcdf_by_bbox()`](https://saketlab.github.io/varunayanR/reference/filter_netcdf_by_bbox.md):
Spatial filtering with bounding box -
[`extract_point_data()`](https://saketlab.github.io/varunayanR/reference/extract_point_data.md):
Extract nearest grid point -
[`aggregate_by_frequency()`](https://saketlab.github.io/varunayanR/reference/aggregate_by_frequency.md):
Temporal aggregation -
[`combine_netcdf_files()`](https://saketlab.github.io/varunayanR/reference/combine_netcdf_files.md):
Merge multiple NetCDF files

**Key differences from Python:** - Uses `stars` and `ncdf4` packages
instead of `xarray` - Fallback mechanisms for time conversion issues -
Manual reshaping to avoid tidyr dependency

#### 4. **Search and Description** (`R/search_and_desc.R`)

Variable discovery and metadata: -
[`search_variable()`](https://saketlab.github.io/varunayanR/reference/search_variable.md):
Search variables by keyword -
[`describe_variables()`](https://saketlab.github.io/varunayanR/reference/describe_variables.md):
Get detailed variable information -
[`list_available_variables()`](https://saketlab.github.io/varunayanR/reference/list_available_variables.md):
List all available variables -
[`get_available_pressure_levels()`](https://saketlab.github.io/varunayanR/reference/get_available_pressure_levels.md):
List pressure levels

**Variable metadata:** - Single-level variables organized by category
(temperature, precipitation, wind, etc.) - Pressure-level atmospheric
variables - Complete descriptions and units for all variables

#### 5. **Utilities** (`R/utils.R`)

Helper functions for data handling: - GeoJSON validation and
conversion - Date parsing and formatting - Coordinate validation -
Temporary file management - Dependency checking - System readiness
checks

## Methodology overview

### Data download workflow

1.  **Input validation**
    - Validate variables against dataset type
    - Check date ranges and coordinate boundaries
    - Verify GeoJSON structure if provided
2.  **Spatial definition**
    - For GeoJSON: Calculate bounding box from polygon
    - For bbox: Use provided coordinates
    - For point: Create small bounding box around point
3.  **Temporal chunking**
    - Split large date ranges into manageable chunks (31 days default)
    - Process chunks sequentially with rate limiting
    - Combine results at the end
4.  **CDS API Request**
    - Build request parameters for CDS API
    - Handle different datasets (single-level vs pressure-level)
    - Manage hourly vs monthly data products
    - Submit via ecmwfr with retry logic
5.  **Post-Processing**
    - Extract ZIP archives if needed
    - Convert NetCDF to data.frame
    - Apply spatial filtering (GeoJSON or bbox)
    - Perform temporal aggregation
    - Save results to output directory

## Performance optimizations

The package includes critical optimizations for handling large datasets
with complex geometries. See **PERFORMANCE_OPTIMIZATIONS.md** for full
details.

### Key optimizations implemented:

1.  **Geometry Simplification** (3-5x speedup)
    - Automatically simplifies complex polygons (\>10k vertices)
    - Preserves topology while reducing computational complexity
    - Reduces Indian states polygon from 50k+ to ~10k vertices
2.  **Spatial Pre-aggregation** (50-100x speedup for temporal data)
    - Triggered automatically for datasets \> 500k points
    - Identifies unique spatial locations before expensive operations
    - For multi-temporal data: 9.5M points → 17k unique locations
    - Expands back to original after filtering
3.  **GEOMETRYCOLLECTION Handling** (Stability)
    - Automatically handles mixed geometry types in GeoJSON
    - Prevents crashes with complex boundary files
4.  **Aggressive Batching** (4x less memory, more stable)
    - Batches at 50k points (down from 150k threshold)
    - Processes 25k per batch (down from 100k)
    - Prevents memory issues and allows progress tracking
5.  **Progress Tracking with ETA**
    - Real-time batch progress percentages
    - Estimated time remaining based on average batch time
    - Clear timing breakdowns for each operation

### Performance example:

**Scenario:** ERA5 India states analysis (2021-2022, 0.25° resolution,
9.5M points)

| Metric          | Original             | Optimized    | Improvement   |
|-----------------|----------------------|--------------|---------------|
| Processing Time | \>12 hours (crashed) | 8-15 minutes | 50-90x faster |
| Memory Usage    | \>16 GB              | 2-4 GB       | 4x reduction  |
| Stability       | InterruptedException | Completes    | 100% reliable |

### Usage:

Optimizations are **automatic** - no code changes required:

``` r

# Automatically optimized for large datasets
data <- era5ify_geojson(
  request_id = "india_analysis",
  variables = c("2m_temperature"),
  start_date = "2021-01-01",
  end_date = "2022-12-31",
  json_file = "indian_states.geojson",
  frequency = "daily",
  resolution = 0.25
)

# Monitor performance
timings <- get_timings()
print_timing_summary()
```

**See examples/performance_test.R for comprehensive performance
testing.**

### Key differences from Python implementation

| Aspect | Python (varunayan) | R (varunayanR) |
|----|----|----|
| **CDS Interface** | cdsapi package | ecmwfr package |
| **NetCDF Reading** | xarray | stars + ncdf4 |
| **Spatial Operations** | shapely | sf package |
| **Data Structures** | pandas DataFrame | R data.frame |
| **Class Structure** | ProcessingParams dataclass | Function parameters |
| **Aggregation** | Variable-specific (sum/max/min/avg) | Simple mean aggregation |
| **Logging** | Python logging module | cli package messages |

### Missing features to implement

1.  **Variable-specific aggregation**
    - Python has lists of variables that require specific aggregation
      methods:
      - `sum_vars`: Variables to sum over time (precipitation,
        radiation, etc.)
      - `max_vars`: Variables to take maximum (max temperature, wind
        gust)
      - `min_vars`: Variables to take minimum (min temperature)
      - `rate_vars`: Rate variables to average
    - R currently uses simple mean aggregation for all variables
2.  **Advanced processing functions**
    - `aggregate_pressure_levels()`: Special handling for pressure-level
      data
    - Adjustment for sum variables in monthly/yearly aggregation
    - Duplicate removal based on time/lat/lon/pressure_level
    - Feature-based aggregation for distinct GeoJSON areas
3.  **File handling utilities**
    - `extract_download()`: Extract and organize downloaded files
    - Advanced ZIP/NetCDF file handling
    - Cleanup of temporary files matching patterns
4.  **Enhanced logging**
    - Verbosity levels (0=warning, 1=info, 2=debug)
    - Colored output for different message types
    - Progress indicators for long operations

## Data aggregation strategy

### Python implementation

The Python version uses sophisticated aggregation logic:

1.  **Spatial aggregation first**
    - Average across all lat/lon points for each timestamp
    - Different methods for different variable types at this stage
2.  **Temporal aggregation second**
    - Sum for accumulation variables (precipitation, radiation)
    - Max for maximum variables
    - Min for minimum variables
    - Average for rate variables and standard variables
3.  **Feature-aware processing**
    - If GeoJSON has distinguishing features, process each separately
    - Maintain feature identity through aggregation pipeline

### R current implementation

The R version currently: - Performs simple mean aggregation across all
variables - Does not distinguish between accumulation vs rate
variables - Needs enhancement to match Python methodology

## Testing strategy

### Required test cases

1.  **Basic functionality**

    ``` r

    # Test single-level bbox download
    data <- era5ify_bbox(
      request_id = "test_bbox",
      variables = c("2m_temperature", "total_precipitation"),
      start_date = "2024-01-01",
      end_date = "2024-01-03",
      north = 30, south = 25, east = 80, west = 75
    )
    ```

2.  **GeoJSON Processing**

    ``` r

    # Test GeoJSON filtering
    data <- era5ify_geojson(
      request_id = "test_geojson",
      variables = c("2m_temperature"),
      start_date = "2024-01-01",
      end_date = "2024-01-02",
      json_file = "test_region.geojson"
    )
    ```

3.  **Pressure-level data**

    ``` r

    # Test pressure-level download
    data <- era5ify_bbox(
      request_id = "test_pressure",
      variables = c("temperature", "relative_humidity"),
      start_date = "2024-01-01",
      end_date = "2024-01-02",
      north = 30, south = 25, east = 80, west = 75,
      dataset_type = "pressure",
      pressure_levels = c("1000", "850", "500")
    )
    ```

4.  **Temporal aggregation**

    ``` r

    # Test daily aggregation
    data <- era5ify_point(
      request_id = "test_daily",
      variables = c("2m_temperature"),
      start_date = "2024-01-01",
      end_date = "2024-01-31",
      lat = 28.6139,
      lon = 77.2090,
      frequency = "daily"
    )
    ```

## Dependencies

### R Packages

- **ecmwfr** (\>= 2.0.0): Interface to CDS API
- **sf**: Spatial data operations
- **stars**: Spatiotemporal arrays (NetCDF reading)
- **ncdf4**: Low-level NetCDF interface
- **ncmeta**: NetCDF metadata
- **dplyr**: Data manipulation
- **lubridate**: Date/time handling
- **jsonlite**: JSON processing
- **cli**: User interface
- **terra**: Raster data handling

### System requirements

- R \>= 4.1.0
- CDS API credentials
- Network connectivity

## Setup instructions

1.  **Install package**

    ``` r

    # From source
    devtools::install_local("path/to/varunayanR")
    ```

2.  **Configure CDS credentials**

    ``` r

    library(varunayan)
    setup_cds_credentials(key = "your-cds-api-key")
    ```

    Get your API key from:
    <https://cds.climate.copernicus.eu/api-how-to>

3.  **Check system readiness**

    ``` r

    check_system_readiness()
    check_dependencies(install_missing = TRUE)
    ```

## Development notes

### Avoid R6 classes

The R implementation uses functional programming approach instead of
R6/S3 classes: - Core functions take parameters directly - No
ProcessingParams class equivalent - State managed through function
parameters and return values - Simpler for users familiar with
functional R style

### CDS API setup

The Python version uses `cdsapi` while R uses `ecmwfr`. Both work with
the same Copernicus CDS but have different interfaces:

**Python (cdsapi):**

``` python
import cdsapi
client = cdsapi.Client()
client.retrieve(dataset, request, output_file)
```

**R (ecmwfr):**

``` r

library(ecmwfr)
wf_set_key(key = "your-key")
wf_request(request, transfer = TRUE, path = output_dir)
```

### File organization

    varunayanR/
    ├── R/
    │   ├── core.R              # ERA5 main user functions
    │   ├── download.R          # ERA5 CDS download functions
    │   ├── processing.R        # ERA5 NetCDF processing
    │   ├── search_and_desc.R   # Variable metadata
    │   ├── utils.R             # Helper functions
    │   ├── variable_lists.R    # Variable aggregation metadata
    │   ├── imd_core.R          # IMD main user functions
    │   ├── imd_download.R      # IMD download functions
    │   ├── imd_processing.R    # IMD data processing
    │   └── varunayan-package.R # Package documentation
    ├── examples/
    │   ├── basic_usage.R       # ERA5 usage examples
    │   └── imd_usage.R         # IMD usage examples
    ├── tests/
    │   └── testthat/
    │       ├── test-core.R
    │       ├── test-download.R
    │       ├── test-processing.R
    │       └── test-search-and-desc.R
    ├── DESCRIPTION
    ├── NAMESPACE
    ├── LICENSE
    └── CLAUDE.md (this file)

## IMD (Indian Meteorological Department) data support

### Overview

The package now supports downloading and processing gridded climate data
from the Indian Meteorological Department (IMD). IMD data provides
high-resolution observations specifically for the Indian region.

### IMD modules

#### 1. **IMD core functions** (`R/imd_core.R`)

Main user-facing functions for IMD data: -
[`imd_rainfall_bbox()`](https://saketlab.github.io/varunayanR/reference/imd_rainfall_bbox.md):
Download rainfall data for bounding box -
[`imd_rainfall_geojson()`](https://saketlab.github.io/varunayanR/reference/imd_rainfall_geojson.md):
Download rainfall data for GeoJSON region -
[`imd_temperature_bbox()`](https://saketlab.github.io/varunayanR/reference/imd_temperature_bbox.md):
Download temperature data for bounding box -
[`imd_temperature_geojson()`](https://saketlab.github.io/varunayanR/reference/imd_temperature_geojson.md):
Download temperature data for GeoJSON region

#### 2. **IMD download functions** (`R/imd_download.R`)

Direct HTTP downloads from IMD servers: -
[`download_imd_rainfall()`](https://saketlab.github.io/varunayanR/reference/download_imd_rainfall.md):
Download gridded rainfall NetCDF files -
[`download_imd_temperature()`](https://saketlab.github.io/varunayanR/reference/download_imd_temperature.md):
Download gridded temperature binary files -
[`list_imd_datasets()`](https://saketlab.github.io/varunayanR/reference/list_imd_datasets.md):
List available IMD datasets -
[`get_imd_grid_specs()`](https://saketlab.github.io/varunayanR/reference/get_imd_grid_specs.md):
Get grid specifications for datasets

**Available datasets:** - **Rainfall (0.25°)**: 1901-2024, 135×129 grid,
NetCDF format - **Rainfall (1.0°)**: 1901-2024, 31×31 grid, NetCDF
format - **Max Temperature (1.0°)**: 1951-2024, 31×31 grid, Binary
format - **Min Temperature (1.0°)**: 1951-2024, 31×31 grid, Binary
format

#### 3. **IMD processing functions** (`R/imd_processing.R`)

Data processing and conversion: -
[`read_imd_rainfall()`](https://saketlab.github.io/varunayanR/reference/read_imd_rainfall.md):
Read NetCDF rainfall files -
[`read_imd_temperature()`](https://saketlab.github.io/varunayanR/reference/read_imd_temperature.md):
Read binary temperature files -
[`process_imd_files()`](https://saketlab.github.io/varunayanR/reference/process_imd_files.md):
Process multiple IMD files -
[`filter_imd_by_bbox()`](https://saketlab.github.io/varunayanR/reference/filter_imd_by_bbox.md):
Spatial filtering -
[`filter_imd_by_geojson()`](https://saketlab.github.io/varunayanR/reference/filter_imd_by_geojson.md):
GeoJSON-based filtering -
[`aggregate_imd_by_frequency()`](https://saketlab.github.io/varunayanR/reference/aggregate_imd_by_frequency.md):
Temporal aggregation

### IMD data characteristics

| Dataset             | Variable       | Resolution | Years     | Grid    | Format | Unit |
|---------------------|----------------|------------|-----------|---------|--------|------|
| Rainfall (High-Res) | Daily rainfall | 0.25°      | 1901-2024 | 135×129 | NetCDF | mm   |
| Rainfall (Standard) | Daily rainfall | 1.0°       | 1901-2024 | 31×31   | NetCDF | mm   |
| Max Temperature     | Daily Tmax     | 1.0°       | 1951-2024 | 31×31   | Binary | °C   |
| Min Temperature     | Daily Tmin     | 1.0°       | 1951-2024 | 31×31   | Binary | °C   |

### Grid specifications

**Rainfall 0.25° Grid:** - Latitude: 6.5°N to 38.5°N (135 points) -
Longitude: 66.5°E to 100.0°E (129 points) - Resolution: 0.25°

**Rainfall/Temperature 1.0° Grid:** - Latitude: 7.5°N to 37.5°N (31
points) - Longitude: 67.5°E to 97.5°E (31 points) - Resolution: 1.0°

### IMD server connectivity and reliability

**Important notes:**

1.  **Data availability**: IMD data is available through 2024. Data for
    2025 and beyond may not be available yet.

2.  **Server connectivity**: The IMD server (www.imdpune.gov.in) can be
    unreliable:

    - May be temporarily unavailable
    - Can have slow response times
    - Connection timeouts are common

3.  **Automatic caching**: All IMD downloads are cached automatically:

    - **Cache-first approach**: Checks cache before attempting server
      connection
    - **Offline capability**: Can work completely offline if data is
      cached
    - **Smart detection**: Shows which years are cached vs need
      downloading
    - **Sample data**: Can populate cache with sample data for testing
    - **Cache location**: `tools::R_user_dir("varunayan", "cache")`

4.  **Error handling**: The package includes robust error handling:

    - **Cache-aware**: Only checks server if data not in cache
    - Automatic retry logic with exponential backoff (up to 3 attempts)
    - Extended timeouts (10 minutes for downloads, 60 seconds for
      connections)
    - Clear error messages showing cached vs missing years
    - Helpful suggestions when server is unreachable

5.  **Cache utilities**:

    ``` r

    # View cache contents
    show_cache_info()

    # Populate cache with sample data for testing
    populate_sample_cache()

    # Work offline using cached data
    data <- imd_rainfall_bbox(
      request_id = "offline",
      start_year = 2024,  # If cached
      end_year = 2024,
      north = 30, south = 25,
      east = 80, west = 75
    )
    # Output: ✔ All requested data available in cache. No download needed!

    # Get cache directory
    cache_dir <- get_cache_dir()

    # Clear cache if needed
    clear_cache(confirm = TRUE)
    ```

6.  **Troubleshooting download failures**:

    ``` r

    # If download fails with connectivity error:
    # 1. Check what's in cache: show_cache_info()
    # 2. Use cached years only
    # 3. Populate sample cache: populate_sample_cache()
    # 4. Try again later (server may be down)
    # 5. Consider ERA5 as alternative
    ```

7.  **Alternative**: If IMD server is persistently unavailable, consider
    using ERA5 data instead, which has more reliable infrastructure.

### IMD vs ERA5 comparison

| Aspect               | IMD                  | ERA5                 |
|----------------------|----------------------|----------------------|
| **Coverage**         | India only           | Global               |
| **Resolution**       | 0.25° or 1.0°        | 0.25° or finer       |
| **Temporal Range**   | 1901-2024 (rainfall) | 1940-present         |
| **Authentication**   | None required        | CDS API key required |
| **Download Method**  | Direct HTTP POST     | CDS API via ecmwfr   |
| **Data Format**      | NetCDF/Binary        | NetCDF               |
| **Variables**        | Rainfall, Tmax, Tmin | 100+ variables       |
| **Update Frequency** | Annual               | Near real-time       |

### Example usage

``` r

library(varunayan)

# Download high-resolution rainfall
maharashtra_rain <- imd_rainfall_bbox(
  request_id = "maharashtra",
  start_year = 2023,
  end_year = 2024,
  north = 22, south = 16,
  east = 80, west = 73,
  resolution = 0.25,
  frequency = "monthly"
)

# Download maximum temperature
delhi_tmax <- imd_temperature_bbox(
  request_id = "delhi",
  start_year = 2023,
  end_year = 2024,
  north = 29, south = 28,
  east = 78, west = 76,
  var_type = "tmax"
)

# Use GeoJSON for complex regions
region_rain <- imd_rainfall_geojson(
  request_id = "custom_region",
  start_year = 2024,
  end_year = 2024,
  geojson_file = "region.geojson",
  resolution = 0.25
)
```

### Implementation details

**Download process:** 1. POST request to IMD server with year and
variable parameters 2. Binary response contains raw gridded data 3.
NetCDF files for rainfall, binary grid files for temperature 4. No
authentication required

**Data processing:** - Rainfall: Read NetCDF using `stars` or `ncdf4` -
Temperature: Read binary using base R
[`readBin()`](https://rdrr.io/r/base/readBin.html) - Convert to
data.frame with date, lat, lon, value columns - Apply spatial and
temporal filtering

**Data sources:** - Rainfall 0.25°:
<https://www.imdpune.gov.in/cmpg/Griddata/Rainfall_25_NetCDF.html> -
Rainfall 1.0°:
<https://www.imdpune.gov.in/cmpg/Griddata/Rainfall_1_NetCDF.html> - Max
Temp: <https://www.imdpune.gov.in/cmpg/Griddata/Max_1_Bin.html> - Min
Temp: <https://www.imdpune.gov.in/cmpg/Griddata/Min_1_Bin.html>

## Next steps for development

1.  **✅ Implement variable lists**
    - ✅ Created R/variable_lists.R with sum_vars, max_vars, min_vars,
      rate_vars
    - ✅ Ported from Python variable_lists.py
2.  **✅ IMD data support**
    - ✅ Complete IMD module for Indian gridded data
    - ✅ Support for rainfall and temperature datasets
    - ✅ Both NetCDF and binary format handling
3.  **Enhanced aggregation**
    - Update aggregate_by_frequency() to use variable-specific methods
    - Implement aggregate_pressure_levels() for pressure data
    - Add feature-aware processing
4.  **Advanced file handling**
    - Implement extract_download() function
    - Better temporary file management
    - Support for multi-file NetCDF archives
5.  **Testing**
    - Add comprehensive test suite
    - Mock CDS API responses for CI/CD
    - Validate output against Python version
6.  **Documentation**
    - Create vignettes for common use cases
    - Add examples to all exported functions
    - Build pkgdown website

## Resources

### ERA5 resources

- **Python Package**: <https://github.com/saketlab/varunayan>
- **CDS API Documentation**:
  <https://cds.climate.copernicus.eu/api-how-to>
- **ERA5 Documentation**:
  <https://confluence.ecmwf.int/display/CKB/ERA5>
- **ecmwfr Package**: <https://github.com/bluegreen-labs/ecmwfr>

### IMD resources

- **IMD Gridded Data Portal**:
  <https://www.imdpune.gov.in/cmpg/Griddata/Griddata.html>
- **Rainfall 0.25° Data**:
  <https://www.imdpune.gov.in/cmpg/Griddata/Rainfall_25_NetCDF.html>
- **Rainfall 1.0° Data**:
  <https://www.imdpune.gov.in/cmpg/Griddata/Rainfall_1_NetCDF.html>
- **Max Temperature Data**:
  <https://www.imdpune.gov.in/cmpg/Griddata/Max_1_Bin.html>
- **Min Temperature Data**:
  <https://www.imdpune.gov.in/cmpg/Griddata/Min_1_Bin.html>

## License

MIT License - Same as Python varunayan package
