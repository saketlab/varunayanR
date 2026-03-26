#' ERA5 data download functions using ecmwfr

# Variables not available in the monthly-means product (require hourly reanalysis)
.MONTHLY_MEANS_UNSUPPORTED <- c(
  "maximum_2m_temperature_since_previous_post_processing",
  "minimum_2m_temperature_since_previous_post_processing"
)

#' Set up CDS credentials for ERA5 data access
#'
#' This function helps users set up their Copernicus Climate Data Store (CDS) credentials
#' for downloading ERA5 data. Credentials are checked in the following order:
#' 1. Directly provided `key` argument
#' 2. `CDS_API_KEY` environment variable
#' 3. `~/.cdsapirc` file
#'
#' @param key Your CDS API key (UUID format). If NULL, attempts to read from
#'   environment variable `CDS_API_KEY` or ~/.cdsapirc file.
#' @param ... Arguments passed to the main function (used by aliases).
#' @return Invisible TRUE if successful
#' @export
#' @examples
#' \dontrun{
#' setup_cds_credentials(key = "your-cds-api-key-here")
#' Sys.setenv(CDS_API_KEY = "your-cds-api-key-here")
#' setup_cds_credentials()
#' }
setup_cds_credentials <- function(key = NULL) {
  if (is.null(key)) {
    env_key <- Sys.getenv("CDS_API_KEY", unset = "")
    if (nzchar(env_key)) {
      key <- env_key
      message("Using CDS API key from CDS_API_KEY environment variable")
    } else {
      message("No key provided, attempting to read from ~/.cdsapirc...")
      creds <- read_cdsapirc()

      if (is.null(creds) || !"key" %in% names(creds)) {
        stop(
          "Could not find CDS credentials.\n",
          "Please provide credentials using one of these methods:\n",
          "  1. Provide key directly: setup_cds_credentials(key = 'your-api-key')\n",
          "  2. Set environment variable: Sys.setenv(CDS_API_KEY = 'your-api-key')\n",
          "  3. Create ~/.cdsapirc file with format:\n",
          "     url: https://cds.climate.copernicus.eu/api\n",
          "     key: your-api-key-here\n\n",
          "Get your API key from: https://cds.climate.copernicus.eu/how-to-api"
        )
      }

      key <- creds$key
      message("Found credentials in ~/.cdsapirc")
    }
  }

  suppressWarnings({
    wf_set_key(key = key)
  })

  message("CDS credentials set successfully!")
  message("You can now download ERA5 data using varunayan functions.")

  invisible(TRUE)
}


#' Download ERA5 single-level data using ecmwfr
#'
#' @param variables Character vector of variable names
#' @param start_date Date object or character string (YYYY-MM-DD)
#' @param end_date Date object or character string (YYYY-MM-DD)
#' @param area Numeric vector of 4 elements: c(north, west, south, east) in decimal degrees
#' @param resolution Numeric value for grid resolution (default: 0.25 degrees)
#' @param frequency Character string: "hourly", "daily", "monthly"
#' @param output_file Character string path for output NetCDF file
#' @param timeout Numeric value for request timeout in seconds (default: 3600)
#' @param retry_attempts Integer number of retry attempts (default: 5)
#' @param use_cache Use cached data if available (default: TRUE)
#' @param verbose Logical indicating whether to print progress messages
#' @return Character string path to downloaded file
download_era5_single <- function(variables, start_date, end_date, area = NULL,
                                 resolution = 0.25, frequency = "hourly", output_file,
                                 timeout = 3600, retry_attempts = 5, use_cache = TRUE,
                                 verbose = FALSE) {
  use_monthly_means <- (frequency == "monthly") &&
    !any(variables %in% .MONTHLY_MEANS_UNSUPPORTED)

  if (use_cache) {
    cache_key <- generate_cache_key(
      source = "era5",
      variables = variables,
      start_date = start_date,
      end_date = end_date,
      area = area,
      resolution = resolution,
      dataset_type = if (use_monthly_means) "single_monthly_means" else "single"
    )

    cached_file <- check_cache(cache_key)
    if (!is.null(cached_file)) {
      message(sprintf(fmt = "Using cached data: %s", basename(path = cached_file)))
      message(sprintf(fmt = "Cache location: %s", cached_file))
      file.copy(cached_file, output_file, overwrite = TRUE)
      return(output_file)
    }
  }

  start_str <- format(as.Date(x = start_date), "%Y-%m-%d")
  end_str <- format(as.Date(x = end_date), "%Y-%m-%d")

  if (use_monthly_means) {
    # Monthly-means product is pre-aggregated; uses year/month params instead of daily dates
    month_seq <- seq(from = as.Date(x = start_date), to = as.Date(x = end_date), by = "month")
    years <- unique(format(month_seq, "%Y"))
    months <- unique(format(month_seq, "%m"))

    request <- list(
      product_type = "monthly_averaged_reanalysis",
      format = "netcdf",
      variable = variables,
      year = years,
      month = months,
      time = "00:00",
      grid = c(resolution, resolution)
    )
  } else {
    date_seq <- seq(from = as.Date(x = start_date), to = as.Date(x = end_date), by = "day")
    date_strings <- format(date_seq, "%Y-%m-%d")

    time_values <- switch(frequency,
      "hourly" = sprintf(fmt = "%02d:00", 0:23),
      "daily" = "12:00",
      sprintf(fmt = "%02d:00", 0:23)
    )

    request <- list(
      product_type = "reanalysis",
      format = "netcdf",
      variable = variables,
      date = date_strings,
      time = time_values,
      grid = c(resolution, resolution)
    )
  }

  if (!is.null(area)) {
    request$area <- area
  }

  request$dataset_short_name <- if (use_monthly_means) {
    "reanalysis-era5-single-levels-monthly-means"
  } else {
    "reanalysis-era5-single-levels"
  }
  request$target <- basename(path = output_file)

  if (!get_cds_credentials(silent = TRUE)) {
    stop(
      "CDS credentials not found. Please either:\n",
      "  1. Create ~/.cdsapirc file with your API key, or\n",
      "  2. Run setup_cds_credentials(key = 'your-api-key')\n\n",
      "Get your API key from: https://cds.climate.copernicus.eu/api-how-to"
    )
  }

  message("Submitting request to Copernicus CDS...")
  message(sprintf(fmt = "Variables: %s", paste(variables, collapse = ", ")))
  message(sprintf(fmt = "Date range: %s to %s", start_str, end_str))
  if (!is.null(area)) {
    message(sprintf(fmt = "Area: N:%s, W:%s, S:%s, E:%s", area[1], area[2], area[3], area[4]))
  }

  message("Note: ERA5 downloads may take several minutes depending on data size and server load")
  message(sprintf(fmt = "Request will timeout after %s seconds", timeout))

  downloaded_file <- NULL
  last_error <- NULL
  failures <- 0
  rate_limit_hits <- 0
  max_rate_limit_hits <- 20

  repeat {
    if (failures > 0) {
      message(sprintf(fmt = "Retry attempt %s/%s", failures, retry_attempts))
      Sys.sleep(5)
    }

    downloaded_file <- tryCatch(
      {
        if (requireNamespace("R.utils", quietly = TRUE)) {
          R.utils::withTimeout(
            wf_request(
              request = request,
              transfer = TRUE,
              path = dirname(path = output_file)
            ),
            timeout = timeout,
            onTimeout = "error"
          )
        } else {
          wf_request(
            request = request,
            transfer = TRUE,
            path = dirname(path = output_file)
          )
        }
      },
      error = function(e) {
        last_error <<- e
        NULL
      }
    )

    if (!is.null(downloaded_file)) break

    if (!is.null(last_error)) {
      if (grepl(pattern = "401|unauthorized|authentication", last_error$message, ignore.case = TRUE)) {
        stop(
          "Authentication failed. Please check your CDS API credentials.\n",
          "Run setup_cds_credentials(key = 'your-api-key') with a valid key.\n",
          "Get your API key from: https://cds.climate.copernicus.eu/api-how-to"
        )
      } else if (grepl(pattern = "rate.limit|429", last_error$message, ignore.case = TRUE)) {
        rate_limit_hits <- rate_limit_hits + 1
        if (rate_limit_hits > max_rate_limit_hits) {
          stop("Exceeded ", max_rate_limit_hits, " rate-limit retries. Try again later.")
        }
        wait_secs <- as.numeric(sub(".*wait (\\d+) seconds.*", "\\1", last_error$message))
        if (is.na(wait_secs)) wait_secs <- 60
        warning(sprintf(fmt = "Rate limited (%d/%d). Waiting %s seconds...",
                        rate_limit_hits, max_rate_limit_hits, wait_secs), call. = FALSE)
        Sys.sleep(wait_secs)
        next # skip the 5s sleep at top since we already waited
      } else if (grepl(pattern = "timeout|time.*out", last_error$message, ignore.case = TRUE)) {
        failures <- failures + 1
        warning(sprintf(fmt = "Request timed out on attempt %s. Retrying...", failures), call. = FALSE)
      } else if (grepl(pattern = "queue|busy|server", last_error$message, ignore.case = TRUE)) {
        failures <- failures + 1
        warning(sprintf(fmt = "CDS server is busy on attempt %s. Retrying...", failures), call. = FALSE)
      } else {
        failures <- failures + 1
        warning(sprintf(fmt = "Download failed on attempt %s: %s", failures, last_error$message), call. = FALSE)
      }
    } else {
      failures <- failures + 1
    }

    if (failures > retry_attempts) {
      stop(
        sprintf("Download failed after %d attempts: ", failures),
        if (!is.null(last_error)) last_error$message else "unknown error", "\n",
        "Check your internet connection and CDS service status at: https://cds.climate.copernicus.eu/"
      )
    }
  }

  # wf_request returns the path to the downloaded file
  # Use it directly if it exists, otherwise fall back to searching
  if (!is.null(downloaded_file) && file.exists(downloaded_file)) {
    final_file <- downloaded_file
    # Handle ZIP extraction if needed
    if (file_ext(downloaded_file) == "zip") {
      final_file <- extract_zip_to_nc(downloaded_file, dirname(path = output_file))
    }
  } else {
    final_file <- find_and_extract_download(output_file, request$target)
  }

  message(sprintf(fmt = "Download completed: %s", final_file))

  if (use_cache) {
    tryCatch(
      save_to_cache(final_file, cache_key),
      error = function(e) warning(sprintf(fmt = "Could not save to cache: %s", e$message), call. = FALSE)
    )
  }

  final_file
}

#' Download ERA5 pressure-level data using ecmwfr
#'
#' @param variables Character vector of variable names
#' @param pressure_levels Character vector of pressure levels (e.g., c("1000", "850", "500"))
#' @param start_date Date object or character string (YYYY-MM-DD)
#' @param end_date Date object or character string (YYYY-MM-DD)
#' @param area Numeric vector of 4 elements: c(north, west, south, east) in decimal degrees
#' @param resolution Numeric value for grid resolution (default: 0.25 degrees)
#' @param frequency Character string: "hourly", "daily", "monthly"
#' @param output_file Character string path for output NetCDF file
#' @param use_cache Use cached data if available (default: TRUE)
#' @param verbose Logical indicating whether to print progress messages
#' @return Character string path to downloaded file
download_era5_pressure <- function(variables, pressure_levels, start_date, end_date,
                                   area = NULL, resolution = 0.25, frequency = "hourly",
                                   output_file, use_cache = TRUE, verbose = FALSE) {
  if (use_cache) {
    cache_key <- generate_cache_key(
      source = "era5",
      variables = variables,
      start_date = start_date,
      end_date = end_date,
      area = area,
      resolution = resolution,
      dataset_type = "pressure",
      pressure_levels = pressure_levels
    )

    cached_file <- check_cache(cache_key)
    if (!is.null(cached_file)) {
      message(sprintf(fmt = "Using cached data: %s", basename(path = cached_file)))
      message(sprintf(fmt = "Cache location: %s", cached_file))
      file.copy(cached_file, output_file, overwrite = TRUE)
      return(output_file)
    }
  }

  start_str <- format(as.Date(x = start_date), "%Y-%m-%d")
  end_str <- format(as.Date(x = end_date), "%Y-%m-%d")

  date_seq <- seq(from = as.Date(x = start_date), to = as.Date(x = end_date), by = "day")
  date_strings <- format(date_seq, "%Y-%m-%d")

  time_values <- switch(frequency,
    "hourly" = sprintf(fmt = "%02d:00", 0:23),
    "daily" = "12:00",
    "monthly" = "12:00",
    sprintf(fmt = "%02d:00", 0:23)
  )

  request <- list(
    product_type = "reanalysis",
    format = "netcdf",
    variable = variables,
    pressure_level = pressure_levels,
    date = date_strings,
    time = time_values,
    grid = c(resolution, resolution)
  )

  if (!is.null(area)) {
    request$area <- area
  }

  request$dataset_short_name <- "reanalysis-era5-pressure-levels"
  request$target <- basename(path = output_file)

  if (!get_cds_credentials(silent = TRUE)) {
    stop(
      "CDS credentials not found. Please either:\n",
      "  1. Create ~/.cdsapirc file with your API key, or\n",
      "  2. Run setup_cds_credentials(key = 'your-api-key')\n\n",
      "Get your API key from: https://cds.climate.copernicus.eu/api-how-to"
    )
  }

  message("Submitting pressure-level request to Copernicus CDS...")
  message(sprintf(fmt = "Variables: %s", paste(variables, collapse = ", ")))
  message(sprintf(fmt = "Pressure levels: %s hPa", paste(pressure_levels, collapse = ", ")))
  message(sprintf(fmt = "Date range: %s to %s", start_str, end_str))
  if (!is.null(area)) {
    message(sprintf(fmt = "Area: N:%s, W:%s, S:%s, E:%s", area[1], area[2], area[3], area[4]))
  }

  message("Note: ERA5 downloads may take several minutes depending on data size and server load")

  downloaded_file <- tryCatch(
    {
      wf_request(
        request = request,
        transfer = TRUE,
        path = dirname(path = output_file)
      )
    },
    error = function(e) {
      if (grepl(pattern = "401|unauthorized|authentication", e$message, ignore.case = TRUE)) {
        stop(
          "Authentication failed. Please check your CDS API credentials.\n",
          "Run setup_cds_credentials(key = 'your-api-key') with a valid key.\n",
          "Get your API key from: https://cds.climate.copernicus.eu/api-how-to"
        )
      } else if (grepl(pattern = "timeout|time.*out", e$message, ignore.case = TRUE)) {
        stop(
          "Request timed out. This can happen with large data requests.\n",
          "Try reducing the date range or area size, or try again later.\n",
          "For large datasets, consider using smaller time chunks or lower resolution."
        )
      } else if (grepl(pattern = "queue|busy|server", e$message, ignore.case = TRUE)) {
        stop(
          "CDS server is busy. Please try again later.\n",
          "Peak usage times may result in longer waits or timeouts."
        )
      } else {
        stop(
          "Download failed: ", e$message, "\n",
          "Check your internet connection and CDS service status at: https://cds.climate.copernicus.eu/"
        )
      }
    }
  )

  # wf_request returns the path to the downloaded file
  # Use it directly if it exists, otherwise fall back to searching
  if (!is.null(downloaded_file) && file.exists(downloaded_file)) {
    final_file <- downloaded_file
    # Handle ZIP extraction if needed
    if (file_ext(downloaded_file) == "zip") {
      final_file <- extract_zip_to_nc(downloaded_file, dirname(path = output_file))
    }
  } else {
    final_file <- find_and_extract_download(output_file, request$target)
  }

  message(sprintf(fmt = "Pressure-level download completed: %s", final_file))

  if (use_cache) {
    tryCatch(
      save_to_cache(final_file, cache_key),
      error = function(e) warning(sprintf(fmt = "Could not save to cache: %s", e$message), call. = FALSE)
    )
  }

  final_file
}

# Helper to extract ZIP file to NetCDF
extract_zip_to_nc <- function(zip_file, output_dir) {
  message(sprintf(fmt = "Extracting ZIP file: %s", basename(path = zip_file)))

  temp_extract_dir <- file.path(output_dir, "extracted")
  dir.create(temp_extract_dir, showWarnings = FALSE)

  unzip(zip_file, exdir = temp_extract_dir)

  nc_files <- list.files(temp_extract_dir, pattern = "\\.nc$", full.names = TRUE)

  if (length(x = nc_files) == 0) {
    stop("No NetCDF files found in ZIP archive: ", zip_file)
  }

  if (length(x = nc_files) > 1) {
    warning(sprintf(fmt = "Multiple NetCDF files found, using first one: %s", basename(path = nc_files[1])), call. = FALSE)
  }

  final_file <- file.path(output_dir, basename(path = nc_files[1]))
  file.copy(nc_files[1], final_file, overwrite = TRUE)

  unlink(temp_extract_dir, recursive = TRUE)
  unlink(zip_file)

  final_file
}

# Helper to find downloaded file (may be .nc or .zip) and extract if needed
find_and_extract_download <- function(output_file, target) {
  base_name <- file_path_sans_ext(basename(path = output_file))
  base_dir <- dirname(path = output_file)

  possible_files <- c(
    output_file,
    file.path(base_dir, paste0(base_name, ".zip")),
    file.path(base_dir, target)
  )

  actual_file <- NULL
  for (pf in possible_files) {
    if (file.exists(pf)) {
      actual_file <- pf
      break
    }
  }

  if (is.null(actual_file)) {
    stop("Downloaded file not found. Expected one of: ", paste(possible_files, collapse = ", "))
  }

  final_file <- actual_file
  if (file_ext(actual_file) == "zip") {
    message(sprintf(fmt = "Extracting ZIP file: %s", basename(path = actual_file)))

    temp_extract_dir <- file.path(base_dir, "extracted")
    dir.create(temp_extract_dir, showWarnings = FALSE)

    unzip(actual_file, exdir = temp_extract_dir)

    nc_files <- list.files(temp_extract_dir, pattern = "\\.nc$", full.names = TRUE)

    if (length(x = nc_files) == 0) {
      stop("No NetCDF files found in ZIP archive: ", actual_file)
    }

    if (length(x = nc_files) > 1) {
      warning(sprintf(fmt = "Multiple NetCDF files found, using first one: %s", basename(path = nc_files[1])), call. = FALSE)
    }

    final_file <- output_file
    file.copy(nc_files[1], final_file, overwrite = TRUE)

    unlink(temp_extract_dir, recursive = TRUE)
    unlink(actual_file)
  }

  final_file
}

.varunayan_cache <- new.env(parent = emptyenv())

#' Validate ERA5 variable names
#'
#' @param variables Character vector of variable names to validate
#' @param dataset_type Character string: "single" or "pressure"
#' @return Logical vector indicating which variables are valid
validate_era5_variables <- function(variables, dataset_type) {
  cache_key <- paste0("valid_vars_", dataset_type)

  if (!exists(cache_key, envir = .varunayan_cache)) {
    if (dataset_type == "single") {
      valid_vars <- get_single_level_variable_names()
    } else if (dataset_type == "pressure") {
      valid_vars <- get_pressure_level_variable_names()
    } else {
      stop("Invalid dataset_type. Must be 'single' or 'pressure'")
    }
    assign(cache_key, valid_vars, envir = .varunayan_cache)
  } else {
    valid_vars <- get(cache_key, envir = .varunayan_cache)
  }

  variables %in% valid_vars
}

#' Get all valid single-level variable names
#'
#' @return Character vector of valid single-level variable names
get_single_level_variable_names <- function() {
  c(
    "2m_temperature", "surface_pressure", "mean_sea_level_pressure",
    "total_precipitation", "convective_precipitation", "large_scale_precipitation",
    "10m_u_component_of_wind", "10m_v_component_of_wind",
    "surface_solar_radiation_downwards", "surface_thermal_radiation_downwards",
    "2m_dewpoint_temperature", "skin_temperature", "total_cloud_cover",
    "low_cloud_cover", "medium_cloud_cover", "high_cloud_cover",
    "surface_latent_heat_flux", "surface_sensible_heat_flux",
    "evaporation", "runoff", "soil_temperature_level_1",
    "soil_temperature_level_2", "soil_temperature_level_3",
    "soil_temperature_level_4", "volumetric_soil_water_layer_1",
    "volumetric_soil_water_layer_2", "volumetric_soil_water_layer_3",
    "volumetric_soil_water_layer_4", "snow_depth", "snow_density",
    "maximum_2m_temperature_since_previous_post_processing",
    "minimum_2m_temperature_since_previous_post_processing"
  )
}

#' Get all valid pressure-level variable names
#'
#' @return Character vector of valid pressure-level variable names
get_pressure_level_variable_names <- function() {
  c(
    "temperature", "u_component_of_wind", "v_component_of_wind",
    "geopotential", "relative_humidity", "specific_humidity",
    "vertical_velocity", "vorticity", "divergence"
  )
}
