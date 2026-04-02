#' HadEX3 Climate Extremes Dataset
#'
#' Functions to download and process the Met Office HadEX3 global climate
#' extremes dataset based on ETCCDI indices.
#'
#' @references
#' Dunn et al. (2020) Development of an updated global land in-situ-based dataset
#' of temperature and precipitation extremes: HadEX3. J. Geophys. Res. Atmos.
#' https://doi.org/10.1029/2019JD032263
#' @name hadex3

# Annual indices (baseline period determines availability of some)
.HADEX3_ANNUAL_INDICES <- c(
  "TXx", "TXn", "TNx", "TNn",
  "TX90p", "TX10p", "TN90p", "TN10p",
  "TR", "SU", "FD", "ID",
  "CSDI", "WSDI", "DTR", "GSL", "ETR",
  "CDD", "CWD", "PRCPTOT", "R10mm", "R20mm",
  "Rx1day", "Rx5day", "R95p", "R99p",
  "R95pTOT", "R99pTOT", "SDII"
)

# Monthly indices (subset of annual)
.HADEX3_MONTHLY_INDICES <- c(
  "TXx", "TXn", "TNx", "TNn",
  "TX90p", "TX10p", "TN90p", "TN10p",
  "TR", "SU", "FD", "ID",
  "DTR", "ETR",
  "PRCPTOT", "Rx1day", "Rx5day", "SDII"
)

# Indices that support the 1981-2010 baseline
.HADEX3_81_10_INDICES <- c(
  "TX90p", "TX10p", "TN90p", "TN10p",
  "CSDI", "WSDI", "R95p", "R99p", "R95pTOT", "R99pTOT"
)

.HADEX3_BASE_URL <- "http://www.metoffice.gov.uk/hadobs/hadex3/data"
.HADEX3_YEAR_START <- 1901L
.HADEX3_YEAR_END <- 2018L

#' Build HadEX3 download URL
#' @param index ETCCDI index name (e.g. "TXx").
#' @param frequency "annual" or "monthly".
#' @param baseline Baseline period: "61-90" or "81-10" (annual only).
#' @return Character URL.
#' @keywords internal
.hadex3_url <- function(index, frequency, baseline = "61-90") {
  if (frequency == "monthly") {
    sprintf("%s/HadEX3_%s_MON.nc.gz", .HADEX3_BASE_URL, index)
  } else {
    sprintf(
      "%s/HadEX3_%s_1901-2018_ADW_%s_1.25x1.875deg.nc.gz",
      .HADEX3_BASE_URL, index, baseline
    )
  }
}

#' Download and decompress a HadEX3 NetCDF file
#' @param index ETCCDI index name.
#' @param frequency "annual" or "monthly".
#' @param baseline Baseline period for annual data.
#' @param output_dir Directory for temporary files.
#' @return Path to decompressed .nc file.
#' @keywords internal
.download_hadex3_file <- function(index, frequency, baseline, output_dir) {
  url <- .hadex3_url(index, frequency, baseline)
  gz_file <- file.path(output_dir, basename(url))
  nc_file <- sub("\\.gz$", "", gz_file)

  message(sprintf("Downloading HadEX3 %s (%s) from Met Office...", index, frequency))
  message(sprintf("URL: %s", url))

  response <- tryCatch(
    httr::GET(url, httr::timeout(600), httr::write_disk(gz_file, overwrite = TRUE)),
    error = function(e) stop("Download failed: ", e$message)
  )

  if (httr::status_code(response) != 200) {
    stop(sprintf(
      "HTTP %d downloading HadEX3 %s. Check that '%s' is a valid index for '%s' frequency.",
      httr::status_code(response), index, index, frequency
    ))
  }

  if (!file.exists(gz_file) || file.size(gz_file) == 0) {
    stop("Downloaded file is empty or missing.")
  }

  message("Decompressing...")
  .decompress_gz(gz_file, nc_file)
  unlink(gz_file)

  nc_file
}

#' Decompress a .gz file
#' @keywords internal
.decompress_gz <- function(gz_file, dest_file) {
  if (requireNamespace("R.utils", quietly = TRUE)) {
    R.utils::gunzip(gz_file, destname = dest_file, overwrite = TRUE, remove = FALSE)
  } else {
    con_in <- gzfile(gz_file, "rb")
    on.exit(close(con_in), add = TRUE)
    con_out <- file(dest_file, "wb")
    on.exit(close(con_out), add = TRUE)
    repeat {
      chunk <- readBin(con_in, "raw", n = 65536L)
      if (length(chunk) == 0L) break
      writeBin(chunk, con_out)
    }
  }
  dest_file
}

#' Read a HadEX3 NetCDF file into a data.frame
#'
#' HadEX3 NetCDF files use dimension names "longitude"/"latitude" (not "lon"/"lat"),
#' longitudes in 0-360 range, and variable name "Ann" for annual files vs. the
#' index name (e.g. "TXx") for monthly files. All files have dims (longitude, latitude, time).
#'
#' @param nc_file Path to decompressed .nc file.
#' @param index ETCCDI index name.
#' @param frequency "annual" or "monthly".
#' @return data.frame with columns year (+ month for monthly), latitude, longitude, value.
#' @keywords internal
.read_hadex3_nc <- function(nc_file, index, frequency) {
  nc <- ncdf4::nc_open(nc_file)
  on.exit(ncdf4::nc_close(nc), add = TRUE)

  lat <- ncdf4::ncvar_get(nc, "latitude")
  lon_raw <- ncdf4::ncvar_get(nc, "longitude")
  # Convert 0-360 to -180-180
  lon <- ifelse(lon_raw > 180, lon_raw - 360, lon_raw)

  # Annual files use "Ann"; monthly files use the index name
  var_name <- if (frequency == "annual") "Ann" else index
  if (!var_name %in% names(nc$var)) {
    available <- names(nc$var)
    stop(sprintf(
      "Variable '%s' not found in NetCDF. Available: %s",
      var_name, paste(available, collapse = ", ")
    ))
  }

  vals <- ncdf4::ncvar_get(nc, var_name)
  fill_val <- ncdf4::ncatt_get(nc, var_name, "_FillValue")$value

  time_var <- ncdf4::ncvar_get(nc, "time")
  time_units <- ncdf4::ncatt_get(nc, "time", "units")$value

  if (frequency == "annual") {
    years <- .parse_hadex3_years(time_var, time_units)
    result <- .expand_hadex3_annual(vals, lat, lon, years, fill_val)
  } else {
    year_months <- .parse_hadex3_months(time_var, time_units)
    result <- .expand_hadex3_monthly(vals, lat, lon, year_months, fill_val)
  }

  result$index <- index
  result
}

#' Parse year values from annual HadEX3 time coordinate
#'
#' HadEX3 annual files use units "years" (plain integers 1901-2018).
#' @keywords internal
.parse_hadex3_years <- function(time_var, time_units) {
  if (grepl("^years$", trimws(time_units), ignore.case = TRUE)) {
    # Plain integer years (e.g. 1901, 1902, ...)
    as.integer(round(time_var))
  } else if (grepl("years since", time_units, ignore.case = TRUE)) {
    base_year <- as.integer(sub(".*since\\s+(\\d{4}).*", "\\1", time_units))
    as.integer(base_year + round(time_var))
  } else if (grepl("days since", time_units, ignore.case = TRUE)) {
    base_date <- as.Date(sub("days since ", "", trimws(time_units)))
    dates <- base_date + time_var
    as.integer(format(dates, "%Y"))
  } else {
    as.integer(round(time_var))
  }
}

#' Parse year+month from monthly HadEX3 time coordinate
#' @keywords internal
.parse_hadex3_months <- function(time_var, time_units) {
  if (grepl("months since", time_units, ignore.case = TRUE)) {
    base_match <- regmatches(time_units, regexpr("\\d{4}-\\d{2}", time_units))
    base_year <- as.integer(substr(base_match, 1, 4))
    base_month <- as.integer(substr(base_match, 6, 7))
    total_months <- base_year * 12L + (base_month - 1L) + as.integer(round(time_var))
    data.frame(year = total_months %/% 12L, month = total_months %% 12L + 1L)
  } else if (grepl("days since", time_units, ignore.case = TRUE)) {
    base_date <- as.Date(sub("days since ", "", time_units))
    dates <- base_date + time_var
    data.frame(
      year = as.integer(format(dates, "%Y")),
      month = as.integer(format(dates, "%m"))
    )
  } else {
    stop("Unrecognised time units in monthly HadEX3 file: ", time_units)
  }
}

#' Expand annual NetCDF array to data.frame
#' @keywords internal
.expand_hadex3_annual <- function(vals, lat, lon, years, fill_val) {
  n_lon <- length(lon)
  n_lat <- length(lat)
  n_time <- length(years)

  grid <- expand.grid(
    lon_idx = seq_len(n_lon),
    lat_idx = seq_len(n_lat),
    time_idx = seq_len(n_time),
    KEEP.OUT.ATTRS = FALSE
  )

  grid$value <- vals[cbind(grid$lon_idx, grid$lat_idx, grid$time_idx)]
  grid$longitude <- lon[grid$lon_idx]
  grid$latitude <- lat[grid$lat_idx]
  grid$year <- years[grid$time_idx]

  result <- grid[, c("year", "latitude", "longitude", "value")]
  result <- result[!is.na(result$value), ]
  if (!is.null(fill_val) && is.numeric(fill_val)) {
    result <- result[abs(result$value - fill_val) > 1e-6, ]
  }
  rownames(result) <- NULL
  result
}

#' Expand monthly NetCDF array to data.frame
#' @keywords internal
.expand_hadex3_monthly <- function(vals, lat, lon, year_months, fill_val) {
  n_lon <- length(lon)
  n_lat <- length(lat)
  n_time <- nrow(year_months)

  grid <- expand.grid(
    lon_idx = seq_len(n_lon),
    lat_idx = seq_len(n_lat),
    time_idx = seq_len(n_time),
    KEEP.OUT.ATTRS = FALSE
  )

  grid$value <- vals[cbind(grid$lon_idx, grid$lat_idx, grid$time_idx)]
  grid$longitude <- lon[grid$lon_idx]
  grid$latitude <- lat[grid$lat_idx]
  grid$year <- year_months$year[grid$time_idx]
  grid$month <- year_months$month[grid$time_idx]

  result <- grid[, c("year", "month", "latitude", "longitude", "value")]
  result <- result[!is.na(result$value), ]
  if (!is.null(fill_val) && is.numeric(fill_val)) {
    result <- result[abs(result$value - fill_val) > 1e-6, ]
  }
  rownames(result) <- NULL
  result
}

#' Validate HadEX3 inputs
#' @keywords internal
.validate_hadex3_inputs <- function(index, frequency, baseline, start_year, end_year) {
  frequency <- match.arg(frequency, c("annual", "monthly"))

  valid_indices <- if (frequency == "monthly") .HADEX3_MONTHLY_INDICES else .HADEX3_ANNUAL_INDICES
  if (!index %in% valid_indices) {
    stop(sprintf(
      "'%s' is not available for %s data.\nAvailable %s indices: %s",
      index, frequency, frequency, paste(valid_indices, collapse = ", ")
    ))
  }

  if (frequency == "annual") {
    baseline <- match.arg(baseline, c("61-90", "81-10"))
    if (baseline == "81-10" && !index %in% .HADEX3_81_10_INDICES) {
      stop(sprintf(
        "Baseline '81-10' is only available for: %s",
        paste(.HADEX3_81_10_INDICES, collapse = ", ")
      ))
    }
  }

  if (start_year < .HADEX3_YEAR_START || end_year > .HADEX3_YEAR_END) {
    stop(sprintf(
      "HadEX3 data covers %d-%d. Requested: %d-%d.",
      .HADEX3_YEAR_START, .HADEX3_YEAR_END, start_year, end_year
    ))
  }
  if (start_year > end_year) stop("start_year must be <= end_year")

  frequency
}

#' Fetch HadEX3 index data (with caching)
#' @keywords internal
.fetch_hadex3 <- function(index, frequency, baseline, use_cache, output_dir) {
  cache_key <- digest::digest(
    list(source = "hadex3", index = index, frequency = frequency, baseline = baseline),
    algo = "md5"
  )

  if (use_cache) {
    cached <- check_cache(cache_key)
    if (!is.null(cached)) {
      message(sprintf("Loading HadEX3 %s (%s) from cache.", index, frequency))
      return(readRDS(cached))
    }
  }

  nc_file <- .download_hadex3_file(index, frequency, baseline, output_dir)
  on.exit(unlink(nc_file), add = TRUE)

  message("Reading NetCDF data...")
  data <- .read_hadex3_nc(nc_file, index, frequency)
  message(sprintf("Read %d global grid points.", nrow(data)))

  if (use_cache) {
    rds_file <- tempfile(fileext = ".rds")
    saveRDS(data, rds_file)
    tryCatch(
      save_to_cache(rds_file, cache_key),
      error = function(e) warning("Could not cache HadEX3 data: ", e$message, call. = FALSE)
    )
    unlink(rds_file)
  }

  data
}

#' Download HadEX3 climate extremes data for a bounding box
#'
#' Downloads and filters HadEX3 ETCCDI climate extremes data to a geographic
#' bounding box. Data covers 1901-2018 at 1.25 x 1.875 degree resolution.
#'
#' @param index ETCCDI index name (e.g. "TXx", "Rx1day"). See [list_hadex3_indices()].
#' @param start_year Start year (1901-2018).
#' @param end_year End year (1901-2018).
#' @param north Northern latitude boundary.
#' @param south Southern latitude boundary.
#' @param east Eastern longitude boundary.
#' @param west Western longitude boundary.
#' @param frequency Temporal frequency: "annual" or "monthly" (default: "annual").
#' @param baseline Reference period for percentile-based indices: "61-90" (default)
#'   or "81-10". Only applies to annual frequency.
#' @param output_dir Directory for temporary files (default: `tempdir()`).
#' @param use_cache Whether to use cached data (default: TRUE).
#' @param ... Arguments passed to the main function (used by aliases).
#' @return data.frame with columns: year (+ month for monthly), latitude,
#'   longitude, value, index.
#' @export
#' @examples
#' \dontrun{
#' # Annual maximum daily maximum temperature for Europe 1981-2010
#' data <- hadex3_bbox(
#'   index = "TXx",
#'   start_year = 1981, end_year = 2010,
#'   north = 71, south = 36, east = 40, west = -10
#' )
#'
#' # Monthly Rx1day for India
#' data <- hadex3_bbox(
#'   index = "Rx1day",
#'   start_year = 2000, end_year = 2018,
#'   north = 35, south = 8, east = 97, west = 68,
#'   frequency = "monthly"
#' )
#' }
hadex3_bbox <- function(index, start_year, end_year,
                        north, south, east, west,
                        frequency = "annual", baseline = "61-90",
                        output_dir = tempdir(), use_cache = TRUE) {
  frequency <- .validate_hadex3_inputs(index, frequency, baseline, start_year, end_year)

  if (!validate_bbox(north, south, east, west)) stop("Invalid bounding box coordinates")

  message("=== HadEX3 Download and Processing ===")
  message(sprintf("Index: %s | Frequency: %s | Years: %d-%d", index, frequency, start_year, end_year))
  message(sprintf("Bounding box: N:%s S:%s E:%s W:%s", north, south, east, west))

  ensure_output_dir(output_dir)

  data <- .fetch_hadex3(index, frequency, baseline, use_cache, output_dir)

  data <- data[data$year >= start_year & data$year <= end_year, ]
  data <- data[
    data$latitude >= south & data$latitude <= north &
      data$longitude >= west & data$longitude <= east,
  ]
  rownames(data) <- NULL

  message(sprintf("Filtered to %d data points.", nrow(data)))
  data
}

#' Download HadEX3 climate extremes data for a GeoJSON region
#'
#' Downloads and filters HadEX3 ETCCDI climate extremes data to a geographic
#' region defined by a GeoJSON polygon.
#'
#' @param index ETCCDI index name (e.g. "TXx", "Rx1day"). See [list_hadex3_indices()].
#' @param start_year Start year (1901-2018).
#' @param end_year End year (1901-2018).
#' @param geojson_file Path to a GeoJSON file defining the region.
#' @param frequency Temporal frequency: "annual" or "monthly" (default: "annual").
#' @param baseline Reference period for percentile-based indices: "61-90" (default)
#'   or "81-10". Only applies to annual frequency.
#' @param output_dir Directory for temporary files (default: `tempdir()`).
#' @param use_cache Whether to use cached data (default: TRUE).
#' @param ... Arguments passed to the main function (used by aliases).
#' @return data.frame with columns: year (+ month for monthly), latitude,
#'   longitude, value, index.
#' @export
#' @examples
#' \dontrun{
#' data <- hadex3_geojson(
#'   index = "TXx",
#'   start_year = 1981, end_year = 2010,
#'   geojson_file = "india.geojson"
#' )
#' }
hadex3_geojson <- function(index, start_year, end_year, geojson_file,
                           frequency = "annual", baseline = "61-90",
                           output_dir = tempdir(), use_cache = TRUE) {
  frequency <- .validate_hadex3_inputs(index, frequency, baseline, start_year, end_year)

  if (!file.exists(geojson_file)) stop("GeoJSON file not found: ", geojson_file)

  message("=== HadEX3 Download and Processing ===")
  message(sprintf("Index: %s | Frequency: %s | Years: %d-%d", index, frequency, start_year, end_year))
  message(sprintf("GeoJSON: %s", basename(geojson_file)))

  ensure_output_dir(output_dir)

  data <- .fetch_hadex3(index, frequency, baseline, use_cache, output_dir)

  data <- data[data$year >= start_year & data$year <= end_year, ]

  # Coarse bbox pre-filter before precise polygon test
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

#' List available HadEX3 ETCCDI indices
#'
#' Returns a data.frame describing all ETCCDI climate extremes indices
#' available in the HadEX3 dataset, including their temporal availability
#' and physical interpretation.
#'
#' @param frequency Filter by frequency: "annual", "monthly", or "all" (default).
#' @param ... Arguments passed to the main function (used by aliases).
#' @return data.frame with columns: index, category, description, unit,
#'   annual, monthly.
#' @export
#' @examples
#' list_hadex3_indices()
#' list_hadex3_indices(frequency = "monthly")
list_hadex3_indices <- function(frequency = "all") {
  frequency <- match.arg(frequency, c("all", "annual", "monthly"))

  indices <- data.frame(
    index = c(
      "TXx", "TXn", "TNx", "TNn",
      "TX90p", "TX10p", "TN90p", "TN10p",
      "TR", "SU", "FD", "ID",
      "CSDI", "WSDI", "DTR", "GSL", "ETR",
      "CDD", "CWD", "PRCPTOT", "R10mm", "R20mm",
      "Rx1day", "Rx5day", "R95p", "R99p",
      "R95pTOT", "R99pTOT", "SDII"
    ),
    category = c(
      rep("Temperature", 4L),
      rep("Temperature percentile", 4L),
      rep("Temperature threshold", 4L),
      rep("Temperature duration", 3L),
      "Temperature", "Temperature",
      rep("Precipitation", 10L),
      rep("Precipitation", 2L)
    ),
    description = c(
      "Max of daily max temp (hottest day)",
      "Min of daily max temp (coldest day)",
      "Max of daily min temp (warmest night)",
      "Min of daily min temp (coldest night)",
      "% days with TX > 90th percentile",
      "% days with TX < 10th percentile",
      "% days with TN > 90th percentile",
      "% days with TN < 10th percentile",
      "Tropical nights (TN > 20\u00b0C)",
      "Summer days (TX > 25\u00b0C)",
      "Frost days (TN < 0\u00b0C)",
      "Ice days (TX < 0\u00b0C)",
      "Cold spell duration index",
      "Warm spell duration index",
      "Diurnal temperature range (TX-TN)",
      "Growing season length",
      "Intra-annual extreme temperature range",
      "Consecutive dry days (P < 1 mm)",
      "Consecutive wet days (P >= 1 mm)",
      "Total wet-day precipitation",
      "Heavy precipitation days (P >= 10 mm)",
      "Very heavy precipitation days (P >= 20 mm)",
      "Max 1-day precipitation",
      "Max 5-day precipitation",
      "Precipitation > 95th percentile total",
      "Precipitation > 99th percentile total",
      "Fraction of total from R95p days",
      "Fraction of total from R99p days",
      "Simple daily intensity index"
    ),
    unit = c(
      rep("\u00b0C", 4L),
      rep("%", 4L),
      "days", "days", "days", "days",
      "days", "days", "\u00b0C", "days", "\u00b0C",
      "days", "days", "mm", "days", "days",
      "mm", "mm", "mm", "mm",
      "%", "%",
      "mm/day"
    ),
    annual = TRUE,
    monthly = c(
      TRUE, TRUE, TRUE, TRUE,
      TRUE, TRUE, TRUE, TRUE,
      TRUE, TRUE, TRUE, TRUE,
      FALSE, FALSE, TRUE, FALSE, TRUE,
      FALSE, FALSE, TRUE, FALSE, FALSE,
      TRUE, TRUE, FALSE, FALSE,
      FALSE, FALSE, TRUE
    ),
    stringsAsFactors = FALSE
  )

  if (frequency == "annual") {
    indices <- indices[indices$annual, ]
  } else if (frequency == "monthly") {
    indices <- indices[indices$monthly, ]
  }

  indices
}
