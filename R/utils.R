#' Utility functions for Varunayan R package
#'
#' @name varunayan-utils
#' @importFrom stats aggregate as.formula complete.cases setNames
#' @importFrom utils setTxtProgressBar txtProgressBar write.csv
#' @importFrom graphics grid
NULL

# Suppress R CMD check NOTEs for dplyr NSE variables
utils::globalVariables(c(
  ".", "..value_col", "datetime", "latitude", "longitude",
  "time_group", "time_idx", "value", "variable"
))

# Package environment for timing data
.varunayan_env <- new.env(parent = emptyenv())
.varunayan_env$timings <- list()

#' Check if data is valid GeoJSON
#' @param data List or data structure to check
#' @return Logical indicating if data is valid GeoJSON
is_valid_geojson <- function(data) {
  is.list(data) && "type" %in% names(data) &&
    data$type %in% c(
      "Feature", "FeatureCollection", "Polygon", "MultiPolygon",
      "Point", "MultiPoint", "LineString", "MultiLineString", "GeometryCollection"
    )
}

#' Convert data to GeoJSON format
#' @param data Data to convert (must be data.frame with lon/lat columns)
#' @return GeoJSON formatted data
convert_to_geojson <- function(data) {
  if (!is.data.frame(data) || !all(c("lon", "lat") %in% names(data))) {
    stop("Cannot convert data to GeoJSON format")
  }
  features <- lapply(seq_len(length.out = nrow(x = data)), function(i) {
    list(
      type = "Feature",
      geometry = list(type = "Point", coordinates = c(data$lon[i], data$lat[i])),
      properties = as.list(data[i, !names(data) %in% c("lon", "lat")])
    )
  })
  list(type = "FeatureCollection", features = features)
}

#' Create GeoJSON from bounding box coordinates
#' @param north Northern latitude
#' @param south Southern latitude
#' @param east Eastern longitude
#' @param west Western longitude
#' @return GeoJSON object representing the bounding box
create_geojson_from_bbox <- function(north, south, east, west) {
  list(
    type = "Feature",
    geometry = list(
      type = "Polygon",
      coordinates = list(list(c(west, south), c(east, south), c(east, north), c(west, north), c(west, south)))
    ),
    properties = list()
  )
}

#' Create temporary GeoJSON file
#' @param geojson_data GeoJSON data to write
#' @param request_id Request identifier for unique filename
#' @return Path to temporary GeoJSON file
create_temp_geojson_file <- function(geojson_data, request_id) {
  temp_file <- file.path(tempdir(), sprintf(fmt = "varunayan_%s_%s.geojson", request_id, format(Sys.time(), "%Y%m%d_%H%M%S")))
  write_json(geojson_data, temp_file, pretty = TRUE, auto_unbox = TRUE)
  temp_file
}

#' Parse date string flexibly
#' @param date_string Character string in various date formats
#' @return Date object
parse_date_flexible <- function(date_string) {
  tryCatch(as.Date(x = date_string, format = "%Y-%m-%d"),
    error = function(e) {
      tryCatch(ymd(date_string),
        error = function(e) stop("Date '", date_string, "' must be in YYYY-MM-DD format")
      )
    }
  )
}

#' Get bounding box from sf object
#' @param sf_obj sf object
#' @return Named numeric vector with xmin, ymin, xmax, ymax
get_bbox_from_sf <- function(sf_obj) {
  bbox <- st_bbox(sf_obj)
  c(
    xmin = as.numeric(x = bbox["xmin"]), ymin = as.numeric(x = bbox["ymin"]),
    xmax = as.numeric(x = bbox["xmax"]), ymax = as.numeric(x = bbox["ymax"])
  )
}

#' Validate geographic coordinates
#' @param lat Latitude value
#' @param lon Longitude value
#' @return Logical indicating if coordinates are valid
validate_coordinates <- function(lat, lon) {
  !is.na(lat) && !is.na(lon) && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180
}

#' Validate bounding box coordinates
#' @param north Northern boundary
#' @param south Southern boundary
#' @param east Eastern boundary
#' @param west Western boundary
#' @return Logical indicating if bounding box is valid
validate_bbox <- function(north, south, east, west) {
  validate_coordinates(north, east) && validate_coordinates(south, west) &&
    north > south && east > west
}

#' Convert pressure levels to character format required by CDS API
#' @param pressure_levels Numeric or character vector of pressure levels
#' @return Character vector of pressure levels
format_pressure_levels <- function(pressure_levels) {
  if (is.null(pressure_levels)) {
    return(NULL)
  }

  pressure_char <- as.character(x = pressure_levels)
  valid_levels <- get_available_pressure_levels()
  invalid <- pressure_char[!pressure_char %in% valid_levels]

  if (length(x = invalid) > 0) {
    warning("Invalid pressure levels: ", paste(invalid, collapse = ", "), call. = FALSE)
  }
  pressure_char
}

#' Format date range for CDS API requests
#' @param start_date Start date (Date object)
#' @param end_date End date (Date object)
#' @return Character vector of date strings in YYYY-MM-DD format
format_date_range <- function(start_date, end_date) {
  format(seq(from = start_date, to = end_date, by = "day"), "%Y-%m-%d")
}

#' Get time values based on frequency
#' @param frequency Character string indicating temporal frequency
#' @return Character vector of time strings
get_time_values <- function(frequency) {
  switch(frequency,
    "hourly" = sprintf(fmt = "%02d:00", 0:23),
    "daily" = "12:00",
    "monthly" = "12:00",
    sprintf(fmt = "%02d:00", 0:23)
  )
}

#' Create output directory if it doesn't exist
#' @param output_dir Path to output directory
#' @return Character string path to created/existing directory
ensure_output_dir <- function(output_dir) {
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    message("Created output directory: ", output_dir)
  }
  output_dir
}

#' Clean up temporary files matching pattern
#' @param pattern Regular expression pattern to match files
#' @param directory Directory to search (default: tempdir())
#' @return Number of files removed
cleanup_temp_files <- function(pattern = "varunayan_.*", directory = tempdir()) {
  temp_files <- list.files(directory, pattern = pattern, full.names = TRUE)
  if (length(x = temp_files) > 0) {
    unlink(temp_files)
    message("Cleaned up ", length(x = temp_files), " temporary files")
  }
  length(x = temp_files)
}

#' Get package version information
#' @param ... Arguments passed to the main function (used by aliases).
#' @return data.frame with package versions (invisible)
#' @export
get_package_info <- function() {
  pkg_info <- sessionInfo()
  message("varunayan Package Information")
  message("R version: ", pkg_info$R.version$version.string)
  message("Platform: ", pkg_info$platform)

  key_packages <- c("ecmwfr", "sf", "stars", "ncdf4", "ncmeta")
  for (pkg in key_packages) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      message(pkg, ": ", packageVersion(pkg))
    } else {
      message(pkg, ": NOT INSTALLED")
    }
  }
  invisible(pkg_info)
}

#' Check system readiness for varunayan operations
#'
#' @param verbose Whether to print detailed information
#' @param ... Arguments passed to the main function (used by aliases).
#' @return Logical indicating if system is ready (invisible)
#' @export
check_system_readiness <- function(verbose = TRUE) {
  if (verbose) message("Checking system readiness...")

  issues <- character()

  for (pkg in c("ecmwfr", "sf", "stars", "ncdf4", "ncmeta")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      issues <- c(issues, paste("Package", pkg, "not available"))
    } else if (verbose) {
      message(pkg, ": OK")
    }
  }

  network_ok <- tryCatch(
    {
      con <- url("https://httpbin.org/status/200", open = "rb")
      close(con)
      TRUE
    },
    error = function(e) FALSE
  )

  if (!network_ok) {
    issues <- c(issues, "Network connectivity issue")
  } else if (verbose) {
    message("Network: OK")
  }

  # Check CDS credentials
  if (!get_cds_credentials(silent = !verbose)) {
    issues <- c(issues, "CDS API credentials not configured")
  }

  if (length(x = issues) == 0) {
    if (verbose) message("System ready!")
    return(invisible(TRUE))
  } else {
    if (verbose) {
      warning("Issues found:", call. = FALSE)
      for (issue in issues) message("  - ", issue)
    }
    return(invisible(FALSE))
  }
}


#' Time an operation and log the duration
#'
#' @param expr Expression to time
#' @param label Label for the operation
#' @param verbose Whether to print timing info (default: TRUE)
#' @return Result of the expression
#' @export
time_operation <- function(expr, label, verbose = TRUE) {
  start <- Sys.time()
  if (verbose) message("[TIMER] Starting: ", label)

  result <- force(expr)

  elapsed <- as.numeric(x = difftime(Sys.time(), start, units = "secs"))
  if (verbose) {
    time_str <- if (elapsed < 1) {
      paste0(round(elapsed * 1000, 1), " ms")
    } else if (elapsed < 60) {
      paste0(round(elapsed, 2), " sec")
    } else {
      paste0(floor(elapsed / 60), "m ", round(elapsed %% 60, 1), "s")
    }
    message("[TIMER] ", label, ": ", time_str)
  }

  .varunayan_env$timings[[length(x = .varunayan_env$timings) + 1]] <- list(
    label = label, elapsed = elapsed, timestamp = Sys.time()
  )
  result
}

#' Get all recorded timings
#' @return data.frame with timing information
#' @export
get_timings <- function() {
  timings <- .varunayan_env$timings
  if (length(x = timings) == 0) {
    message("No timing data recorded")
    return(data.frame(label = character(), elapsed_seconds = numeric(), timestamp = character()))
  }

  df <- data.frame(
    label = sapply(timings, `[[`, "label"),
    elapsed_seconds = sapply(timings, `[[`, "elapsed"),
    timestamp = sapply(timings, function(x) format(x$timestamp, "%Y-%m-%d %H:%M:%S")),
    stringsAsFactors = FALSE
  )
  df$duration <- sapply(df$elapsed_seconds, function(s) {
    if (s < 1) {
      sprintf(fmt = "%.1f ms", s * 1000)
    } else if (s < 60) {
      sprintf(fmt = "%.2f sec", s)
    } else {
      sprintf(fmt = "%dm %.1fs", floor(s / 60), s %% 60)
    }
  })
  df
}

#' Clear all timing data
#' @export
clear_timings <- function() {
  .varunayan_env$timings <- list()
  message("Timing data cleared")
}

#' Print timing summary
#' @export
print_timing_summary <- function() {
  df <- get_timings()
  if (nrow(x = df) == 0) {
    message("No timing data to display")
    return(invisible(NULL))
  }

  message("\n=== Performance Timing Summary ===\n")
  message("Total operations: ", nrow(x = df))
  message("Total time: ", round(sum(df$elapsed_seconds), 2), " seconds\n")

  df <- df[order(-df$elapsed_seconds), ]
  message("Operations (slowest first):")
  for (i in seq_len(length.out = nrow(x = df))) {
    pct <- round(100 * df$elapsed_seconds[i] / sum(df$elapsed_seconds), 1)
    message(i, ". ", df$label[i], ": ", df$duration[i], " (", pct, "%)")
  }
  invisible(df)
}


#' Read CDS API credentials from ~/.cdsapirc file
#' @param file_path Path to .cdsapirc file (default: "~/.cdsapirc")
#' @return List with credentials or NULL
#' @export
read_cdsapirc <- function(file_path = "~/.cdsapirc") {
  file_path <- path.expand(file_path)
  if (!file.exists(file_path)) {
    return(NULL)
  }

  tryCatch(
    {
      lines <- readLines(file_path, warn = FALSE)
      creds <- list()
      for (line in lines) {
        line <- trimws(x = line)
        if (nchar(line) == 0 || grepl(pattern = "^#", line)) next
        if (grepl(pattern = ":", line)) {
          parts <- strsplit(x = line, split = ":", fixed = TRUE)[[1]]
          if (length(x = parts) >= 2) {
            creds[[trimws(x = parts[1])]] <- trimws(x = paste(parts[-1], collapse = ":"))
          }
        }
      }
      if ("key" %in% names(creds)) creds else NULL
    },
    error = function(e) NULL
  )
}

#' Get CDS API credentials from multiple sources
#'
#' Checks ecmwfr config first, then ~/.cdsapirc
#'
#' @param silent Suppress informational messages
#' @return Logical indicating whether credentials are available
#' @export
get_cds_credentials <- function(silent = FALSE) {
  # Check env var FIRST — allows parallel workers to use different keys
  env_key <- Sys.getenv("CDS_API_KEY", unset = "")
  if (nzchar(env_key)) {
    if (!silent) message("Setting up CDS credentials from CDS_API_KEY environment variable...")
    tryCatch(
      {
        suppressWarnings(wf_set_key(key = env_key))
        if (!silent) message("CDS credentials configured")
        return(TRUE)
      },
      error = function(e) FALSE
    )
  }

  has_creds <- suppressWarnings(tryCatch(
    {
      key <- wf_get_key()
      !is.null(key) && nchar(key) > 0
    },
    error = function(e) FALSE
  ))

  if (has_creds) {
    if (!silent) message("CDS credentials found")
    return(TRUE)
  }

  env_key <- Sys.getenv("CDS_API_KEY", unset = "")
  if (nzchar(env_key)) {
    if (!silent) message("Setting up CDS credentials from CDS_API_KEY environment variable...")
    tryCatch(
      {
        suppressWarnings(wf_set_key(key = env_key))
        if (!silent) message("CDS credentials configured")
        return(TRUE)
      },
      error = function(e) FALSE
    )
  }

  creds <- read_cdsapirc()
  if (!is.null(creds) && "key" %in% names(creds)) {
    if (!silent) message("Setting up CDS credentials from ~/.cdsapirc...")
    tryCatch(
      {
        suppressWarnings(wf_set_key(key = creds$key))
        if (!silent) message("CDS credentials configured")
        return(TRUE)
      },
      error = function(e) FALSE
    )
  }

  if (!silent) {
    warning("No CDS credentials found", call. = FALSE)
    message("Run setup_cds_credentials(key = 'your-api-key')")
  }
  FALSE
}
