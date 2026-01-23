#' IMD data download and processing for custom regions

#' Download and process IMD rainfall data for a bounding box
#'
#' Downloads IMD gridded rainfall data and filters it to a specified bounding box.
#'
#' @param request_id Unique identifier for the request.
#' @param start_year Start year.
#' @param end_year End year.
#' @param north Northern latitude boundary.
#' @param south Southern latitude boundary.
#' @param east Eastern longitude boundary.
#' @param west Western longitude boundary.
#' @param resolution Spatial resolution: 0.25 or 1.0 degrees (default: 0.25).
#' @param frequency Temporal frequency: "daily", "monthly", "yearly" (default: "daily").
#' @param save_raw Whether to save raw downloaded files (default: FALSE).
#' @param output_dir Directory to save files (default: tempdir()).
#' @return data.frame with processed rainfall data
#' @export
#' @examples
#' \dontrun{
#' data <- imd_rainfall_bbox(
#'   request_id = "maharashtra_rain",
#'   start_year = 2023,
#'   end_year = 2024,
#'   north = 22, south = 16,
#'   east = 80, west = 73,
#'   resolution = 0.25,
#'   frequency = "monthly"
#' )
#' }
imd_rainfall_bbox <- function(request_id, start_year, end_year,
                              north, south, east, west,
                              resolution = 0.25, frequency = "daily",
                              save_raw = FALSE, output_dir = tempdir(),
                              use_cache = TRUE) {
  message("=== IMD Rainfall Download and Processing ===")
  message(sprintf(fmt = "Request ID: %s", request_id))
  message(sprintf(fmt = "Years: %s to %s", start_year, end_year))
  message(sprintf(fmt = "Resolution: %s\u00b0", resolution))
  message(sprintf(fmt = "Bounding box: N:%s, S:%s, E:%s, W:%s", north, south, east, west))

  if (!validate_bbox(north, south, east, west)) {
    stop("Invalid bounding box coordinates")
  }

  downloaded_files <- download_imd_rainfall(
    start_year = start_year,
    end_year = end_year,
    resolution = resolution,
    output_dir = output_dir,
    use_cache = use_cache
  )

  if (length(x = downloaded_files) == 0) stop("No files were successfully downloaded")

  years <- start_year:end_year
  processed_data <- process_imd_files(
    file_paths = downloaded_files,
    var_type = "rain",
    resolution = resolution,
    years = years
  )

  filtered_data <- filter_imd_by_bbox(
    data = processed_data,
    north = north, south = south,
    east = east, west = west
  )

  if (frequency != "daily") {
    filtered_data <- aggregate_imd_by_frequency(filtered_data, frequency)
  }

  save_imd_results(
    data = filtered_data,
    request_id = request_id,
    var_type = "rainfall",
    resolution = resolution,
    frequency = frequency,
    output_dir = output_dir
  )

  if (!save_raw) {
    unlink(downloaded_files)
    message("Cleaned up raw downloaded files")
  }

  message("Processing completed!")
  message(sprintf(fmt = "Final dataset: %s data points", nrow(x = filtered_data)))

  filtered_data
}

#' Download and process IMD rainfall data for a GeoJSON region
#'
#' @param request_id Unique identifier for the request.
#' @param start_year Start year (1901-2024).
#' @param end_year End year (1901-2024).
#' @param geojson_file Path to GeoJSON file.
#' @param resolution Spatial resolution: 0.25 or 1.0 degrees (default: 0.25).
#' @param frequency Temporal frequency (default: "daily").
#' @param save_raw Whether to save raw files (default: FALSE).
#' @param output_dir Directory to save files (default: tempdir()).
#' @return data.frame with processed rainfall data
#' @export
imd_rainfall_geojson <- function(request_id, start_year, end_year, geojson_file,
                                 resolution = 0.25, frequency = "daily",
                                 save_raw = FALSE, output_dir = tempdir(),
                                 use_cache = TRUE) {
  message("=== IMD Rainfall Download and Processing ===")
  message(sprintf(fmt = "Request ID: %s", request_id))
  message(sprintf(fmt = "GeoJSON: %s", basename(path = geojson_file)))

  if (!file.exists(geojson_file)) {
    stop("GeoJSON file not found: ", geojson_file)
  }

  geojson_sf <- st_read(geojson_file, quiet = TRUE)
  bbox <- st_bbox(geojson_sf)

  north <- bbox[["ymax"]]
  south <- bbox[["ymin"]]
  east <- bbox[["xmax"]]
  west <- bbox[["xmin"]]

  message(sprintf(fmt = "Bounding box from GeoJSON: N:%s, S:%s, E:%s, W:%s", round(north, 2), round(south, 2), round(east, 2), round(west, 2)))

  downloaded_files <- download_imd_rainfall(
    start_year = start_year,
    end_year = end_year,
    resolution = resolution,
    output_dir = output_dir,
    use_cache = use_cache
  )

  if (length(x = downloaded_files) == 0) stop("No files were successfully downloaded")

  years <- start_year:end_year
  processed_data <- process_imd_files(
    file_paths = downloaded_files,
    var_type = "rain",
    resolution = resolution,
    years = years
  )

  filtered_data <- filter_imd_by_geojson(
    data = processed_data,
    geojson_file = geojson_file
  )

  if (frequency != "daily") {
    filtered_data <- aggregate_imd_by_frequency(filtered_data, frequency)
  }

  save_imd_results(
    data = filtered_data,
    request_id = request_id,
    var_type = "rainfall",
    resolution = resolution,
    frequency = frequency,
    output_dir = output_dir
  )

  if (!save_raw) {
    unlink(downloaded_files)
    message("Cleaned up raw downloaded files")
  }

  message("Processing completed!")
  message(sprintf(fmt = "Final dataset: %s data points", nrow(x = filtered_data)))

  filtered_data
}

#' Download and process IMD temperature data for a bounding box
#'
#' @param request_id Unique identifier for the request.
#' @param start_year Start year (1951-2024).
#' @param end_year End year (1951-2024).
#' @param north Northern latitude boundary.
#' @param south Southern latitude boundary.
#' @param east Eastern longitude boundary.
#' @param west Western longitude boundary.
#' @param var_type Temperature type: "tmax" or "tmin".
#' @param frequency Temporal frequency (default: "daily").
#' @param save_raw Whether to save raw files (default: FALSE).
#' @param output_dir Directory to save files (default: tempdir()).
#' @return data.frame with processed temperature data
#' @export
#' @examples
#' \dontrun{
#' data <- imd_temperature_bbox(
#'   request_id = "delhi_tmax",
#'   start_year = 2023,
#'   end_year = 2024,
#'   north = 29, south = 28,
#'   east = 78, west = 76,
#'   var_type = "tmax"
#' )
#' }
imd_temperature_bbox <- function(request_id, start_year, end_year,
                                 north, south, east, west,
                                 var_type = "tmax", frequency = "daily",
                                 save_raw = FALSE, output_dir = tempdir(),
                                 use_cache = TRUE) {
  message("=== IMD Temperature Download and Processing ===")
  message(sprintf(fmt = "Request ID: %s", request_id))
  message(sprintf(fmt = "Variable: %s", var_type))
  message(sprintf(fmt = "Years: %s to %s", start_year, end_year))

  if (!validate_bbox(north, south, east, west)) {
    stop("Invalid bounding box coordinates")
  }

  downloaded_files <- download_imd_temperature(
    start_year = start_year,
    end_year = end_year,
    var_type = var_type,
    output_dir = output_dir,
    use_cache = use_cache
  )

  if (length(x = downloaded_files) == 0) stop("No files were successfully downloaded")

  years <- start_year:end_year
  processed_data <- process_imd_files(
    file_paths = downloaded_files,
    var_type = var_type,
    years = years
  )

  filtered_data <- filter_imd_by_bbox(
    data = processed_data,
    north = north, south = south,
    east = east, west = west
  )

  if (frequency != "daily") {
    filtered_data <- aggregate_imd_by_frequency(filtered_data, frequency)
  }

  save_imd_results(
    data = filtered_data,
    request_id = request_id,
    var_type = var_type,
    resolution = 1.0,
    frequency = frequency,
    output_dir = output_dir
  )

  if (!save_raw) {
    unlink(downloaded_files)
    message("Cleaned up raw downloaded files")
  }

  message("Processing completed!")
  message(sprintf(fmt = "Final dataset: %s data points", nrow(x = filtered_data)))

  filtered_data
}

#' Download and process IMD temperature data for a GeoJSON region
#'
#' @param request_id Unique identifier.
#' @param start_year Start year (1951-2024).
#' @param end_year End year (1951-2024).
#' @param geojson_file Path to GeoJSON file.
#' @param var_type Temperature type: "tmax" or "tmin".
#' @param frequency Temporal frequency (default: "daily").
#' @param save_raw Whether to save raw files (default: FALSE).
#' @param output_dir Directory for output (default: tempdir()).
#' @return data.frame with processed temperature data
#' @export
imd_temperature_geojson <- function(request_id, start_year, end_year, geojson_file,
                                    var_type = "tmax", frequency = "daily",
                                    save_raw = FALSE, output_dir = tempdir(),
                                    use_cache = TRUE) {
  message("=== IMD Temperature Download and Processing ===")
  message(sprintf(fmt = "Request ID: %s", request_id))
  message(sprintf(fmt = "Variable: %s", var_type))
  message(sprintf(fmt = "GeoJSON: %s", basename(path = geojson_file)))

  if (!file.exists(geojson_file)) {
    stop("GeoJSON file not found: ", geojson_file)
  }

  downloaded_files <- download_imd_temperature(
    start_year = start_year,
    end_year = end_year,
    var_type = var_type,
    output_dir = output_dir,
    use_cache = use_cache
  )

  if (length(x = downloaded_files) == 0) stop("No files were successfully downloaded")

  years <- start_year:end_year
  processed_data <- process_imd_files(
    file_paths = downloaded_files,
    var_type = var_type,
    years = years
  )

  filtered_data <- filter_imd_by_geojson(
    data = processed_data,
    geojson_file = geojson_file
  )

  if (frequency != "daily") {
    filtered_data <- aggregate_imd_by_frequency(filtered_data, frequency)
  }

  save_imd_results(
    data = filtered_data,
    request_id = request_id,
    var_type = var_type,
    resolution = 1.0,
    frequency = frequency,
    output_dir = output_dir
  )

  if (!save_raw) {
    unlink(downloaded_files)
    message("Cleaned up raw downloaded files")
  }

  message("Processing completed!")
  message(sprintf(fmt = "Final dataset: %s data points", nrow(x = filtered_data)))

  filtered_data
}

#' Save IMD results to CSV
#'
#' @param data data.frame with processed data
#' @param request_id Request identifier
#' @param var_type Variable type
#' @param resolution Resolution
#' @param frequency Frequency
#' @param output_dir Output directory
#' @keywords internal
save_imd_results <- function(data, request_id, var_type, resolution, frequency, output_dir) {
  imd_output_dir <- file.path(output_dir, paste0(request_id, "_imd_output"))
  ensure_output_dir(imd_output_dir)

  output_file <- file.path(
    imd_output_dir,
    sprintf(fmt = "%s_imd_%s_%s_%s_data.csv", request_id, var_type, resolution, frequency)
  )

  write.csv(data, output_file, row.names = FALSE)
  message(sprintf(fmt = "Saved data to: %s", output_file))

  unique_coords <- unique(x = data[, c("latitude", "longitude")])
  coords_file <- file.path(imd_output_dir, sprintf(fmt = "%s_unique_coordinates.csv", request_id))
  write.csv(unique_coords, coords_file, row.names = FALSE)
  message(sprintf(fmt = "Saved %s unique coordinates to: %s", nrow(x = unique_coords), coords_file))

  metadata <- list(
    request_id = request_id,
    var_type = var_type,
    resolution = resolution,
    frequency = frequency,
    n_records = nrow(x = data),
    n_locations = nrow(x = unique_coords),
    date_range = c(min(data$date), max(data$date)),
    spatial_extent = c(
      min(data$latitude), max(data$latitude),
      min(data$longitude), max(data$longitude)
    ),
    created_at = Sys.time()
  )

  metadata_file <- file.path(imd_output_dir, sprintf(fmt = "%s_metadata.json", request_id))
  write_json(metadata, metadata_file, pretty = TRUE, auto_unbox = TRUE)
  message(sprintf(fmt = "Saved metadata to: %s", metadata_file))

  invisible(output_file)
}
