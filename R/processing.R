#' NetCDF processing functions for ERA5 data

#' Process NetCDF file and extract data as data.frame
#'
#' @param netcdf_file Character string path to NetCDF file
#' @return data.frame with processed climate data
process_netcdf_to_dataframe <- function(netcdf_file) {
  if (!file.exists(netcdf_file)) stop("NetCDF file not found: ", netcdf_file)

  message(sprintf(fmt = "Processing NetCDF file: %s", basename(path = netcdf_file)))

  start_time_total <- Sys.time()

  start_time <- Sys.time()
  nc_data <- tryCatch(
    read_ncdf(netcdf_file),
    error = function(e) {
      # Handle time conversion failures with fallback chain
      if (grepl(pattern = "cannot convert.*into seconds", e$message)) {
        tryCatch(
          read_ncdf(netcdf_file, proxy = FALSE, make_time = FALSE),
          error = function(e2) read_netcdf_with_ncdf4(netcdf_file)
        )
      } else {
        stop(e)
      }
    }
  )
  elapsed <- as.numeric(x = difftime(Sys.time(), start_time, units = "secs"))
  message(sprintf(fmt = "[TIMER] NetCDF read: %ss", round(elapsed, 2)))

  start_time <- Sys.time()
  df <- as.data.frame(nc_data)
  names(df) <- gsub(pattern = "\\.", replacement = "_", names(df))
  elapsed <- as.numeric(x = difftime(Sys.time(), start_time, units = "secs"))
  message(sprintf(fmt = "[TIMER] Convert to data.frame: %ss", round(elapsed, 2)))

  name_map <- c(
    x = "longitude", y = "latitude", time = "datetime",
    lon = "longitude", lat = "latitude"
  )
  for (old in names(name_map)) {
    if (old %in% names(df)) names(df)[names(df) == old] <- name_map[old]
  }

  if (!"datetime" %in% names(df)) {
    time_cols <- names(df)[grepl(pattern = "time|valid_time", names(df), ignore.case = TRUE)]
    if (length(x = time_cols) > 0) {
      names(df)[names(df) == time_cols[1]] <- "datetime"
    }
  }

  if ("datetime" %in% names(df) && is.numeric(df$datetime)) {
    # Try common ERA5 time origins (hours since epoch)
    for (spec in list(
      list(mult = 3600, origin = "1900-01-01"),
      list(mult = 3600, origin = "1979-01-01"),
      list(mult = 86400, origin = "1900-01-01")
    )) {
      result <- tryCatch(as.POSIXct(x = df$datetime * spec$mult, origin = spec$origin, tz = "UTC"),
        error = function(e) NULL
      )
      if (!is.null(result)) {
        df$datetime <- result
        break
      }
    }

    if (is.numeric(df$datetime)) {
      warning("Using sequential dates fallback", call. = FALSE)
      n_times <- length(x = unique(x = df$datetime))
      df$datetime <- seq(as.POSIXct(x = "2023-01-01", tz = "UTC"),
        by = "day",
        length.out = n_times
      )[as.numeric(x = as.factor(x = df$datetime))]
    }
  }

  var_cols <- setdiff(x = names(x = df), y = c("longitude", "latitude", "datetime"))

  if (length(x = var_cols) > 1) {
    start_time <- Sys.time()
    df_list <- list()
    for (i in seq_along(along.with = var_cols)) {
      var_col <- var_cols[i]
      temp_df <- df[, setdiff(x = names(x = df), y = var_cols), drop = FALSE]
      temp_df$variable <- var_col
      temp_df$value <- df[[var_col]]
      df_list[[i]] <- temp_df
    }
    df <- do.call(rbind, df_list)
    elapsed <- as.numeric(x = difftime(Sys.time(), start_time, units = "secs"))
    message(sprintf(fmt = "[TIMER] Reshape to long format: %ss", round(elapsed, 2)))
  } else if (length(x = var_cols) == 1) {
    df$variable <- var_cols[1]
    names(df)[names(df) == var_cols[1]] <- "value"
  }

  if (all(c("datetime", "latitude", "longitude", "variable", "value") %in% names(df))) {
    base_cols <- c("datetime", "latitude", "longitude", "variable", "value")
    other_cols <- setdiff(x = names(x = df), y = base_cols)
    df <- df[, c(base_cols, other_cols), drop = FALSE]
  }

  df <- df[complete.cases(... = df), ]

  total_elapsed <- as.numeric(x = difftime(Sys.time(), start_time_total, units = "secs"))
  message(sprintf(fmt = "NetCDF processing completed. %s data points extracted.", nrow(x = df)))
  message(sprintf(fmt = "[TIMER] Total NetCDF processing: %ss", round(total_elapsed, 2)))

  df
}

#' Filter NetCDF data by spatial boundaries (bounding box)
#'
#' @param netcdf_file Character string path to NetCDF file
#' @param north Northern latitude boundary
#' @param south Southern latitude boundary
#' @param east Eastern longitude boundary
#' @param west Western longitude boundary
#' @return data.frame with spatially filtered data
filter_netcdf_by_bbox <- function(netcdf_file, north, south, east, west) {
  df <- process_netcdf_to_dataframe(netcdf_file)
  filtered_df <- df[
    df$latitude >= south & df$latitude <= north &
      df$longitude >= west & df$longitude <= east,
  ]
  message(sprintf(fmt = "Spatial filtering applied: %s points within bounding box", nrow(x = filtered_df)))
  filtered_df
}

#' Filter NetCDF data by GeoJSON polygon
#'
#' @param netcdf_file Character string path to NetCDF file
#' @param geojson_file Character string path to GeoJSON file
#' @return data.frame with spatially filtered data
filter_netcdf_by_geojson <- function(netcdf_file, geojson_file) {
  if (!grepl(pattern = "^https?://", geojson_file) && !file.exists(geojson_file)) {
    stop("GeoJSON file not found: ", geojson_file)
  }
  df <- process_netcdf_to_dataframe(netcdf_file)
  filter_dataframe_by_geojson(df, geojson_file)
}

#' Filter data.frame by GeoJSON polygon (optimized)
#'
#' Uses geometry simplification and spatial pre-aggregation for large datasets.
#'
#' @param df data.frame with latitude and longitude columns
#' @param geojson_file Character string path to GeoJSON file
#' @return data.frame with spatially filtered data
filter_dataframe_by_geojson <- function(df, geojson_file) {
  start_time <- Sys.time()
  message(sprintf(fmt = "Starting optimized spatial filtering (%s points)...", nrow(x = df)))

  if (!grepl(pattern = "^https?://", geojson_file) && !file.exists(geojson_file)) {
    stop("GeoJSON file not found: ", geojson_file)
  }

  message("Loading GeoJSON boundary...")
  step_start <- Sys.time()
  geojson_sf <- st_read(geojson_file, quiet = TRUE)
  elapsed <- as.numeric(x = difftime(Sys.time(), step_start, units = "secs"))
  message(sprintf(fmt = "[TIMER] Load GeoJSON: %ss", round(elapsed, 3)))

  step_start <- Sys.time()
  if (is.na(st_crs(geojson_sf))) {
    geojson_sf <- st_set_crs(geojson_sf, 4326)
  }
  geojson_sf <- st_transform(geojson_sf, 4326)

  # Disable s2 spherical geometry for union operation
  old_use_s2 <- sf_use_s2()
  sf_use_s2(FALSE)
  on.exit(sf_use_s2(old_use_s2))

  message("Preparing boundary polygon...")
  geojson_sf <- st_make_valid(geojson_sf)

  geom_types <- unique(x = as.character(x = st_geometry_type(geojson_sf)))
  if ("GEOMETRYCOLLECTION" %in% geom_types) {
    message("Converting GEOMETRYCOLLECTION to polygons...")
    geojson_sf <- st_collection_extract(geojson_sf, "POLYGON")
  }

  geojson_union <- st_union(geojson_sf)

  # Simplify complex geometries for faster intersection tests
  n_coords <- tryCatch(
    {
      coords <- st_coordinates(geojson_union)
      if (is.matrix(coords)) nrow(x = coords) else 0
    },
    error = function(e) length(x = st_geometry(geojson_union)) * 100
  )

  if (n_coords > 10000) {
    message(sprintf(fmt = "Simplifying complex geometry (%s vertices) for faster processing...", n_coords))
    geojson_union <- st_simplify(geojson_union, preserveTopology = TRUE, dTolerance = 0.01)

    n_coords_after <- tryCatch(
      {
        coords <- st_coordinates(geojson_union)
        if (is.matrix(coords)) nrow(x = coords) else 0
      },
      error = function(e) n_coords
    )

    message(sprintf(fmt = "Simplified to %s vertices (%s%% of original)", n_coords_after, round(100 * n_coords_after / n_coords, 1)))
  }

  elapsed <- as.numeric(x = difftime(Sys.time(), step_start, units = "secs"))
  message(sprintf(fmt = "[TIMER] Prepare boundary: %ss", round(elapsed, 3)))

  step_start <- Sys.time()
  bbox <- st_bbox(geojson_union)
  message("Pre-filtering by bounding box...")
  n_before <- nrow(x = df)
  df <- df[df$latitude >= bbox["ymin"] & df$latitude <= bbox["ymax"] &
    df$longitude >= bbox["xmin"] & df$longitude <= bbox["xmax"], ]
  elapsed <- as.numeric(x = difftime(Sys.time(), step_start, units = "secs"))
  message(sprintf(fmt = "Bbox filter: kept %s of %s points (%s%%)", nrow(x = df), n_before, round(100 * nrow(x = df) / n_before, 1)))
  message(sprintf(fmt = "[TIMER] Bbox filter: %ss", round(elapsed, 3)))

  if (nrow(x = df) == 0) {
    warning("No points within bounding box!", call. = FALSE)
    return(df)
  }

  # Pre-aggregate spatially for very large datasets
  spatial_aggregated <- FALSE
  if (nrow(x = df) > 500000) {
    message(sprintf(fmt = "Dataset very large (%s points). Pre-aggregating by unique spatial locations...", nrow(x = df)))
    step_start <- Sys.time()

    df_original <- df
    df <- df %>%
      group_by(latitude, longitude) %>%
      summarise(
        n_points = n(),
        value = mean(value, na.rm = TRUE),
        .groups = "drop"
      )

    spatial_aggregated <- TRUE
    elapsed <- as.numeric(x = difftime(Sys.time(), step_start, units = "secs"))
    message(sprintf(fmt = "Pre-aggregated to %s unique spatial locations (%s%% of original) in %ss", nrow(x = df), round(100 * nrow(x = df) / nrow(x = df_original), 1), round(elapsed, 2)))
  }

  message("Converting to spatial points for polygon intersection...")

  if (nrow(x = df) > 50000) {
    batch_size <- 25000
    n_batches <- ceiling(nrow(x = df) / batch_size)
    message(sprintf(fmt = "Processing %s batches of %s points each...", n_batches, batch_size))

    filtered_list <- list()
    batch_times <- numeric(n_batches)

    for (i in seq_len(length.out = n_batches)) {
      start_idx <- (i - 1) * batch_size + 1
      end_idx <- min(i * batch_size, nrow(x = df))

      eta_msg <- ""
      if (i > 1) {
        avg_time <- mean(batch_times[1:(i - 1)])
        remaining_batches <- n_batches - i + 1
        eta_seconds <- avg_time * remaining_batches
        if (eta_seconds < 60) {
          eta_msg <- sprintf(fmt = " [ETA: ~%.0f sec]", eta_seconds)
        } else {
          eta_msg <- sprintf(fmt = " [ETA: ~%.1f min]", eta_seconds / 60)
        }
      }

      message(sprintf(fmt = "Batch %s/%s (%s%%): filtering points %s to %s...%s", i, n_batches, round(100 * i / n_batches, 1), start_idx, end_idx, eta_msg))
      batch_start <- Sys.time()

      batch_df <- df[start_idx:end_idx, ]

      sf_start <- Sys.time()
      points_sf <- st_as_sf(batch_df, coords = c("longitude", "latitude"), crs = 4326)
      sf_elapsed <- as.numeric(x = difftime(Sys.time(), sf_start, units = "secs"))
      message(sprintf(fmt = "  [TIMER] st_as_sf: %ss", round(sf_elapsed, 2)))

      intersect_start <- Sys.time()
      inside_points <- st_intersects(points_sf, geojson_union, sparse = FALSE)[, 1]
      intersect_elapsed <- as.numeric(x = difftime(Sys.time(), intersect_start, units = "secs"))
      message(sprintf(fmt = "  [TIMER] st_intersects: %ss", round(intersect_elapsed, 2)))

      filtered_list[[i]] <- batch_df[inside_points, ]

      batch_elapsed <- as.numeric(x = difftime(Sys.time(), batch_start, units = "secs"))
      batch_times[i] <- batch_elapsed
      message(sprintf(fmt = "Batch %s: kept %s of %s points (%ss)", i, sum(inside_points), nrow(x = batch_df), round(batch_elapsed, 2)))
    }

    message(sprintf(fmt = "Batch processing complete. Average time per batch: %ss", round(mean(batch_times), 2)))
    filtered_df <- do.call(rbind, filtered_list)
  } else {
    message("Creating spatial points (this may take 30-60 seconds)...")
    sf_start <- Sys.time()
    points_sf <- st_as_sf(df, coords = c("longitude", "latitude"), crs = 4326)
    sf_elapsed <- as.numeric(x = difftime(Sys.time(), sf_start, units = "secs"))
    message(sprintf(fmt = "[TIMER] st_as_sf: %ss", round(sf_elapsed, 2)))

    message("Checking which points are within boundaries...")
    intersect_start <- Sys.time()
    inside_points <- st_intersects(points_sf, geojson_union, sparse = FALSE)[, 1]
    intersect_elapsed <- as.numeric(x = difftime(Sys.time(), intersect_start, units = "secs"))
    message(sprintf(fmt = "[TIMER] st_intersects: %ss", round(intersect_elapsed, 2)))

    filtered_df <- df[inside_points, ]
  }

  # Expand back to original data if we pre-aggregated
  if (spatial_aggregated && exists("df_original")) {
    message("Expanding back to original temporal data...")
    step_start <- Sys.time()

    filtered_df <- df_original %>%
      semi_join(
        filtered_df %>% select(latitude, longitude),
        by = c("latitude", "longitude")
      )

    elapsed <- as.numeric(x = difftime(Sys.time(), step_start, units = "secs"))
    message(sprintf(fmt = "Expanded to %s original points in %ss", nrow(x = filtered_df), round(elapsed, 2)))
  }

  elapsed_time <- as.numeric(x = difftime(Sys.time(), start_time, units = "secs"))
  message(sprintf(fmt = "Spatial filtering complete in %ss: %s of %s points retained (%s%%)", round(elapsed_time, 1), nrow(x = filtered_df), n_before, round(100 * nrow(x = filtered_df) / n_before, 1)))

  filtered_df
}

#' Extract data for specific point location (nearest neighbor)
#'
#' @param netcdf_file Character string path to NetCDF file
#' @param target_lat Target latitude
#' @param target_lon Target longitude
#' @return data.frame with data for nearest point
extract_point_data <- function(netcdf_file, target_lat, target_lon) {
  df <- process_netcdf_to_dataframe(netcdf_file)

  distances <- sqrt((df$latitude - target_lat)^2 + (df$longitude - target_lon)^2)
  nearest_idx <- which.min(x = distances)
  nearest_distance <- min(distances)

  nearest_coords <- df[nearest_idx, c("latitude", "longitude")]
  point_data <- df %>%
    filter(
      latitude == nearest_coords$latitude[1],
      longitude == nearest_coords$longitude[1]
    )

  message(sprintf(fmt = "Point extraction: nearest grid point at (%s, %s)", round(nearest_coords$latitude[1], 3), round(nearest_coords$longitude[1], 3)))
  message(sprintf(fmt = "Distance from target: %s degrees", round(nearest_distance, 3)))

  point_data
}

#' Aggregate data by temporal frequency
#'
#' @param data data.frame with datetime column
#' @param frequency Character string: "daily", "monthly", "yearly"
#' @param verbose Logical indicating whether to print progress messages
#' @return data.frame with temporally aggregated data
aggregate_by_frequency <- function(data, frequency, verbose = FALSE) {
  if (!"datetime" %in% names(data)) {
    warning("No datetime column found, returning original data", call. = FALSE)
    return(data)
  }

  if (frequency == "hourly") {
    return(data)
  }

  if (verbose) {
    message("Starting temporal aggregation...")
    message(sprintf(fmt = "Input: %s data points", nrow(x = data)))
  }

  start_time_agg <- Sys.time()

  if (requireNamespace("data.table", quietly = TRUE)) {
    step_start <- Sys.time()
    DT <- as.data.table(data)
    elapsed <- as.numeric(x = difftime(Sys.time(), step_start, units = "secs"))
    if (verbose) message(sprintf(fmt = "[TIMER] Convert to data.table: %ss", round(elapsed, 3)))

    step_start <- Sys.time()
    if (frequency == "daily") {
      DT[, time_group := as.Date(x = datetime)]
    } else if (frequency == "monthly") {
      DT[, time_group := year(datetime) * 100L + month(datetime)]
    } else if (frequency == "yearly") {
      DT[, time_group := year(datetime)]
    } else {
      DT[, time_group := as.Date(x = datetime)]
    }
    elapsed <- as.numeric(x = difftime(Sys.time(), step_start, units = "secs"))
    if (verbose) message(sprintf(fmt = "[TIMER] Create time groups: %ss", round(elapsed, 3)))

    step_start <- Sys.time()
    aggregated <- DT[, .(
      datetime = min(datetime),
      value = mean(value, na.rm = TRUE)
    ), by = .(time_group, latitude, longitude, variable)]
    elapsed <- as.numeric(x = difftime(Sys.time(), step_start, units = "secs"))
    if (verbose) message(sprintf(fmt = "[TIMER] data.table aggregation: %ss", round(elapsed, 3)))

    step_start <- Sys.time()
    setorder(aggregated, datetime, latitude, longitude, variable)
    elapsed <- as.numeric(x = difftime(Sys.time(), step_start, units = "secs"))
    if (verbose) message(sprintf(fmt = "[TIMER] Sorting: %ss", round(elapsed, 3)))

    aggregated[, time_group := NULL]
    aggregated <- as.data.frame(aggregated)
  } else {
    data$time_group <- switch(frequency,
      "daily" = as.Date(x = data$datetime),
      "monthly" = format(data$datetime, "%Y-%m"),
      "yearly" = format(data$datetime, "%Y"),
      as.Date(x = data$datetime)
    )

    aggregated <- data %>%
      group_by(time_group, latitude, longitude, variable) %>%
      summarise(
        datetime = min(datetime),
        value = mean(value, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      select(datetime, latitude, longitude, variable, value) %>%
      arrange(datetime, latitude, longitude, variable) %>%
      as.data.frame()
  }

  total_agg_time <- as.numeric(x = difftime(Sys.time(), start_time_agg, units = "secs"))
  if (verbose) {
    message("Temporal aggregation complete!")
    message(sprintf(fmt = "Output: %s data points (reduced by %s%%)", nrow(x = aggregated), round(100 * (1 - nrow(x = aggregated) / nrow(x = data)), 1)))
    message(sprintf(fmt = "[TIMER] Total aggregation time: %ss", round(total_agg_time, 2)))
  }

  aggregated
}

#' Apply temporal chunking for large date ranges
#'
#' @param start_date Start date
#' @param end_date End date
#' @param frequency Temporal frequency
#' @param max_days_per_chunk Maximum days per chunk
#' @return List of date pairs for chunked processing
create_temporal_chunks <- function(start_date, end_date, frequency, max_days_per_chunk = 31) {
  start_dt <- as.Date(x = start_date)
  end_dt <- as.Date(x = end_date)
  total_days <- as.numeric(x = end_dt - start_dt) + 1

  if (total_days <= max_days_per_chunk) {
    return(list(list(start = start_dt, end = end_dt)))
  }

  chunks <- list()
  current_start <- start_dt

  while (current_start <= end_dt) {
    current_end <- min(current_start + max_days_per_chunk - 1, end_dt)
    chunks[[length(x = chunks) + 1]] <- list(start = current_start, end = current_end)
    current_start <- current_end + 1
  }

  message(sprintf(fmt = "Large date range detected. Processing in %s chunks.", length(x = chunks)))
  chunks
}

#' Combine multiple NetCDF files into single data.frame
#'
#' @param netcdf_files Character vector of NetCDF file paths
#' @param verbose Logical indicating whether to print progress messages
#' @return data.frame with combined data from all files
combine_netcdf_files <- function(netcdf_files, verbose = FALSE) {
  valid_files <- netcdf_files[file.exists(netcdf_files)]
  if (length(x = valid_files) == 0) stop("No valid NetCDF files found")

  if (verbose) message(sprintf(fmt = "Combining %s NetCDF files...", length(x = valid_files)))

  all_data <- list()
  for (i in seq_along(along.with = valid_files)) {
    if (verbose) message(sprintf(fmt = "Processing file %s/%s: %s", i, length(x = valid_files), basename(path = valid_files[i])))
    all_data[[i]] <- process_netcdf_to_dataframe(valid_files[i])
  }

  combined_df <- do.call(rbind, all_data)

  if (nrow(x = combined_df) > 0) {
    combined_df <- combined_df[!duplicated(combined_df), ]
    order_idx <- order(combined_df$datetime, combined_df$latitude, combined_df$longitude, combined_df$variable)
    combined_df <- combined_df[order_idx, ]
    rownames(combined_df) <- NULL
  }

  message(sprintf(fmt = "Combined data: %s total data points", nrow(x = combined_df)))
  combined_df
}

#' Read NetCDF using ncdf4 as fallback when stars fails
#'
#' @param netcdf_file Path to NetCDF file
#' @return data.frame with processed data
read_netcdf_with_ncdf4 <- function(netcdf_file) {
  nc <- nc_open(netcdf_file)

  tryCatch({
    dims <- names(nc$dim)
    message(sprintf(fmt = "NetCDF dimensions: %s", paste(dims, collapse = ", ")))

    vars <- names(nc$var)
    coord_vars <- c("lat", "latitude", "lon", "longitude", "time", "valid_time")
    data_vars <- vars[!vars %in% coord_vars]
    message(sprintf(fmt = "Data variables: %s", paste(data_vars, collapse = ", ")))

    if ("latitude" %in% names(nc$dim)) {
      lats <- ncvar_get(nc, "latitude")
    } else if ("lat" %in% names(nc$dim)) {
      lats <- ncvar_get(nc, "lat")
    } else {
      stop("No latitude dimension found")
    }

    if ("longitude" %in% names(nc$dim)) {
      lons <- ncvar_get(nc, "longitude")
    } else if ("lon" %in% names(nc$dim)) {
      lons <- ncvar_get(nc, "lon")
    } else {
      stop("No longitude dimension found")
    }

    times <- NULL
    if ("time" %in% names(nc$dim)) {
      times <- ncvar_get(nc, "time")
    } else if ("valid_time" %in% names(nc$dim)) {
      times <- ncvar_get(nc, "valid_time")
    }

    all_data <- list()

    for (var in data_vars) {
      var_data <- ncvar_get(nc, var)

      if (!is.null(times)) {
        coords <- expand.grid(
          longitude = lons,
          latitude = lats,
          time_idx = seq_along(along.with = times)
        )
        coords$datetime <- times[coords$time_idx]
        coords$time_idx <- NULL
        coords$value <- as.vector(var_data)
      } else {
        coords <- expand.grid(longitude = lons, latitude = lats)
        coords$datetime <- as.POSIXct(x = "2023-01-01 12:00:00", tz = "UTC")
        coords$value <- as.vector(var_data)
      }

      coords$variable <- var
      all_data[[var]] <- coords
    }

    result_df <- do.call(rbind, all_data)
    rownames(result_df) <- NULL

    if (!is.null(times) && is.numeric(result_df$datetime)) {
      tryCatch(
        {
          result_df$datetime <- as.POSIXct(x = result_df$datetime * 3600, origin = "1900-01-01", tz = "UTC")
        },
        error = function(e) {
          unique_times <- sort(x = unique(x = result_df$datetime))
          time_map <- seq(as.POSIXct(x = "2023-01-01 12:00:00", tz = "UTC"), by = "day", length.out = length(x = unique_times))
          names(time_map) <- unique_times
          result_df$datetime <- time_map[as.character(x = result_df$datetime)]
        }
      )
    }

    result_df
  }, finally = {
    nc_close(nc)
  })
}
