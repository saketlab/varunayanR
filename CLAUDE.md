# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Project Overview

**varunayanR** (package name: `varunayan`) is an R package for
downloading and processing climate data from multiple sources: ERA5
reanalysis (Copernicus CDS), IMD (Indian Meteorological Department)
gridded data, HadEX3 global climate extremes (ETCCDI indices), and CRU
TS v4.07 monthly gridded observations. Supports extracting data via
bounding boxes, GeoJSON polygons, or point coordinates.

- **Author:** Saket Choudhary
- **License:** MIT
- **R requirement:** \>= 4.1.0
- **Site:** <https://saketlab.github.io/varunayanR/>
- **Repo:** <https://github.com/saketlab/varunayanR>

## Development Commands

``` bash
# Generate documentation (roxygen2) — run after changing any #' comments
Rscript -e 'roxygen2::roxygenize()'

# Check package (full R CMD check)
R CMD check .

# Build package
R CMD build .

# Install locally
R CMD INSTALL .

# Run all tests
Rscript -e 'testthat::test_dir("tests/testthat")'

# Run a single test file
Rscript -e 'testthat::test_file("tests/testthat/test-utils.R")'

# Build pkgdown site
Rscript -e 'pkgdown::build_site()'

# Build vignettes
Rscript -e 'devtools::build_vignettes()'

# CRAN-specific stricter check
Rscript -e 'devtools::check(cran = TRUE)'
```

## CI/CD

GitHub Actions (`.github/workflows/`): - **R-CMD-check.yaml** — Quick
check on Ubuntu R-release, then matrix (macOS, Windows, Ubuntu
devel/oldrel). Vignettes are skipped in CI
(`--no-build-vignettes --ignore-vignettes`). Needs `CDS_API_KEY` secret
for ERA5 credential tests. - **pkgdown.yaml** — Builds and deploys the
documentation site. - **test-coverage.yaml** — Runs test coverage
reporting.

## Architecture

### Four data source pipelines

Each pipeline follows the same pattern: **entry point → cache check →
download → process NetCDF/binary → unit conversion → return
data.frame**.

1.  **ERA5** (`R/core.R`, `R/download.R`, `R/processing.R`): Downloads
    from Copernicus CDS via `ecmwfr`. Entry points:
    [`era5ify_bbox()`](https://saketlab.github.io/varunayanR/reference/era5ify_bbox.md),
    [`era5ify_geojson()`](https://saketlab.github.io/varunayanR/reference/era5ify_geojson.md),
    [`era5ify_point()`](https://saketlab.github.io/varunayanR/reference/era5ify_point.md).
    **Requires CDS API credentials** (set via
    [`setup_cds_credentials()`](https://saketlab.github.io/varunayanR/reference/setup_cds_credentials.md)
    or `~/.cdsapirc`). Converts Kelvin→Celsius, meters→mm. Implements
    automatic request chunking to respect CDS field limits (120K for
    hourly/daily, 10K for monthly). Monthly requests default to 1 year
    per chunk due to internal CDS timeouts.

2.  **IMD** (`R/imd_core.R`, `R/imd_download.R`, `R/imd_processing.R`):
    Downloads from IMD servers via `httr`. Entry points:
    [`imd_rainfall_bbox()`](https://saketlab.github.io/varunayanR/reference/imd_rainfall_bbox.md),
    [`imd_rainfall_geojson()`](https://saketlab.github.io/varunayanR/reference/imd_rainfall_geojson.md),
    [`imd_temperature_bbox()`](https://saketlab.github.io/varunayanR/reference/imd_temperature_bbox.md),
    [`imd_temperature_geojson()`](https://saketlab.github.io/varunayanR/reference/imd_temperature_geojson.md).
    No credentials required.

3.  **HadEX3** (`R/hadex3.R`): Downloads ETCCDI climate extremes from
    Met Office. Entry points:
    [`hadex3_bbox()`](https://saketlab.github.io/varunayanR/reference/hadex3_bbox.md),
    [`hadex3_geojson()`](https://saketlab.github.io/varunayanR/reference/hadex3_geojson.md).
    27 annual indices + 18 monthly subset, 1901-2018, 1.25°×1.875°
    resolution. **Longitude quirk:** stored as 0-360° internally,
    auto-converted to -180/180 on read. Annual files use variable name
    `Ann`; monthly files use the index name. No credentials.

4.  **CRU TS** (`R/cru_ts.R`): Downloads CRU TS v4.07 from UEA. Entry
    points:
    [`cru_ts_bbox()`](https://saketlab.github.io/varunayanR/reference/cru_ts_bbox.md),
    [`cru_ts_geojson()`](https://saketlab.github.io/varunayanR/reference/cru_ts_geojson.md).
    10 variables, 1901-2022, 0.5° resolution. **Decade-split files** —
    only needed decades are downloaded.
    [`list_cru_ts_variables()`](https://saketlab.github.io/varunayanR/reference/list_cru_ts_variables.md)
    maps CRU codes to ERA5/HadEX3 equivalents. No credentials.

### Supporting modules

- `R/heat_stress.R` — Heat index calculations (WBGT, UTCI, humidex, wet
  bulb); largest file (~1330 lines, 34 exports)
- `R/spatial.R` — Polygon aggregation, grid comparison, GeoJSON
  filtering
- `R/cache.R` — Disk-based caching via `digest` MD5. Cache stored in
  `tools::R_user_dir("varunayan", "cache")`. Keys are parameter-based
  with readable prefixes (e.g., `era5_20230101_20231231_<hash>`)
- `R/variable_lists.R` — Aggregation rules: `sum_vars`
  (precip/radiation), `mean_vars` (temperature), `rate_vars`,
  `min_vars`, `max_vars`. Used by temporal aggregation to ensure correct
  statistics
- `R/search_and_desc.R` — Variable search and description functions
- `R/country.R` — Country-level convenience with cosine-latitude
  area-weighted aggregation via `maps` package
- `R/aliases.R` — PascalCase aliases (e.g., `ERA5ifyBbox`, `HadEX3Bbox`,
  `CRUTSBbox`) wrapping the snake_case primary functions
- `R/utils.R` — Shared utilities: validation, GeoJSON helpers, date
  parsing, timing

### Non-obvious implementation details

- **NetCDF time parsing fallback chain** (`R/processing.R`): Tries
  `read_ncdf()` auto conversion → `make_time=FALSE` → raw `ncdf4` →
  sequential date fallback. This handles diverse CDS NetCDF encodings.
- **CDS error handling**: Uses custom condition class
  `cds_request_too_large` for oversized requests.
- **Dual data manipulation**: Both `data.table` (performance on large
  grids) and `dplyr` (readability in pipelines) are used throughout —
  this is intentional.

### Naming conventions

- Primary API: **snake_case** (e.g., `era5ify_bbox`,
  `imd_rainfall_geojson`)
- PascalCase aliases in `R/aliases.R` for backward compatibility
- All exported functions documented with roxygen2; docs generated into
  `man/`

### Testing

Tests in `tests/testthat/` using testthat v3. Six test files covering:
utils, download, country, search-and-desc, hadex3, cru-ts. Most
download/credential-dependent tests are skipped in standard runs — tests
focus on offline-testable utility logic.

### Documentation site

Built with `pkgdown` (config in `_pkgdown.yml`, Bootstrap 5). Seven
vignettes covering quickstart, ERA5 vs IMD, spatial aggregation, heat
stress, country temperature, HadEX3, and CRU TS vs ERA5. Pre-downloaded
`.rds` data for vignettes lives in `inst/extdata/`.
