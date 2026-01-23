#' IMD data processing functions

#' Read IMD binary temperature file
#'
#' Reads IMD binary temperature data (max or min) and converts to data.frame.
#'
#' @param file_path Path to IMD binary file (.grd).
#' @param var_type Variable type: "tmax" or "tmin".
#' @param year Year of the data.
#' @return data.frame with columns: date, latitude, longitude, temperature
#' @export
#' @examples
#' \dontrun{
#' tmax_data <- read_imd_temperature("imd_tmax_1.0_2023.grd", "tmax", 2023)
#' }
read_imd_temperature <- function(file_path, var_type, year) {
  if (!file.exists(file_path)) stop("File not found: ", file_path)

  dataset_id <- paste0(var_type, "_1.0")
  grid_specs <- get_imd_grid_specs(dataset_id)

  message(sprintf(fmt = "Reading IMD %s data for %s", var_type, year))
  message(sprintf(fmt = "Grid: %sx%s points", grid_specs$nlat, grid_specs$nlon))

  n_days <- if (is_leap_year(year)) 366 else 365

  con <- file(file_path, "rb")
  tryCatch({
    n_values <- n_days * grid_specs$nlat * grid_specs$nlon
    raw_data <- readBin(con, "numeric", n = n_values, size = 4, endian = "little")

    if (length(x = raw_data) != n_values) {
      warning(sprintf(fmt = "Expected %s values but got %s", n_values, length(x = raw_data)), call. = FALSE)
    }
  }, finally = {
    close(con)
  })

  dates <- seq(as.Date(x = paste0(year, "-01-01")), as.Date(x = paste0(year, "-12-31")), by = "day")

  lats <- seq(grid_specs$lat_start, grid_specs$lat_end, by = grid_specs$resolution)
  lons <- seq(grid_specs$lon_start, grid_specs$lon_end, by = grid_specs$resolution)

  if (length(x = lats) != grid_specs$nlat) {
    warning(sprintf(fmt = "Latitude grid mismatch: expected %s, got %s", grid_specs$nlat, length(x = lats)), call. = FALSE)
    lats <- lats[1:grid_specs$nlat]
  }
  if (length(x = lons) != grid_specs$nlon) {
    warning(sprintf(fmt = "Longitude grid mismatch: expected %s, got %s", grid_specs$nlon, length(x = lons)), call. = FALSE)
    lons <- lons[1:grid_specs$nlon]
  }

  data_array <- array(raw_data, dim = c(grid_specs$nlon, grid_specs$nlat, n_days))

  grid <- expand.grid(
    longitude = lons,
    latitude = lats,
    date = dates,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )

  grid$temperature <- as.vector(data_array)

  # Filter missing values (99.9 for temperature)
  result_df <- grid[!is.na(grid$temperature) & grid$temperature < 99, ]
  rownames(result_df) <- NULL

  message(sprintf(fmt = "Processed %s data points", nrow(x = result_df)))
  result_df
}

#' Read IMD NetCDF rainfall file
#'
#' Reads IMD NetCDF rainfall data and converts to data.frame.
#'
#' @param file_path Path to IMD NetCDF file (.nc).
#' @param resolution Spatial resolution: 0.25 or 1.0.
#' @param year Year of the data.
#' @return data.frame with columns: date, latitude, longitude, rainfall
#' @export
#' @examples
#' \dontrun{
#' rain_data <- read_imd_rainfall("imd_rainfall_0.25_2023.nc", 0.25, 2023)
#' }
read_imd_rainfall <- function(file_path, resolution, year) {
  if (!file.exists(file_path)) stop("File not found: ", file_path)

  dataset_id <- paste0("rainfall_", resolution)
  grid_specs <- get_imd_grid_specs(dataset_id)

  message(sprintf(fmt = "Reading IMD rainfall data for %s", year))
  message(sprintf(fmt = "Resolution: %s\u00b0", resolution))

  rainfall_data <- tryCatch(
    read_ncdf(file_path),
    error = function(e) {
      warning(sprintf(fmt = "read_ncdf failed, trying ncdf4: %s", e$message), call. = FALSE)
      read_imd_rainfall_ncdf4(file_path, grid_specs, year)
    }
  )

  if (inherits(rainfall_data, "stars")) {
    df <- as.data.frame(rainfall_data)

    name_map <- c(
      lon = "longitude", lat = "latitude", time = "date",
      x = "longitude", y = "latitude", Time = "date"
    )
    for (old in names(name_map)) {
      if (old %in% names(df)) names(df)[names(df) == old] <- name_map[old]
    }

    rain_vars <- c("rf", "rainfall", "rain", "precip")
    rain_col <- intersect(rain_vars, names(df))
    if (length(x = rain_col) == 0) {
      rain_col <- setdiff(x = names(x = df), y = c("longitude", "latitude", "date"))[1]
    } else {
      rain_col <- rain_col[1]
    }

    if (rain_col != "rainfall") names(df)[names(df) == rain_col] <- "rainfall"
    df <- df[, c("date", "latitude", "longitude", "rainfall")]

    if (!inherits(df$date, "Date")) df$date <- as.Date(x = df$date)
    df <- df[!is.na(df$rainfall) & df$rainfall > -900, ]
  } else {
    df <- rainfall_data
  }

  message(sprintf(fmt = "Processed %s data points", nrow(x = df)))
  df
}

#' Read IMD NetCDF using ncdf4
#'
#' @param file_path Path to NetCDF file
#' @param grid_specs Grid specifications
#' @param year Year of data
#' @return data.frame
#' @keywords internal
read_imd_rainfall_ncdf4 <- function(file_path, grid_specs, year) {
  nc <- nc_open(file_path)

  tryCatch({
    dims <- names(nc$dim)
    vars <- names(nc$var)

    message(sprintf(fmt = "NetCDF dimensions: %s", paste(dims, collapse = ", ")))
    message(sprintf(fmt = "NetCDF variables: %s", paste(vars, collapse = ", ")))

    lats <- ncvar_get(nc, "lat")
    lons <- ncvar_get(nc, "lon")

    rain_var <- if ("rf" %in% vars) "rf" else setdiff(vars, c("lat", "lon", "time"))[1]
    if (is.na(rain_var)) stop("No rainfall variable found in NetCDF file")

    rainfall <- ncvar_get(nc, rain_var)

    n_days <- if (is_leap_year(year)) 366 else 365
    dates <- seq(as.Date(x = paste0(year, "-01-01")), by = "day", length.out = n_days)

    grid <- expand.grid(
      longitude = lons,
      latitude = lats,
      date = dates,
      KEEP.OUT.ATTRS = FALSE,
      stringsAsFactors = FALSE
    )

    grid$rainfall <- as.vector(rainfall)

    result_df <- grid[!is.na(grid$rainfall) & grid$rainfall > -900, ]
    rownames(result_df) <- NULL

    result_df
  }, finally = {
    nc_close(nc)
  })
}

#' Process multiple IMD files
#'
#' Reads and combines multiple IMD data files.
#'
#' @param file_paths Character vector of file paths.
#' @param var_type Variable type: "rain", "tmax", or "tmin".
#' @param resolution Resolution (for rainfall): 0.25 or 1.0.
#' @param years Integer vector. Years corresponding to each file.
#' @return data.frame with combined data
#' @export
#' @examples
#' \dontrun{
#' files <- c("imd_tmax_1.0_2023.grd", "imd_tmax_1.0_2024.grd")
#' data <- process_imd_files(files, "tmax", years = c(2023, 2024))
#' }
process_imd_files <- function(file_paths, var_type, resolution = NULL, years = NULL) {
  if (length(x = file_paths) == 0) stop("No files provided")

  years <- years %||% extract_years_from_filenames(file_paths)
  if (length(x = years) != length(x = file_paths)) stop("Number of years must match number of files")

  message(sprintf(fmt = "Processing %s IMD files", length(x = file_paths)))

  all_data <- lapply(seq_along(along.with = file_paths), function(i) {
    tryCatch(
      {
        if (var_type == "rain") {
          res <- resolution %||% if (grepl(pattern = "0.25", file_paths[i])) 0.25 else 1.0
          read_imd_rainfall(file_paths[i], res, years[i])
        } else if (var_type %in% c("tmax", "tmin")) {
          read_imd_temperature(file_paths[i], var_type, years[i])
        } else {
          stop("Invalid var_type: ", var_type)
        }
      },
      error = function(e) {
        stop(sprintf(fmt = "Error processing %s: %s", basename(path = file_paths[i]), e$message))
        NULL
      }
    )
  })

  all_data <- Filter(Negate(is.null), all_data)
  if (length(x = all_data) == 0) stop("No files were successfully processed")

  combined_df <- do.call(rbind, all_data)
  combined_df <- combined_df[order(combined_df$date, combined_df$latitude, combined_df$longitude), ]
  rownames(combined_df) <- NULL

  message(sprintf(fmt = "Combined data: %s total data points", nrow(x = combined_df)))
  combined_df
}

#' Filter IMD data by spatial boundaries
#'
#' @param data data.frame with IMD data
#' @param north Northern latitude boundary
#' @param south Southern latitude boundary
#' @param east Eastern longitude boundary
#' @param west Western longitude boundary
#' @return Filtered data.frame
#' @export
filter_imd_by_bbox <- function(data, north, south, east, west) {
  if (!all(c("latitude", "longitude") %in% names(data))) {
    stop("Data must contain 'latitude' and 'longitude' columns")
  }
  if (!validate_bbox(north, south, east, west)) stop("Invalid bounding box coordinates")

  filtered <- data[data$latitude >= south & data$latitude <= north &
    data$longitude >= west & data$longitude <= east, ]

  message(sprintf(fmt = "Filtered %s points to %s within bounding box", nrow(x = data), nrow(x = filtered)))
  filtered
}

#' Filter IMD data by GeoJSON polygon
#'
#' @param data data.frame with IMD data
#' @param geojson_file Path to GeoJSON file
#' @return Filtered data.frame
#' @export
filter_imd_by_geojson <- function(data, geojson_file) {
  if (!all(c("latitude", "longitude") %in% names(data))) {
    stop("Data must contain 'latitude' and 'longitude' columns")
  }

  geojson_sf <- st_read(geojson_file, quiet = TRUE)
  if (is.na(st_crs(geojson_sf))) geojson_sf <- st_set_crs(geojson_sf, 4326)
  geojson_sf <- st_transform(geojson_sf, 4326)

  points_sf <- st_as_sf(data, coords = c("longitude", "latitude"), crs = 4326)
  inside <- apply(st_within(points_sf, geojson_sf, sparse = FALSE), 1, any)
  filtered <- data[inside, ]

  message(sprintf(fmt = "Filtered %s points to %s within GeoJSON boundary", nrow(x = data), nrow(x = filtered)))
  filtered
}

#' Aggregate IMD data by temporal frequency
#'
#' @param data data.frame with IMD data
#' @param frequency Character string: "daily", "monthly", "yearly"
#' @return Aggregated data.frame
#' @export
aggregate_imd_by_frequency <- function(data, frequency = "daily") {
  if (!"date" %in% names(data)) stop("Data must contain 'date' column")
  if (tolower(x = frequency) == "daily") {
    return(data)
  }

  value_col <- setdiff(x = names(x = data), y = c("date", "latitude", "longitude"))[1]
  if (is.na(value_col)) stop("No value column found in data")

  if (requireNamespace("data.table", quietly = TRUE)) {
    DT <- as.data.table(data)

    freq_lower <- tolower(x = frequency)
    if (freq_lower == "monthly") {
      DT[, time_group := year(date) * 100L + month(date)]
    } else if (freq_lower == "yearly") {
      DT[, time_group := year(date)]
    } else {
      DT[, time_group := year(date) * 100L + month(date)]
    }

    # Sum for rainfall, mean for temperature
    agg_fun <- if (value_col == "rainfall") sum else mean

    aggregated <- DT[, .(value = agg_fun(get(..value_col), na.rm = TRUE)),
      by = .(time_group, latitude, longitude)
    ]

    if (freq_lower == "monthly") {
      aggregated[, date := as.Date(paste0(
        time_group %/% 100L, "-",
        sprintf(fmt = "%02d", time_group %% 100L), "-01"
      ))]
    } else if (freq_lower == "yearly") {
      aggregated[, date := as.Date(x = paste0(time_group, "-01-01"))]
    } else {
      aggregated[, date := as.Date(paste0(
        time_group %/% 100L, "-",
        sprintf(fmt = "%02d", time_group %% 100L), "-01"
      ))]
    }

    setorder(aggregated, date, latitude, longitude)

    aggregated[, time_group := NULL]
    setnames(aggregated, "value", value_col)

    aggregated <- as.data.frame(aggregated)
  } else {
    freq_lower <- tolower(x = frequency)
    data$time_group <- format(data$date, switch(freq_lower,
      monthly = "%Y-%m",
      yearly = "%Y",
      "%Y-%m"
    ))

    agg_fun <- if (value_col == "rainfall") sum else mean
    formula_str <- paste(value_col, "~ time_group + latitude + longitude")

    aggregated <- aggregate(
      as.formula(formula_str),
      data = data,
      FUN = agg_fun,
      na.rm = TRUE
    )

    if (freq_lower == "yearly") {
      aggregated$date <- as.Date(x = paste0(aggregated$time_group, "-01-01"))
    } else {
      aggregated$date <- as.Date(x = paste0(aggregated$time_group, "-01"))
    }
    aggregated$time_group <- NULL

    aggregated <- aggregated[, c("date", "latitude", "longitude", value_col)]
    aggregated <- aggregated[order(aggregated$date, aggregated$latitude, aggregated$longitude), ]
    rownames(aggregated) <- NULL
  }

  message(sprintf(fmt = "Aggregated from %s to %s points (%s)", nrow(x = data), nrow(x = aggregated), frequency))
  aggregated
}

is_leap_year <- function(year) {
  (year %% 4 == 0 & year %% 100 != 0) | (year %% 400 == 0)
}

extract_years_from_filenames <- function(filenames) {
  years <- vapply(filenames, function(f) {
    matches <- regmatches(f, gregexpr("[0-9]{4}", f))[[1]]
    if (length(x = matches) > 0) as.integer(x = matches[length(x = matches)]) else NA_integer_
  }, integer(1))

  if (any(is.na(years))) stop("Could not extract years from all filenames")
  years
}
