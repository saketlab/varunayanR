#' Process NetCDF file and extract data as data.frame
#'
#' Uses ncdf4 directly for fast reading, with stars as fallback.
#'
#' @param netcdf_file Character string path to NetCDF file
#' @return data.frame with processed climate data
process_netcdf_to_dataframe <- function(netcdf_file) {
  if (!file.exists(netcdf_file)) stop("NetCDF file not found: ", netcdf_file)

  message(sprintf(fmt = "Processing NetCDF file: %s", basename(path = netcdf_file)))

  start_time_total <- Sys.time()

  start_time <- Sys.time()
  df <- tryCatch(
    .read_ncdf4_fast(netcdf_file),
    error = function(e) {
      message(sprintf(fmt = "Fast ncdf4 read failed (%s), falling back to stars", e$message))
      .read_ncdf_stars_fallback(netcdf_file)
    }
  )
  elapsed <- as.numeric(x = difftime(Sys.time(), start_time, units = "secs"))
  message(sprintf(fmt = "[TIMER] NetCDF read: %ss", round(elapsed, 2)))

  df <- df[complete.cases(... = df), ]

  total_elapsed <- as.numeric(x = difftime(Sys.time(), start_time_total, units = "secs"))
  message(sprintf(fmt = "NetCDF processing completed. %s data points extracted.", nrow(x = df)))
  message(sprintf(fmt = "[TIMER] Total NetCDF processing: %ss", round(total_elapsed, 2)))

  df
}

#' Fast NetCDF reader using ncdf4 + data.table
#' @param netcdf_file Path to NetCDF file
#' @return data.frame in long format (datetime, latitude, longitude, variable, value)
#' @keywords internal
.read_ncdf4_fast <- function(netcdf_file) {
  nc <- ncdf4::nc_open(netcdf_file)
  on.exit(ncdf4::nc_close(nc))

  dim_names <- names(nc$dim)
  lat_name <- intersect(c("latitude", "lat"), dim_names)[1]
  lon_name <- intersect(c("longitude", "lon"), dim_names)[1]
  time_name <- intersect(c("valid_time", "time"), dim_names)[1]

  if (is.na(lat_name) || is.na(lon_name)) {
    stop("No latitude/longitude dimensions found")
  }

  lats <- ncdf4::ncvar_get(nc, lat_name)
  lons <- ncdf4::ncvar_get(nc, lon_name)

  times <- NULL
  time_units <- NULL
  if (!is.na(time_name)) {
    times <- ncdf4::ncvar_get(nc, time_name)
    time_units <- nc$dim[[time_name]]$units
  }

  data_vars <- setdiff(names(nc$var), c(.NC_METADATA_VARS, lat_name, lon_name, time_name))
  if (length(data_vars) == 0) stop("No data variables found in NetCDF")

  # expand.grid (not CJ) to match ncvar_get's column-major dimension order
  if (!is.null(times)) {
    grid_dt <- data.table::as.data.table(expand.grid(
      longitude = lons,
      latitude = lats,
      time_idx = seq_along(times)
    ))
    grid_dt[, datetime := times[time_idx]]
    grid_dt[, time_idx := NULL]
  } else {
    grid_dt <- data.table::as.data.table(expand.grid(
      longitude = lons, latitude = lats
    ))
    grid_dt[, datetime := as.POSIXct("2023-01-01 12:00:00", tz = "UTC")]
  }

  for (var in data_vars) {
    var_data <- ncdf4::ncvar_get(nc, var)
    data.table::set(grid_dt, j = var, value = as.vector(var_data))
  }

  if (!is.null(times) && is.numeric(grid_dt$datetime)) {
    grid_dt[, datetime := .parse_nc_time(datetime, time_units)]
  }

  id_cols <- c("datetime", "latitude", "longitude")
  df <- data.table::melt(
    grid_dt,
    id.vars = id_cols,
    measure.vars = data_vars,
    variable.name = "variable",
    value.name = "value",
    variable.factor = FALSE
  )

  base_cols <- c("datetime", "latitude", "longitude", "variable", "value")
  other_cols <- setdiff(names(df), base_cols)
  data.table::setcolorder(df, c(base_cols, other_cols))

  as.data.frame(df)
}

#' Parse numeric time values from NetCDF
#' @param time_vals Numeric time values
#' @param time_units Character string from the NetCDF time dimension units attribute
#'   (e.g. "seconds since 1970-01-01", "hours since 1900-01-01")
#' @return POSIXct vector
#' @keywords internal
.parse_nc_time <- function(time_vals, time_units = NULL) {
  if (!is.null(time_units) && grepl("since", time_units, ignore.case = TRUE)) {
    parts <- strsplit(time_units, "\\s+since\\s+", perl = TRUE)[[1]]
    if (length(parts) == 2) {
      unit_str <- tolower(trimws(parts[1]))
      origin_date <- sub("\\s.*", "", trimws(parts[2]))

      mult <- switch(unit_str,
        "seconds" = 1,
        "minutes" = 60,
        "hours"   = 3600,
        "days"    = 86400,
        NULL
      )

      if (!is.null(mult)) {
        result <- tryCatch(
          as.POSIXct(time_vals * mult, origin = origin_date, tz = "UTC"),
          error = function(e) NULL
        )
        if (!is.null(result) && all(is.finite(result))) {
          return(result)
        }
      }
    }
  }

  for (spec in list(
    list(mult = 1, origin = "1970-01-01"),
    list(mult = 3600, origin = "1900-01-01"),
    list(mult = 3600, origin = "1979-01-01"),
    list(mult = 86400, origin = "1900-01-01")
  )) {
    result <- tryCatch(
      as.POSIXct(time_vals * spec$mult, origin = spec$origin, tz = "UTC"),
      error = function(e) NULL
    )
    if (!is.null(result) && all(is.finite(result)) &&
      all(result > as.POSIXct("1800-01-01", tz = "UTC")) &&
      all(result < as.POSIXct("2100-01-01", tz = "UTC"))) {
      return(result)
    }
  }

  warning("Using sequential dates fallback", call. = FALSE)
  n_times <- length(unique(time_vals))
  seq(as.POSIXct("2023-01-01", tz = "UTC"),
    by = "day",
    length.out = n_times
  )[as.numeric(as.factor(time_vals))]
}

#' Stars-based NetCDF reader (fallback for non-standard files)
#' @param netcdf_file Path to NetCDF file
#' @return data.frame in long format
#' @keywords internal
.read_ncdf_stars_fallback <- function(netcdf_file) {
  nc_vars <- tryCatch(
    {
      nc_tmp <- ncdf4::nc_open(netcdf_file)
      tryCatch(
        setdiff(names(nc_tmp$var), .NC_METADATA_VARS),
        finally = ncdf4::nc_close(nc_tmp)
      )
    },
    error = function(e) NULL
  )

  nc_data <- tryCatch(
    if (!is.null(nc_vars) && length(nc_vars) > 0) {
      read_ncdf(netcdf_file, var = nc_vars)
    } else {
      read_ncdf(netcdf_file)
    },
    error = function(e) {
      if (grepl(pattern = "cannot convert.*into seconds", e$message)) {
        tryCatch(
          read_ncdf(netcdf_file, proxy = FALSE, make_time = FALSE),
          error = function(e2) .read_ncdf4_fast(netcdf_file)
        )
      } else {
        stop(e)
      }
    }
  )

  df <- as.data.frame(nc_data)
  names(df) <- gsub(pattern = "\\.", replacement = "_", names(df))

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
    df$datetime <- .parse_nc_time(df$datetime)
  }

  var_cols <- setdiff(x = names(x = df), y = c("longitude", "latitude", "datetime"))

  if (length(x = var_cols) > 1) {
    DT <- data.table::as.data.table(df)
    df <- as.data.frame(data.table::melt(
      DT,
      id.vars = c("datetime", "latitude", "longitude"),
      measure.vars = var_cols,
      variable.name = "variable",
      value.name = "value",
      variable.factor = FALSE
    ))
  } else if (length(x = var_cols) == 1) {
    df$variable <- var_cols[1]
    names(df)[names(df) == var_cols[1]] <- "value"
  }

  base_cols <- c("datetime", "latitude", "longitude", "variable", "value")
  if (all(base_cols %in% names(df))) {
    other_cols <- setdiff(names(df), base_cols)
    df <- df[, c(base_cols, other_cols), drop = FALSE]
  }

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

#' Filter data.frame by GeoJSON polygon
#'
#' Tests only unique (lat, lon) coordinates against the polygon, then joins
#' back to full dataset via data.table keyed semi-join.
#'
#' @param df data.frame with latitude and longitude columns
#' @param geojson_file Character string path to GeoJSON file
#' @return data.frame with spatially filtered data
filter_dataframe_by_geojson <- function(df, geojson_file) {
  start_time <- Sys.time()
  n_before <- nrow(x = df)
  message(sprintf(fmt = "Starting spatial filtering (%s points)...", n_before))

  if (!grepl(pattern = "^https?://", geojson_file) && !file.exists(geojson_file)) {
    stop("GeoJSON file not found: ", geojson_file)
  }

  step_start <- Sys.time()
  geojson_sf <- st_read(geojson_file, quiet = TRUE)
  elapsed <- as.numeric(x = difftime(Sys.time(), step_start, units = "secs"))
  message(sprintf(fmt = "[TIMER] Load GeoJSON: %ss", round(elapsed, 3)))

  step_start <- Sys.time()
  if (is.na(st_crs(geojson_sf))) {
    geojson_sf <- st_set_crs(geojson_sf, 4326)
  }
  geojson_sf <- st_transform(geojson_sf, 4326)

  old_use_s2 <- sf_use_s2()
  sf_use_s2(FALSE)
  on.exit(sf_use_s2(old_use_s2))

  geojson_sf <- st_make_valid(geojson_sf)

  geom_types <- unique(x = as.character(x = st_geometry_type(geojson_sf)))
  if ("GEOMETRYCOLLECTION" %in% geom_types) {
    geojson_sf <- st_collection_extract(geojson_sf, "POLYGON")
  }

  geojson_union <- st_union(geojson_sf)

  n_coords <- tryCatch(
    {
      coords <- st_coordinates(geojson_union)
      if (is.matrix(coords)) nrow(x = coords) else 0
    },
    error = function(e) length(x = st_geometry(geojson_union)) * 100
  )

  if (n_coords > 10000) {
    message(sprintf(fmt = "Simplifying complex geometry (%s vertices)...", n_coords))
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
  df <- df[df$latitude >= bbox["ymin"] & df$latitude <= bbox["ymax"] &
    df$longitude >= bbox["xmin"] & df$longitude <= bbox["xmax"], ]
  elapsed <- as.numeric(x = difftime(Sys.time(), step_start, units = "secs"))
  message(sprintf(fmt = "Bbox filter: kept %s of %s points (%s%%)", nrow(x = df), n_before, round(100 * nrow(x = df) / n_before, 1)))
  message(sprintf(fmt = "[TIMER] Bbox filter: %ss", round(elapsed, 3)))

  if (nrow(x = df) == 0) {
    warning("No points within bounding box!", call. = FALSE)
    return(df)
  }

  step_start <- Sys.time()
  unique_coords <- unique(df[, c("latitude", "longitude")])
  n_unique <- nrow(unique_coords)
  message(sprintf(fmt = "Testing %s unique coordinates (from %s rows)...", n_unique, nrow(x = df)))

  points_sf <- st_as_sf(unique_coords, coords = c("longitude", "latitude"), crs = 4326)

  inside <- st_intersects(points_sf, geojson_union, sparse = TRUE)
  inside_mask <- lengths(inside) > 0
  intersect_elapsed <- as.numeric(x = difftime(Sys.time(), step_start, units = "secs"))
  message(sprintf(fmt = "[TIMER] Spatial test (%s unique pts): %ss (%s inside)", n_unique, round(intersect_elapsed, 3), sum(inside_mask)))

  inside_coords <- unique_coords[inside_mask, ]

  step_start <- Sys.time()
  dt_df <- data.table::as.data.table(df)
  dt_inside <- data.table::as.data.table(inside_coords)
  data.table::setkey(dt_df, latitude, longitude)
  data.table::setkey(dt_inside, latitude, longitude)
  filtered_df <- as.data.frame(dt_df[dt_inside, nomatch = NULL])
  join_elapsed <- as.numeric(x = difftime(Sys.time(), step_start, units = "secs"))
  message(sprintf(fmt = "[TIMER] Semi-join back: %ss", round(join_elapsed, 3)))

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
