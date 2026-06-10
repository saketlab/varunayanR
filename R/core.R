# ERA5 data download and processing for custom regions

# CDS API field limits (from https://forum.ecmwf.int/t/cdsapi-limitations-and-restrictions/1639)
# A "field" = 1 variable x 1 time step (x 1 pressure level if applicable)
CDS_FIELD_LIMIT_HOURLY <- 120000L # reanalysis (hourly/daily)
CDS_FIELD_LIMIT_MONTHLY <- 10000L # monthly-means product

#' Estimate the number of CDS "fields" in a request
#'
#' The CDS API limits requests to 120,000 fields for hourly/daily reanalysis
#' and 10,000 fields for monthly means. A field is one variable x one time step
#' x one pressure level.
#'
#' @param n_variables Number of variables requested
#' @param start_date Start date
#' @param end_date End date
#' @param frequency "hourly", "daily", or "monthly"
#' @param n_pressure_levels Number of pressure levels (1 for single-level)
#' @return Integer number of estimated fields
#' @keywords internal
estimate_cds_fields <- function(n_variables, start_date, end_date, frequency,
                                n_pressure_levels = 1L) {
  s <- as.Date(start_date)
  e <- as.Date(end_date)

  if (frequency == "monthly") {
    n_timesteps <- (as.integer(format(e, "%Y")) - as.integer(format(s, "%Y"))) * 12L +
      (as.integer(format(e, "%m")) - as.integer(format(s, "%m"))) + 1L
  } else {
    n_days <- as.integer(e - s) + 1L
    times_per_day <- if (frequency == "hourly") 24L else 1L
    n_timesteps <- n_days * times_per_day
  }

  as.integer(n_variables) * n_timesteps * as.integer(n_pressure_levels)
}

#' Compute optimal chunk size to stay within CDS field limits
#'
#' Uses 90% of the CDS limit as headroom. Returns max years for monthly
#' frequency, max days for hourly/daily.
#'
#' @param n_variables Number of variables
#' @param frequency "hourly", "daily", or "monthly"
#' @param n_pressure_levels Number of pressure levels (1 for single-level)
#' @return Integer: max years (monthly) or max days (hourly/daily) per chunk
#' @keywords internal
compute_optimal_chunk_size <- function(n_variables, frequency,
                                       n_pressure_levels = 1L) {
  n_vars <- as.integer(n_variables) * as.integer(n_pressure_levels)

  if (frequency == "monthly") {
    # CDS monthly-means: field = n_vars * 12_months_per_year * n_years
    # Limit is 10,000 fields. Use 90% headroom.
    max_years <- (CDS_FIELD_LIMIT_MONTHLY * 0.9) %/% (n_vars * 12L)
    return(as.integer(max(min(max_years, 30L), 1L)))
  }

  times_per_day <- if (frequency == "hourly") 24L else 1L
  max_days <- CDS_FIELD_LIMIT_HOURLY %/% (n_vars * times_per_day)
  as.integer(min(max(max_days, 1L), 3650L))
}

# Temperature variables that need Kelvin to Celsius conversion
TEMP_VARS <- c(
  "2m_temperature", "2m_dewpoint_temperature", "skin_temperature",
  "sea_surface_temperature", "soil_temperature_level_1",
  "soil_temperature_level_2", "soil_temperature_level_3",
  "soil_temperature_level_4", "temperature",
  "maximum_2m_temperature_since_previous_post_processing",
  "minimum_2m_temperature_since_previous_post_processing",
  "t2m", "d2m", "skt", "sst", "stl1", "stl2", "stl3", "stl4", "t",
  "mx2t", "mn2t"
)

# Precipitation/accumulation variables that need meters to mm conversion
PRECIP_VARS <- c(
  "total_precipitation", "convective_precipitation",
  "large_scale_precipitation", "snowfall",
  "total_evaporation", "evaporation",
  "tp", "cp", "lsp", "sf", "e"
)

#' Convert ERA5 units to user-friendly units
#'
#' Converts temperature from Kelvin to Celsius and precipitation from meters to mm.
#'
#' @param data data.frame with ERA5 data containing 'variable' and 'value' columns
#' @return data.frame with converted units
#' @keywords internal
convert_era5_units <- function(data) {
  if (!"variable" %in% names(data) || !"value" %in% names(data)) {
    return(data)
  }

  if (inherits(data$value, "units")) {
    data$value <- as.numeric(x = data$value)
  }

  temp_mask <- data$variable %in% TEMP_VARS
  if (any(temp_mask)) {
    data$value[temp_mask] <- data$value[temp_mask] - 273.15
  }

  precip_mask <- data$variable %in% PRECIP_VARS
  if (any(precip_mask)) {
    data$value[precip_mask] <- data$value[precip_mask] * 1000
  }

  data
}

validate_era5_inputs <- function(dataset_type, variables, start_date, end_date) {
  dataset_type <- tolower(x = dataset_type)
  if (!dataset_type %in% c("single", "pressure")) {
    stop("Invalid dataset_type: ", dataset_type, ". Must be 'single' or 'pressure'")
  }

  valid_vars <- validate_era5_variables(variables, dataset_type)
  if (!all(valid_vars)) {
    stop(
      "Invalid variables for ", dataset_type, " dataset: ",
      paste(variables[!valid_vars], collapse = ", ")
    )
  }

  dates <- c(as.Date(x = start_date), as.Date(x = end_date))
  if (dates[1] > dates[2]) stop("Start date must be before end date")

  list(dataset_type = dataset_type, start_dt = dates[1], end_dt = dates[2])
}

download_era5_data <- function(dataset_type, variables, start_dt, end_dt, area,
                               resolution, frequency, output_dir, request_id,
                               pressure_levels = NULL, save_raw = FALSE, use_cache = TRUE,
                               verbose = FALSE) {
  n_vars <- length(variables)
  n_plevels <- if (!is.null(pressure_levels)) length(pressure_levels) else 1L

  # Estimate total fields and compute optimal chunk size proactively
  total_fields <- estimate_cds_fields(n_vars, start_dt, end_dt, frequency, n_plevels)
  field_limit <- if (frequency == "monthly") CDS_FIELD_LIMIT_MONTHLY else CDS_FIELD_LIMIT_HOURLY

  if (verbose) {
    message(sprintf(
      "Estimated CDS fields: %s (limit: %s)", format(total_fields, big.mark = ","),
      format(field_limit, big.mark = ",")
    ))
  }

  if (frequency == "monthly") {
    max_years <- compute_optimal_chunk_size(n_vars, frequency, n_plevels)
    start_year <- as.integer(format(as.Date(start_dt), "%Y"))
    end_year <- as.integer(format(as.Date(end_dt), "%Y"))

    if (max_years >= (end_year - start_year + 1L)) {
      # Entire range fits in one request
      chunks <- list(list(
        start = paste0(start_year, "-01-01"),
        end = paste0(end_year, "-12-31")
      ))
    } else {
      # Chunk into groups of max_years
      chunks <- list()
      yr <- start_year
      while (yr <= end_year) {
        yr_end <- min(yr + max_years - 1L, end_year)
        chunks[[length(chunks) + 1L]] <- list(
          start = paste0(yr, "-01-01"),
          end = paste0(yr_end, "-12-31")
        )
        yr <- yr_end + 1L
      }
    }

    if (total_fields > field_limit && verbose) {
      message(sprintf(
        "Request exceeds %s field limit. Auto-chunking into %d chunk(s) of up to %d year(s).",
        format(field_limit, big.mark = ","), length(chunks), max_years
      ))
    }
  } else {
    chunk_days <- compute_optimal_chunk_size(n_vars, frequency, n_plevels)

    if (total_fields > field_limit && verbose) {
      message(sprintf(
        "Request exceeds %s field limit. Auto-chunking into %d-day chunks.",
        format(field_limit, big.mark = ","), chunk_days
      ))
    }

    chunks <- create_temporal_chunks(start_dt, end_dt, frequency, max_days_per_chunk = chunk_days)
  }

  # Download a single chunk, splitting automatically if CDS says "too large"
  download_chunk <- function(chunk_start, chunk_end, chunk_id, depth = 0) {
    chunk_file <- file.path(output_dir, sprintf(
      "%s_chunk%s_%s.nc",
      request_id, chunk_id, format(Sys.Date(), "%Y%m%d")
    ))

    tryCatch(
      {
        if (dataset_type == "single") {
          result_file <- download_era5_single(
            variables = variables,
            start_date = chunk_start,
            end_date = chunk_end,
            area = area,
            resolution = resolution,
            frequency = frequency,
            output_file = chunk_file,
            timeout = 1800,
            retry_attempts = 5,
            use_cache = use_cache,
            verbose = verbose
          )
        } else {
          result_file <- download_era5_pressure(
            variables = variables,
            pressure_levels = pressure_levels,
            start_date = chunk_start,
            end_date = chunk_end,
            area = area,
            resolution = resolution,
            frequency = frequency,
            output_file = chunk_file,
            use_cache = use_cache,
            verbose = verbose
          )
        }
        return(result_file)
      },
      cds_request_too_large = function(e) {
        s <- as.Date(chunk_start)
        en <- as.Date(chunk_end)
        span <- as.numeric(en - s)

        if (span < 30 || depth > 6) {
          stop(
            "Request still too large after splitting to ",
            span, " days (depth ", depth, "). Reduce area or resolution."
          )
        }

        mid <- s + floor(span / 2)
        if (frequency == "monthly") {
          mid_year <- as.integer(format(mid, "%Y"))
          mid <- as.Date(paste0(mid_year, "-01-01"))
          # Ensure mid is strictly between start and end
          start_year <- as.integer(format(s, "%Y"))
          end_year <- as.integer(format(en, "%Y"))
          if (mid_year <= start_year) mid <- as.Date(paste0(start_year + 1, "-01-01"))
          if (mid >= en) {
            # Can't split a single year for monthly. Fall back to daily-style split.
            mid <- s + floor(span / 2)
          }
        }

        # Final guard: mid must be after start and before end
        if (mid <= s || mid >= en) {
          stop(
            "Cannot split range ", chunk_start, " to ", chunk_end,
            " further. Reduce area or resolution."
          )
        }

        message(sprintf(
          "Chunk too large (%s to %s). Splitting at %s (depth %d)...",
          chunk_start, chunk_end, mid, depth + 1
        ))

        f1 <- download_chunk(
          chunk_start, as.character(mid - 1),
          paste0(chunk_id, "a"), depth + 1
        )
        f2 <- download_chunk(
          as.character(mid), chunk_end,
          paste0(chunk_id, "b"), depth + 1
        )
        return(c(f1, f2))
      }
    )
  }

  message(sprintf(fmt = "Processing %d temporal chunks...", length(x = chunks)))
  if (length(chunks) > 1) {
    pb <- txtProgressBar(min = 0, max = length(x = chunks), style = 3)
  }

  all_files <- list()
  for (i in seq_along(along.with = chunks)) {
    chunk <- chunks[[i]]
    if (verbose) {
      message(sprintf(
        fmt = "\nChunk %s/%s: %s to %s",
        i, length(x = chunks), chunk$start, chunk$end
      ))
    }

    files <- download_chunk(chunk$start, chunk$end, as.character(i))
    all_files <- c(all_files, files)

    if (length(chunks) > 1) setTxtProgressBar(pb, i)
  }
  if (length(chunks) > 1) close(pb)

  all_files <- unlist(all_files)

  if (length(all_files) == 1) {
    list(file = all_files[1])
  } else {
    processed_data <- combine_netcdf_files(all_files, verbose = verbose)
    if (!save_raw) unlink(all_files)
    list(data = processed_data, files = all_files)
  }
}

#' Download and process ERA5 data for a GeoJSON region
#'
#' @param request_id Unique identifier for the data request
#' @param variables List of ERA5 variables to download
#' @param start_date Start date in "YYYY-MM-DD" format
#' @param end_date End date in "YYYY-MM-DD" format
#' @param json_file Path to GeoJSON file defining the region
#' @param dataset_type Type of dataset ("single" or "pressure")
#' @param pressure_levels Pressure levels for pressure dataset
#' @param frequency Temporal frequency ("hourly", "daily", "monthly")
#' @param resolution Spatial resolution in degrees (default: 0.25)
#' @param save_raw Whether to save raw downloaded files
#' @param output_dir Directory to save files (default: tempdir())
#' @param use_cache Whether to use cached data if available (default: TRUE)
#' @param convert_units Whether to convert units to user-friendly formats (default: TRUE).
#'   When TRUE, temperature variables are returned in Celsius (converted from Kelvin)
#'   and precipitation variables are returned in mm (converted from meters).
#' @param verbose Whether to print detailed progress messages
#' @param ... Arguments passed to the main function (used by aliases).
#'
#' @return data.frame with processed climate data. When `convert_units = TRUE`:
#'   \itemize{
#'     \item Temperature variables (e.g., 2m_temperature): Celsius
#'     \item Precipitation variables (e.g., total_precipitation): mm
#'     \item Other variables: original ERA5 units
#'   }
#' @export
#' @examples
#' \dontrun{
#' setup_cds_credentials(key = "your-cds-api-key")
#'
#' data <- era5ify_geojson(
#'   request_id = "my_request",
#'   variables = c("2m_temperature", "total_precipitation"),
#'   start_date = "2023-01-01",
#'   end_date = "2023-01-31",
#'   json_file = "region.geojson"
#' )
#' # Temperature is in Celsius, precipitation is in mm
#' }
era5ify_geojson <- function(request_id, variables, start_date, end_date, json_file,
                            dataset_type = "single", pressure_levels = NULL,
                            frequency = "hourly", resolution = 0.25,
                            save_raw = FALSE, output_dir = tempdir(), use_cache = TRUE,
                            convert_units = TRUE, verbose = FALSE) {
  if (!grepl(pattern = "^https?://", json_file) && !file.exists(json_file)) {
    stop("GeoJSON file not found: ", json_file)
  }

  validated <- validate_era5_inputs(dataset_type, variables, start_date, end_date)

  bbox <- st_bbox(st_read(json_file, quiet = TRUE))
  area <- c(bbox[["ymax"]], bbox[["xmin"]], bbox[["ymin"]], bbox[["xmax"]])

  if (verbose) {
    message("Starting ERA5 data download for GeoJSON region")
    message(sprintf(fmt = "Request ID: %s", request_id))
    message(sprintf(fmt = "Bounding box: N:%s, W:%s, S:%s, E:%s", round(area[1], 3), round(area[2], 3), round(area[3], 3), round(area[4], 3)))
  }

  result <- download_era5_data(
    validated$dataset_type, variables, validated$start_dt,
    validated$end_dt, area, resolution, frequency,
    output_dir, request_id, pressure_levels, save_raw, use_cache, verbose
  )

  if (!is.null(result$data)) {
    processed_data <- filter_dataframe_by_geojson(result$data, json_file)
  } else {
    processed_data <- filter_netcdf_by_geojson(result$file, json_file)
    if (!save_raw && file.exists(result$file)) unlink(result$file)
  }

  if (frequency != "hourly") processed_data <- aggregate_by_frequency(processed_data, frequency)

  if (convert_units) {
    processed_data <- convert_era5_units(processed_data)
  }

  message("Processing completed successfully!")
  message(sprintf(fmt = "Final dataset: %s data points", nrow(x = processed_data)))
  processed_data
}

#' Download and process ERA5 data for a bounding box
#'
#' @param request_id Unique identifier for the data request.
#' @param variables List of ERA5 variables to download.
#' @param start_date Start date in "YYYY-MM-DD" format.
#' @param end_date End date in "YYYY-MM-DD" format.
#' @param north Northern latitude boundary.
#' @param south Southern latitude boundary.
#' @param east Eastern longitude boundary.
#' @param west Western longitude boundary.
#' @param dataset_type Type of dataset ("single" or "pressure").
#' @param pressure_levels Pressure levels for pressure dataset.
#' @param frequency Temporal frequency ("hourly", "daily", "monthly").
#' @param resolution Spatial resolution in degrees (default: 0.25).
#' @param save_raw Whether to save raw downloaded files.
#' @param output_dir Directory to save files (default: tempdir()).
#' @param use_cache Whether to use cached data if available (default: TRUE).
#' @param convert_units Whether to convert units to user-friendly formats (default: TRUE).
#'   When TRUE, temperature variables are returned in Celsius (converted from Kelvin)
#'   and precipitation variables are returned in mm (converted from meters).
#' @param verbose Whether to print detailed progress messages.
#' @param ... Arguments passed to the main function (used by aliases).
#'
#' @return data.frame with processed climate data. When `convert_units = TRUE`:
#'   \itemize{
#'     \item Temperature variables (e.g., 2m_temperature): Celsius
#'     \item Precipitation variables (e.g., total_precipitation): mm
#'     \item Other variables: original ERA5 units
#'   }
#' @export
#' @examples
#' \dontrun{
#' setup_cds_credentials(key = "your-cds-api-key")
#'
#' data <- era5ify_bbox(
#'   request_id = "my_request",
#'   variables = c("2m_temperature", "total_precipitation"),
#'   start_date = "2023-01-01",
#'   end_date = "2023-01-31",
#'   north = 40, south = 35, east = -70, west = -75
#' )
#' # Temperature is in Celsius, precipitation is in mm
#' }
era5ify_bbox <- function(request_id, variables, start_date, end_date,
                         north, south, east, west,
                         dataset_type = "single", pressure_levels = NULL,
                         frequency = "hourly", resolution = 0.25,
                         save_raw = FALSE, output_dir = tempdir(), use_cache = TRUE,
                         convert_units = TRUE, verbose = FALSE) {
  if (north <= south) stop("North boundary must be greater than south boundary")
  if (east <= west) stop("East boundary must be greater than west boundary")
  if (north > 90 || south < -90 || abs(east) > 180 || abs(west) > 180) {
    stop("Invalid coordinates. Latitude must be between -90 and 90, longitude between -180 and 180")
  }

  validated <- validate_era5_inputs(dataset_type, variables, start_date, end_date)
  area <- c(north, west, south, east)

  if (verbose) {
    message("Starting ERA5 data download for bounding box")
    message(sprintf(fmt = "Request ID: %s", request_id))
    message(sprintf(fmt = "Bounding box: N:%s, S:%s, E:%s, W:%s", north, south, east, west))
  }

  result <- download_era5_data(
    validated$dataset_type, variables, validated$start_dt,
    validated$end_dt, area, resolution, frequency,
    output_dir, request_id, pressure_levels, save_raw, use_cache, verbose
  )

  if (!is.null(result$data)) {
    processed_data <- result$data
  } else {
    processed_data <- filter_netcdf_by_bbox(result$file, north, south, east, west)
    if (!save_raw && file.exists(result$file)) unlink(result$file)
  }

  if (frequency == "monthly") {
    time_col <- intersect(c("datetime", "time"), colnames(processed_data))[1]
    if (!"year" %in% colnames(processed_data) && !is.na(time_col)) {
      processed_data$year <- as.integer(format(processed_data[[time_col]], "%Y"))
      processed_data$month <- as.integer(format(processed_data[[time_col]], "%m"))
    }
  } else if (frequency != "hourly") {
    processed_data <- aggregate_by_frequency(processed_data, frequency, verbose = verbose)
  }

  if (convert_units) {
    processed_data <- convert_era5_units(processed_data)
  }

  if (verbose) message("Processing completed successfully!")
  message(sprintf(fmt = "Downloaded %s data points", nrow(x = processed_data)))
  processed_data
}

#' Download and process ERA5 data for a point location
#'
#' @param request_id Unique identifier for the data request.
#' @param variables List of ERA5 variables to download.
#' @param start_date Start date in "YYYY-MM-DD" format.
#' @param end_date End date in "YYYY-MM-DD" format.
#' @param lat Latitude of the point location.
#' @param lon Longitude of the point location.
#' @param dataset_type Type of dataset ("single" or "pressure").
#' @param pressure_levels Pressure levels for pressure dataset.
#' @param frequency Temporal frequency ("hourly", "daily", "monthly").
#' @param save_raw Whether to save raw downloaded files.
#' @param output_dir Directory to save files (default: tempdir()).
#' @param use_cache Whether to use cached data if available (default: TRUE).
#' @param convert_units Whether to convert units to user-friendly formats (default: TRUE).
#'   When TRUE, temperature variables are returned in Celsius (converted from Kelvin)
#'   and precipitation variables are returned in mm (converted from meters).
#' @param verbose Whether to print detailed progress messages.
#' @param ... Arguments passed to the main function (used by aliases).
#'
#' @return data.frame with processed climate data. When `convert_units = TRUE`:
#'   \itemize{
#'     \item Temperature variables (e.g., 2m_temperature): Celsius
#'     \item Precipitation variables (e.g., total_precipitation): mm
#'     \item Other variables: original ERA5 units
#'   }
#' @export
#' @examples
#' \dontrun{
#' setup_cds_credentials(key = "your-cds-api-key")
#'
#' data <- era5ify_point(
#'   request_id = "my_request",
#'   variables = c("2m_temperature", "total_precipitation"),
#'   start_date = "2023-01-01",
#'   end_date = "2023-01-31",
#'   lat = 40.7128,
#'   lon = -74.0060
#' )
#' # Temperature is in Celsius, precipitation is in mm
#' }
era5ify_point <- function(request_id, variables, start_date, end_date, lat, lon,
                          dataset_type = "single", pressure_levels = NULL,
                          frequency = "hourly", save_raw = FALSE, output_dir = tempdir(),
                          use_cache = TRUE, convert_units = TRUE, verbose = FALSE) {
  if (lat < -90 || lat > 90) stop("Latitude must be between -90 and 90 degrees")
  if (lon < -180 || lon > 180) stop("Longitude must be between -180 and 180 degrees")

  validated <- validate_era5_inputs(dataset_type, variables, start_date, end_date)

  buffer <- 0.5
  area <- c(
    min(lat + buffer, 90), max(lon - buffer, -180),
    max(lat - buffer, -90), min(lon + buffer, 180)
  )

  message("Starting ERA5 data download for point location")
  message(sprintf(fmt = "Request ID: %s", request_id))
  message(sprintf(fmt = "Target point: (%s, %s)", lat, lon))

  chunks <- create_temporal_chunks(validated$start_dt, validated$end_dt, frequency, max_days_per_chunk = 31)

  if (length(x = chunks) > 1) {
    all_files <- vapply(seq_along(along.with = chunks), function(i) {
      download_func <- if (validated$dataset_type == "single") download_era5_single else download_era5_pressure
      download_func(
        variables = variables,
        pressure_levels = pressure_levels,
        start_date = chunks[[i]]$start,
        end_date = chunks[[i]]$end,
        area = area,
        resolution = 0.25,
        frequency = frequency,
        output_file = file.path(output_dir, sprintf(
          "%s_point_chunk%d_%s.nc",
          request_id, i, format(Sys.Date(), "%Y%m%d")
        )),
        use_cache = use_cache
      )
    }, character(1))

    combined_data <- combine_netcdf_files(all_files, verbose = verbose)

    split_data <- split(combined_data, list(combined_data$datetime, combined_data$variable))
    nearest_list <- lapply(split_data, function(group) {
      if (nrow(x = group) == 0) {
        return(NULL)
      }
      group[which.min(x = sqrt((group$latitude - lat)^2 + (group$longitude - lon)^2)), , drop = FALSE]
    })

    processed_data <- do.call(rbind, Filter(Negate(is.null), nearest_list))
    rownames(processed_data) <- NULL
    if (!save_raw) unlink(all_files)
  } else {
    download_func <- if (validated$dataset_type == "single") download_era5_single else download_era5_pressure
    downloaded_file <- download_func(
      variables = variables,
      pressure_levels = pressure_levels,
      start_date = validated$start_dt,
      end_date = validated$end_dt,
      area = area,
      resolution = 0.25,
      frequency = frequency,
      output_file = file.path(output_dir, sprintf(
        "%s_point_%s_%s.nc",
        request_id, validated$dataset_type, format(Sys.Date(), "%Y%m%d")
      )),
      use_cache = use_cache
    )

    processed_data <- extract_point_data(downloaded_file, lat, lon)
    if (!save_raw && file.exists(downloaded_file)) unlink(downloaded_file)
  }

  if (frequency != "hourly") processed_data <- aggregate_by_frequency(processed_data, frequency)

  if (convert_units) {
    processed_data <- convert_era5_units(processed_data)
  }

  message("Processing completed successfully!")
  message(sprintf(fmt = "Final dataset: %s data points", nrow(x = processed_data)))
  processed_data
}
