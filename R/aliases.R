#' PascalCase Aliases
#'
#' PascalCase aliases for all exported functions for backward compatibility.
#' @name varunayan-aliases

# ERA5 functions
#' @rdname era5ify_geojson
#' @export
ERA5ifyGeojson <- function(...) era5ify_geojson(...)

#' @rdname era5ify_bbox
#' @export
ERA5ifyBbox <- function(...) era5ify_bbox(...)

#' @rdname era5ify_point
#' @export
ERA5ifyPoint <- function(...) era5ify_point(...)

# IMD functions
#' @rdname imd_rainfall_bbox
#' @export
IMDRainfallBbox <- function(...) imd_rainfall_bbox(...)

#' @rdname imd_rainfall_geojson
#' @export
IMDRainfallGeojson <- function(...) imd_rainfall_geojson(...)

#' @rdname imd_temperature_bbox
#' @export
IMDTemperatureBbox <- function(...) imd_temperature_bbox(...)

#' @rdname imd_temperature_geojson
#' @export
IMDTemperatureGeojson <- function(...) imd_temperature_geojson(...)

#' @rdname imd_stations
#' @export
IMDStations <- function(...) imd_stations(...)

# Setup and credentials
#' @rdname setup_cds_credentials
#' @export
SetupCdsCredentials <- function(...) setup_cds_credentials(...)

# Variable search and description
#' @rdname search_variable
#' @export
SearchVariable <- function(...) search_variable(...)

#' @rdname describe_variables
#' @export
DescribeVariables <- function(...) describe_variables(...)

#' @rdname list_available_variables
#' @export
ListAvailableVariables <- function(...) list_available_variables(...)

#' @rdname get_available_pressure_levels
#' @export
GetAvailablePressureLevels <- function(...) get_available_pressure_levels(...)

# Cache management
#' @rdname populate_sample_cache
#' @export
PopulateSampleCache <- function(...) populate_sample_cache(...)

#' @rdname show_cache_info
#' @export
ShowCacheInfo <- function(...) show_cache_info(...)

#' @rdname clear_cache
#' @export
ClearCache <- function(...) clear_cache(...)

#' @rdname get_cache_dir
#' @export
GetCacheDir <- function(...) get_cache_dir(...)

# Country-level convenience functions
#' @rdname get_era5_country_temperature
#' @export
GetERA5CountryTemperature <- function(...) get_era5_country_temperature(...)

# HadEX3 functions
#' @rdname hadex3_bbox
#' @export
HadEX3Bbox <- function(...) hadex3_bbox(...)

#' @rdname hadex3_geojson
#' @export
HadEX3Geojson <- function(...) hadex3_geojson(...)

#' @rdname list_hadex3_indices
#' @export
ListHadEX3Indices <- function(...) list_hadex3_indices(...)

# CRU TS functions
#' @rdname cru_ts_bbox
#' @export
CRUTSBbox <- function(...) cru_ts_bbox(...)

#' @rdname cru_ts_geojson
#' @export
CRUTSGeojson <- function(...) cru_ts_geojson(...)

#' @rdname list_cru_ts_variables
#' @export
ListCRUTSVariables <- function(...) list_cru_ts_variables(...)

# System utilities

#' @rdname check_system_readiness
#' @export
CheckSystemReadiness <- function(...) check_system_readiness(...)

#' @rdname get_package_info
#' @export
GetPackageInfo <- function(...) get_package_info(...)
