#' IMD data download functions
#'
#' Functions for downloading gridded data from India Meteorological Department (IMD)
#' Based on analysis of actual IMD data format.

#' Download IMD gridded rainfall data
#'
#' Downloads daily gridded rainfall data from IMD at specified resolution.
#'
#' @param start_year Start year.
#' @param end_year End year.
#' @param resolution Spatial resolution: 0.25 or 1.0 degrees.
#' @param output_dir Directory to save downloaded files.
#' @param use_cache Whether to use cached data if available (default: TRUE).
#' @return Character vector of downloaded file paths
#' @export
#' @examples
#' \dontrun{
#' # Download 0.25 degree rainfall for 2023-2025
#' files <- download_imd_rainfall(
#'   start_year = 2023,
#'   end_year = 2025,
#'   resolution = 0.25
#' )
#' }
download_imd_rainfall <- function(start_year, end_year, resolution = 0.25, output_dir = tempdir(), use_cache = TRUE) {
  if (start_year < 1901 || end_year > 2024) stop("Rainfall data available for years 1901-2024")
  if (start_year > end_year) stop("Start year must be <= end year")
  if (!resolution %in% c(0.25, 1.0)) stop("Resolution must be 0.25 or 1.0 degrees")


  endpoint <- if (resolution == 0.25) list(php = "RF25.php", param = "RF25") else list(php = "rain.php", param = "rain")

  message(sprintf(fmt = "Downloading IMD rainfall data (resolution: %s\u00B0)", resolution))
  message(sprintf(fmt = "Years: %s to %s", start_year, end_year))

  ensure_output_dir(output_dir)


  years <- start_year:end_year
  cached_years <- c()
  missing_years <- c()

  if (use_cache) {
    message("Checking cache for existing data...")
    for (year in years) {
      cache_key <- generate_cache_key(
        source = "imd",
        start_date = paste0(year, "-01-01"),
        end_date = paste0(year, "-12-31"),
        resolution = resolution,
        var_type = "rainfall"
      )
      cached_file <- check_cache(cache_key)
      if (!is.null(cached_file)) {
        cached_years <- c(cached_years, year)
      } else {
        missing_years <- c(missing_years, year)
      }
    }

    if (length(x = cached_years) > 0) {
      message(sprintf(fmt = "Found %s year(s) in cache: %s", length(x = cached_years), paste(cached_years, collapse = ", ")))
    }
    if (length(x = missing_years) > 0) {
      message(sprintf(fmt = "Need to download %s year(s): %s", length(x = missing_years), paste(missing_years, collapse = ", ")))
    }
  } else {
    missing_years <- years
    message(sprintf(fmt = "Cache disabled. Will download all %s years.", length(x = missing_years)))
  }


  if (length(x = missing_years) > 0) {
    message("Checking IMD server connectivity...")
    if (!check_imd_server()) {
      warning("IMD server (www.imdpune.gov.in) is not responding", call. = FALSE)

      if (length(x = cached_years) == length(x = years)) {
        message("All requested data is cached. Proceeding with cached data only.")
      } else {
        stop(sprintf(fmt = "Server unreachable and %s year(s) not in cache", length(x = missing_years)))
        message("This could be due to:")
        message(paste("  -", c(
          "Server is temporarily down",
          "Network connectivity issues",
          "Firewall/proxy blocking the connection",
          "Server is under maintenance"
        ), collapse = "\n"))
        message("Options:")
        message(paste("  -", c(
          "Try again later when server is available",
          sprintf(fmt = "Request only cached years: %s", paste(cached_years, collapse = ", ")),
          "Use ERA5 data as alternative"
        ), collapse = "\n"))
        stop("Cannot connect to IMD server and some data is not cached")
      }
    } else {
      message("IMD server is reachable")
    }
  } else {
    message("All requested data available in cache. No download needed!")
  }


  files <- vapply(years, function(year) {
    output_file <- file.path(output_dir, sprintf(fmt = "imd_rainfall_%s_%d.nc", resolution, year))


    if (use_cache) {
      cache_key <- generate_cache_key(
        source = "imd",
        start_date = paste0(year, "-01-01"),
        end_date = paste0(year, "-12-31"),
        resolution = resolution,
        var_type = "rainfall"
      )

      cached_file <- check_cache(cache_key)
      if (!is.null(cached_file)) {
        message(sprintf(fmt = "Using cached data for %s: %s", year, basename(path = cached_file)))
        file.copy(cached_file, output_file, overwrite = TRUE)
        return(output_file)
      }
    }

    tryCatch(
      {
        message(sprintf(fmt = "Downloading year %s...", year))
        result <- download_imd_year(
          year, endpoint$php, endpoint$param,
          "https://www.imdpune.gov.in/cmpg/Griddata/", output_file
        )
        message(sprintf(fmt = "Downloaded %s: %s", year, basename(path = result)))


        if (use_cache) {
          tryCatch(
            {
              save_to_cache(result, cache_key)
            },
            error = function(e) {
              warning(sprintf(fmt = "Could not save to cache: %s", e$message), call. = FALSE)
            }
          )
        }

        Sys.sleep(2)
        result
      },
      error = function(e) {
        stop(sprintf(fmt = "Failed to download %s: %s", year, e$message))
        NA_character_
      }
    )
  }, character(1))

  files <- files[!is.na(files)]
  message(sprintf(fmt = "Downloaded %s files", length(x = files)))
  files
}

#' Download IMD gridded temperature data
#'
#' Downloads daily gridded temperature data (max or min) from IMD.
#' Temperature data is at 1.0 degree resolution only.
#'
#' @param start_year Start year.
#' @param end_year End year.
#' @param var_type Type of temperature: "tmax" or "tmin".
#' @param output_dir Directory to save downloaded files.
#' @param use_cache Whether to use cached data if available (default: TRUE).
#' @return Character vector of downloaded file paths
#' @export
#' @examples
#' \dontrun{
#' # Download max temperature for 2023-2025
#' files <- download_imd_temperature(
#'   start_year = 2023,
#'   end_year = 2025,
#'   var_type = "tmax"
#' )
#' }
download_imd_temperature <- function(start_year, end_year, var_type = "tmax", output_dir = tempdir(), use_cache = TRUE) {
  if (start_year < 1951 || end_year > 2024) stop("Temperature data available for years 1951-2024")
  if (start_year > end_year) stop("Start year must be <= end year")
  if (!var_type %in% c("tmax", "tmin")) stop("var_type must be 'tmax' or 'tmin'")


  endpoint <- if (var_type == "tmax") list(php = "maxtemp.php", param = "maxtemp") else list(php = "mintemp.php", param = "mintemp")

  message(sprintf(fmt = "Downloading IMD %s data (resolution: 1.0\u00B0)", var_type))
  message(sprintf(fmt = "Years: %s to %s", start_year, end_year))

  ensure_output_dir(output_dir)


  years <- start_year:end_year
  cached_years <- c()
  missing_years <- c()

  if (use_cache) {
    message("Checking cache for existing data...")
    for (year in years) {
      cache_key <- generate_cache_key(
        source = "imd",
        start_date = paste0(year, "-01-01"),
        end_date = paste0(year, "-12-31"),
        resolution = 1.0,
        var_type = var_type
      )
      cached_file <- check_cache(cache_key)
      if (!is.null(cached_file)) {
        cached_years <- c(cached_years, year)
      } else {
        missing_years <- c(missing_years, year)
      }
    }

    if (length(x = cached_years) > 0) {
      message(sprintf(fmt = "Found %s year(s) in cache: %s", length(x = cached_years), paste(cached_years, collapse = ", ")))
    }
    if (length(x = missing_years) > 0) {
      message(sprintf(fmt = "Need to download %s year(s): %s", length(x = missing_years), paste(missing_years, collapse = ", ")))
    }
  } else {
    missing_years <- years
    message(sprintf(fmt = "Cache disabled. Will download all %s years.", length(x = missing_years)))
  }


  if (length(x = missing_years) > 0) {
    message("Checking IMD server connectivity...")
    if (!check_imd_server()) {
      warning("IMD server (www.imdpune.gov.in) is not responding", call. = FALSE)

      if (length(x = cached_years) == length(x = years)) {
        message("All requested data is cached. Proceeding with cached data only.")
      } else {
        stop(sprintf(fmt = "Server unreachable and %s year(s) not in cache", length(x = missing_years)))
        message("This could be due to:")
        message(paste("  -", c(
          "Server is temporarily down",
          "Network connectivity issues",
          "Firewall/proxy blocking the connection",
          "Server is under maintenance"
        ), collapse = "\n"))
        message("Options:")
        message(paste("  -", c(
          "Try again later when server is available",
          sprintf(fmt = "Request only cached years: %s", paste(cached_years, collapse = ", ")),
          "Use ERA5 data as alternative"
        ), collapse = "\n"))
        stop("Cannot connect to IMD server and some data is not cached")
      }
    } else {
      message("IMD server is reachable")
    }
  } else {
    message("All requested data available in cache. No download needed!")
  }


  files <- vapply(years, function(year) {
    output_file <- file.path(output_dir, sprintf(fmt = "imd_%s_1.0_%d.grd", var_type, year))


    if (use_cache) {
      cache_key <- generate_cache_key(
        source = "imd",
        start_date = paste0(year, "-01-01"),
        end_date = paste0(year, "-12-31"),
        resolution = 1.0,
        var_type = var_type
      )

      cached_file <- check_cache(cache_key)
      if (!is.null(cached_file)) {
        message(sprintf(fmt = "Using cached data for %s: %s", year, basename(path = cached_file)))
        file.copy(cached_file, output_file, overwrite = TRUE)
        return(output_file)
      }
    }

    tryCatch(
      {
        message(sprintf(fmt = "Downloading year %s...", year))
        result <- download_imd_year(
          year, endpoint$php, endpoint$param,
          "https://www.imdpune.gov.in/cmpg/Griddata/", output_file
        )
        message(sprintf(fmt = "Downloaded %s: %s", year, basename(path = result)))


        if (use_cache) {
          tryCatch(
            {
              save_to_cache(result, cache_key)
            },
            error = function(e) {
              warning(sprintf(fmt = "Could not save to cache: %s", e$message), call. = FALSE)
            }
          )
        }

        Sys.sleep(2)
        result
      },
      error = function(e) {
        stop(sprintf(fmt = "Failed to download %s: %s", year, e$message))
        NA_character_
      }
    )
  }, character(1))

  files <- files[!is.na(files)]
  message(sprintf(fmt = "Downloaded %s files", length(x = files)))
  files
}

#' Check IMD server connectivity
#'
#' @param base_url Base URL to test.
#' @param timeout Connection timeout in seconds.
#' @return Logical indicating if server is reachable
#' @keywords internal
check_imd_server <- function(base_url = "https://www.imdpune.gov.in/", timeout = 30) {
  tryCatch(
    {
      response <- GET(
        base_url,
        timeout(timeout),
        config(connecttimeout = timeout)
      )
      status_code(response) < 500
    },
    error = function(e) {
      FALSE
    }
  )
}

#' Internal function to download a single year of IMD data
#'
#' @param year Year to download.
#' @param php_file PHP endpoint file.
#' @param param_name POST parameter name.
#' @param base_url Base URL.
#' @param output_file Path to save the downloaded file.
#' @param max_retries Maximum number of retry attempts.
#' @return Character string path to downloaded file
#' @keywords internal
download_imd_year <- function(year, php_file, param_name, base_url, output_file, max_retries = 3) {
  post_data <- setNames(list(as.character(x = year)), param_name)
  url <- paste0(base_url, php_file)

  last_error <- NULL

  for (attempt in 1:max_retries) {
    if (attempt > 1) {
      wait_time <- 2^(attempt - 1)
      message(sprintf(fmt = "Retry %s/%s after %ss...", attempt, max_retries, wait_time))
      Sys.sleep(wait_time)
    }

    response <- tryCatch(
      {
        POST(url,
          body = post_data,
          encode = "form",
          timeout(600), # 10 minute timeout for slow server
          config(connecttimeout = 60) # 60 second connection timeout
        )
      },
      error = function(e) {
        last_error <<- e
        NULL
      }
    )


    if (is.null(response)) {
      warning(sprintf(fmt = "Connection failed on attempt %s: %s", attempt, last_error$message), call. = FALSE)
      next
    }


    if (status_code(response) != 200) {
      last_error <- simpleError(paste("Server returned status", status_code(response)))
      warning(sprintf(fmt = "Request failed with status %s on attempt %s", status_code(response), attempt), call. = FALSE)
      next
    }

    if (grepl(pattern = "text/html", headers(response)$`content-type`, ignore.case = TRUE)) {
      last_error <- simpleError("Server returned HTML instead of data")
      warning(sprintf(fmt = "Server returned HTML on attempt %s", attempt), call. = FALSE)
      next
    }


    writeBin(content(response, "raw"), output_file)
    if (!file.exists(output_file) || file.size(output_file) == 0) {
      last_error <- simpleError("Downloaded file is empty or was not created")
      warning(sprintf(fmt = "Downloaded file is empty on attempt %s", attempt), call. = FALSE)
      next
    }


    return(output_file)
  }


  if (!is.null(last_error)) {
    stop("Failed after ", max_retries, " attempts. Last error: ", last_error$message)
  } else {
    stop("Failed after ", max_retries, " attempts with unknown error")
  }
}

#' Get IMD grid specifications
#'
#' Returns the grid specifications for different IMD datasets based on
#' analysis of actual data.
#'
#' @param dataset Dataset identifier: "rainfall_0.25",
#'   "rainfall_1.0", "tmax_1.0", "tmin_1.0".
#' @return List with grid specifications.
#' @export
#' @examples
#' specs <- get_imd_grid_specs("rainfall_0.25")
get_imd_grid_specs <- function(dataset) {
  specs <- list(
    "rainfall_0.25" = list(
      nlat = 129, # Actual from NetCDF
      nlon = 135, # Actual from NetCDF
      lat_start = 6.5,
      lat_end = 38.5,
      lon_start = 66.5,
      lon_end = 100.0,
      resolution = 0.25,
      unit = "mm",
      missing_value = -999,
      format = "NetCDF",
      variable_name = "rf",
      description = "Daily rainfall at 0.25 degree resolution"
    ),
    "rainfall_1.0" = list(
      nlat = 31,
      nlon = 31,
      lat_start = 7.5,
      lat_end = 37.5,
      lon_start = 67.5,
      lon_end = 97.5,
      resolution = 1.0,
      unit = "mm",
      missing_value = -999,
      format = "NetCDF",
      variable_name = "rf",
      description = "Daily rainfall at 1.0 degree resolution"
    ),
    "tmax_1.0" = list(
      nlat = 31,
      nlon = 31,
      lat_start = 7.5,
      lat_end = 37.5,
      lon_start = 67.5,
      lon_end = 97.5,
      resolution = 1.0,
      unit = "Celsius",
      missing_value = 99.9,
      format = "Binary",
      description = "Daily maximum temperature at 1.0 degree resolution"
    ),
    "tmin_1.0" = list(
      nlat = 31,
      nlon = 31,
      lat_start = 7.5,
      lat_end = 37.5,
      lon_start = 67.5,
      lon_end = 97.5,
      resolution = 1.0,
      unit = "Celsius",
      missing_value = 99.9,
      format = "Binary",
      description = "Daily minimum temperature at 1.0 degree resolution"
    )
  )

  if (!dataset %in% names(specs)) {
    stop(
      "Invalid dataset. Must be one of: ",
      paste(names(specs), collapse = ", ")
    )
  }

  return(specs[[dataset]])
}

#' List available IMD datasets
#'
#' @return data.frame with available IMD datasets and their characteristics
#' @export
list_imd_datasets <- function() {
  datasets <- data.frame(
    dataset_id = c("rainfall_0.25", "rainfall_1.0", "tmax_1.0", "tmin_1.0"),
    variable = c("Rainfall", "Rainfall", "Max Temperature", "Min Temperature"),
    resolution = c(0.25, 1.0, 1.0, 1.0),
    year_start = c(1901, 1901, 1951, 1951),
    year_end = c(2025, 2025, 2025, 2025),
    unit = c("mm", "mm", "\u00b0C", "\u00b0C"),
    format = c("NetCDF", "NetCDF", "Binary", "Binary"),
    grid_size = c("135x129", "31x31", "31x31", "31x31"),
    missing_value = c(-999, -999, 99.9, 99.9),
    stringsAsFactors = FALSE
  )

  return(datasets)
}
