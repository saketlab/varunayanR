#' CRU TS Gridded Climate Dataset
#'
#' Functions to download and process the University of East Anglia Climatic
#' Research Unit Time-Series (CRU TS) gridded monthly climate dataset.
#' Covers global land areas (excl. Antarctica) at 0.5 degree resolution,
#' 1901-2022.
#'
#' @references
#' Harris et al. (2020) Version 4 of the CRU TS monthly high-resolution
#' gridded multivariate climate dataset. Sci. Data 7:109.
#' https://doi.org/10.1038/s41597-020-0453-3
#' @name cru_ts

.CRU_TS_VERSION <- "4.07"
.CRU_TS_SUBDIR <- "cruts.2304141047.v4.07"
.CRU_TS_BASE_URL <- sprintf(
  "https://crudata.uea.ac.uk/cru/data/hrg/cru_ts_%s/%s",
  .CRU_TS_VERSION, .CRU_TS_SUBDIR
)
.CRU_TS_YEAR_START <- 1901L
.CRU_TS_YEAR_END <- 2022L

# Decade file boundaries (end year of each file)
.CRU_TS_DECADES <- list(
  c(1901L, 1910L), c(1911L, 1920L), c(1921L, 1930L), c(1931L, 1940L),
  c(1941L, 1950L), c(1951L, 1960L), c(1961L, 1970L), c(1971L, 1980L),
  c(1981L, 1990L), c(1991L, 2000L), c(2001L, 2010L), c(2011L, 2020L),
  c(2021L, 2022L)
)

#' Variable data dictionary for CRU TS
#'
#' Maps CRU TS variable codes to common names, units, and ERA5 equivalents.
#'
#' @param ... Arguments passed to the main function (used by aliases).
#' @return data.frame with columns: variable, name, description, unit,
#'   era5_equivalent, hadex3_equivalent.
#' @export
#' @examples
#' list_cru_ts_variables()
list_cru_ts_variables <- function(...) {
  data.frame(
    variable = c("tmp", "tmx", "tmn", "dtr", "pre", "wet", "frs", "vap", "cld", "pet"),
    name = c(
      "mean_temperature", "max_temperature", "min_temperature",
      "diurnal_temperature_range", "precipitation", "wet_day_frequency",
      "frost_day_frequency", "vapour_pressure", "cloud_cover",
      "potential_evapotranspiration"
    ),
    description = c(
      "Monthly mean daily mean temperature",
      "Monthly mean daily maximum temperature",
      "Monthly mean daily minimum temperature",
      "Monthly mean diurnal temperature range (tmx - tmn)",
      "Monthly total precipitation",
      "Monthly count of wet days (precipitation >= 0.1 mm)",
      "Monthly count of frost days (minimum temperature < 0\u00b0C)",
      "Monthly mean vapour pressure",
      "Monthly mean cloud cover (oktas converted to %)",
      "Monthly total potential evapotranspiration (Penman-Monteith)"
    ),
    unit = c(
      "\u00b0C", "\u00b0C", "\u00b0C", "\u00b0C",
      "mm/month",
      "days/month",
      "days/month",
      "hPa",
      "%",
      "mm/month"
    ),
    era5_equivalent = c(
      "2m_temperature",
      "maximum_2m_temperature_since_previous_post_processing",
      "minimum_2m_temperature_since_previous_post_processing",
      NA_character_,
      "total_precipitation",
      NA_character_,
      NA_character_,
      "2m_dewpoint_temperature",
      "total_cloud_cover",
      NA_character_
    ),
    hadex3_equivalent = c(
      NA_character_, "TXx/TXn", "TNx/TNn", "DTR",
      "PRCPTOT", "CWD", "FD",
      NA_character_, NA_character_, NA_character_
    ),
    stringsAsFactors = FALSE
  )
}

#' Build CRU TS download URL for a specific decade file
#' @param variable CRU TS variable code.
#' @param decade_start Start year of the decade file.
#' @param decade_end End year of the decade file.
#' @return Character URL.
#' @keywords internal
.cru_ts_url <- function(variable, decade_start, decade_end) {
  filename <- sprintf(
    "cru_ts%s.%d.%d.%s.dat.nc.gz",
    .CRU_TS_VERSION, decade_start, decade_end, variable
  )
  sprintf("%s/%s/%s", .CRU_TS_BASE_URL, variable, filename)
}

#' Find which decade files overlap with a year range
#' @keywords internal
.cru_ts_needed_decades <- function(start_year, end_year) {
  Filter(
    function(d) d[2] >= start_year && d[1] <= end_year,
    .CRU_TS_DECADES
  )
}

#' Download and decompress a single CRU TS decade file
#' @keywords internal
.download_cru_ts_decade <- function(variable, decade_start, decade_end,
                                    output_dir, use_cache) {
  cache_key <- digest::digest(
    list(
      source = "cru_ts", version = .CRU_TS_VERSION,
      variable = variable, decade_start = decade_start, decade_end = decade_end
    ),
    algo = "md5"
  )

  if (use_cache) {
    cached <- check_cache(cache_key)
    if (!is.null(cached)) {
      message(sprintf("Loading CRU TS %s %d-%d from cache.", variable, decade_start, decade_end))
      return(readRDS(cached))
    }
  }

  url <- .cru_ts_url(variable, decade_start, decade_end)
  gz_file <- file.path(output_dir, basename(url))
  nc_file <- sub("\\.gz$", "", gz_file)

  message(sprintf("Downloading CRU TS %s %d-%d...", variable, decade_start, decade_end))

  response <- tryCatch(
    httr::GET(url, httr::timeout(600), httr::write_disk(gz_file, overwrite = TRUE)),
    error = function(e) stop("Download failed: ", e$message)
  )

  if (httr::status_code(response) != 200) {
    stop(sprintf(
      "HTTP %d for CRU TS %s %d-%d.", httr::status_code(response),
      variable, decade_start, decade_end
    ))
  }

  message("Decompressing...")
  .decompress_gz(gz_file, nc_file)
  unlink(gz_file)
  on.exit(unlink(nc_file), add = TRUE)

  data <- .read_cru_ts_nc(nc_file, variable)

  if (use_cache) {
    rds_file <- tempfile(fileext = ".rds")
    saveRDS(data, rds_file)
    tryCatch(
      save_to_cache(rds_file, cache_key),
      error = function(e) warning("Could not cache CRU TS data: ", e$message, call. = FALSE)
    )
    unlink(rds_file)
  }

  data
}

#' Read a CRU TS NetCDF file into a data.frame
#' @param nc_file Path to decompressed .nc file.
#' @param variable CRU TS variable code.
#' @return data.frame with year, month, latitude, longitude, value, variable.
#' @keywords internal
.read_cru_ts_nc <- function(nc_file, variable) {
  nc <- ncdf4::nc_open(nc_file)
  on.exit(ncdf4::nc_close(nc), add = TRUE)

  lat <- ncdf4::ncvar_get(nc, "lat")
  lon <- ncdf4::ncvar_get(nc, "lon")

  if (!variable %in% names(nc$var)) {
    stop(sprintf(
      "Variable '%s' not found in NetCDF. Available: %s",
      variable, paste(names(nc$var), collapse = ", ")
    ))
  }

  vals <- ncdf4::ncvar_get(nc, variable)
  fill_val <- ncdf4::ncatt_get(nc, variable, "_FillValue")$value

  time_var <- ncdf4::ncvar_get(nc, "time")
  time_units <- ncdf4::ncatt_get(nc, "time", "units")$value

  dates <- .parse_cru_ts_time(time_var, time_units)

  n_lon <- length(lon)
  n_lat <- length(lat)
  n_time <- length(dates)

  grid <- expand.grid(
    lon_idx = seq_len(n_lon),
    lat_idx = seq_len(n_lat),
    time_idx = seq_len(n_time),
    KEEP.OUT.ATTRS = FALSE
  )

  grid$value <- vals[cbind(grid$lon_idx, grid$lat_idx, grid$time_idx)]
  grid$longitude <- lon[grid$lon_idx]
  grid$latitude <- lat[grid$lat_idx]
  grid$year <- as.integer(format(dates[grid$time_idx], "%Y"))
  grid$month <- as.integer(format(dates[grid$time_idx], "%m"))
  grid$variable <- variable

  result <- grid[, c("year", "month", "latitude", "longitude", "value", "variable")]
  result <- result[!is.na(result$value), ]
  if (!is.null(fill_val) && is.numeric(fill_val)) {
    result <- result[abs(result$value - fill_val) > 1e-6, ]
  }
  rownames(result) <- NULL
  result
}

#' Parse CRU TS time coordinate to Date vector
#' @keywords internal
.parse_cru_ts_time <- function(time_var, time_units) {
  if (grepl("days since", time_units, ignore.case = TRUE)) {
    base_date <- as.Date(sub("days since ", "", trimws(time_units)))
    base_date + time_var
  } else if (grepl("months since", time_units, ignore.case = TRUE)) {
    base_match <- regmatches(time_units, regexpr("\\d{4}-\\d{2}", time_units))
    base_year <- as.integer(substr(base_match, 1, 4))
    base_month <- as.integer(substr(base_match, 6, 7))
    total_months <- base_year * 12L + (base_month - 1L) + as.integer(round(time_var))
    as.Date(sprintf("%d-%02d-01", total_months %/% 12L, total_months %% 12L + 1L))
  } else {
    stop("Unrecognised time units in CRU TS file: ", time_units)
  }
}

#' Validate CRU TS inputs
#' @keywords internal
.validate_cru_ts_inputs <- function(variable, start_year, end_year) {
  valid_vars <- list_cru_ts_variables()$variable
  if (!variable %in% valid_vars) {
    stop(sprintf(
      "'%s' is not a valid CRU TS variable.\nAvailable variables: %s\nSee list_cru_ts_variables() for details.",
      variable, paste(valid_vars, collapse = ", ")
    ))
  }
  if (start_year < .CRU_TS_YEAR_START || end_year > .CRU_TS_YEAR_END) {
    stop(sprintf(
      "CRU TS v%s covers %d-%d. Requested: %d-%d.",
      .CRU_TS_VERSION, .CRU_TS_YEAR_START, .CRU_TS_YEAR_END, start_year, end_year
    ))
  }
  if (start_year > end_year) stop("start_year must be <= end_year")
}

#' Fetch CRU TS data for a variable and year range
#' @keywords internal
.fetch_cru_ts <- function(variable, start_year, end_year, use_cache, output_dir) {
  decades <- .cru_ts_needed_decades(start_year, end_year)

  all_data <- lapply(decades, function(d) {
    .download_cru_ts_decade(variable, d[1], d[2], output_dir, use_cache)
  })

  result <- do.call(rbind, all_data)
  result <- result[result$year >= start_year & result$year <= end_year, ]
  rownames(result) <- NULL
  result
}

#' Download CRU TS climate data for a bounding box
#'
#' Downloads and filters CRU TS v4.07 monthly gridded climate data to a
#' geographic bounding box. Data covers global land areas at 0.5 degree
#' resolution, 1901-2022.
#'
#' @param variable CRU TS variable code. See [list_cru_ts_variables()].
#'   Common values: "tmp" (mean temperature), "pre" (precipitation),
#'   "tmx" (max temperature), "tmn" (min temperature).
#' @param start_year Start year (1901-2022).
#' @param end_year End year (1901-2022).
#' @param north Northern latitude boundary.
#' @param south Southern latitude boundary.
#' @param east Eastern longitude boundary.
#' @param west Western longitude boundary.
#' @param output_dir Directory for temporary files (default: `tempdir()`).
#' @param use_cache Whether to use cached data (default: TRUE).
#' @param ... Arguments passed to the main function (used by aliases).
#' @return data.frame with columns: year, month, latitude, longitude,
#'   value, variable.
#' @export
#' @examples
#' \dontrun{
#' # Monthly mean temperature for India 2010-2020
#' data <- cru_ts_bbox(
#'   variable = "tmp",
#'   start_year = 2010, end_year = 2020,
#'   north = 35, south = 8, east = 97, west = 68
#' )
#'
#' # Precipitation for Europe 1981-2010
#' data <- cru_ts_bbox(
#'   variable = "pre",
#'   start_year = 1981, end_year = 2010,
#'   north = 71, south = 36, east = 40, west = -10
#' )
#' }
cru_ts_bbox <- function(variable, start_year, end_year,
                        north, south, east, west,
                        output_dir = tempdir(), use_cache = TRUE, ...) {
  .validate_cru_ts_inputs(variable, start_year, end_year)
  if (!validate_bbox(north, south, east, west)) stop("Invalid bounding box coordinates")

  message("=== CRU TS Download and Processing ===")
  message(sprintf("Variable: %s | Years: %d-%d", variable, start_year, end_year))
  message(sprintf("Bounding box: N:%s S:%s E:%s W:%s", north, south, east, west))

  ensure_output_dir(output_dir)

  data <- .fetch_cru_ts(variable, start_year, end_year, use_cache, output_dir)

  data <- data[
    data$latitude >= south & data$latitude <= north &
      data$longitude >= west & data$longitude <= east,
  ]
  rownames(data) <- NULL

  message(sprintf("Filtered to %d data points.", nrow(data)))
  data
}

#' Download CRU TS climate data for a GeoJSON region
#'
#' Downloads and filters CRU TS v4.07 monthly gridded climate data to a
#' geographic region defined by a GeoJSON polygon.
#'
#' @param variable CRU TS variable code. See [list_cru_ts_variables()].
#' @param start_year Start year (1901-2022).
#' @param end_year End year (1901-2022).
#' @param geojson_file Path to a GeoJSON file defining the region.
#' @param output_dir Directory for temporary files (default: `tempdir()`).
#' @param use_cache Whether to use cached data (default: TRUE).
#' @param ... Arguments passed to the main function (used by aliases).
#' @return data.frame with columns: year, month, latitude, longitude,
#'   value, variable.
#' @export
#' @examples
#' \dontrun{
#' data <- cru_ts_geojson(
#'   variable = "tmp",
#'   start_year = 1981, end_year = 2010,
#'   geojson_file = "india.geojson"
#' )
#' }
cru_ts_geojson <- function(variable, start_year, end_year, geojson_file,
                           output_dir = tempdir(), use_cache = TRUE, ...) {
  .validate_cru_ts_inputs(variable, start_year, end_year)
  if (!file.exists(geojson_file)) stop("GeoJSON file not found: ", geojson_file)

  message("=== CRU TS Download and Processing ===")
  message(sprintf("Variable: %s | Years: %d-%d", variable, start_year, end_year))
  message(sprintf("GeoJSON: %s", basename(geojson_file)))

  ensure_output_dir(output_dir)

  data <- .fetch_cru_ts(variable, start_year, end_year, use_cache, output_dir)

  # Coarse bbox pre-filter
  region_sf <- sf::st_read(geojson_file, quiet = TRUE)
  bbox <- sf::st_bbox(region_sf)
  data <- data[
    data$latitude >= bbox[["ymin"]] & data$latitude <= bbox[["ymax"]] &
      data$longitude >= bbox[["xmin"]] & data$longitude <= bbox[["xmax"]],
  ]

  if (nrow(data) > 0) {
    data <- filter_dataframe_by_geojson(data, geojson_file)
  }

  rownames(data) <- NULL
  message(sprintf("Filtered to %d data points.", nrow(data)))
  data
}
