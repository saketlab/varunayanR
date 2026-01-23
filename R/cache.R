#' Cache management for downloaded NetCDF files
#'
#' Functions to cache ERA5 and IMD NetCDF files for faster successive queries

#' Get cache directory path
#'
#' @param create Create directory if it doesn't exist (default: TRUE)
#' @return Character string with cache directory path
#' @export
get_cache_dir <- function(create = TRUE) {
  cache_dir <- R_user_dir(package = "varunayan", which = "cache")
  if (create && !dir.exists(paths = cache_dir)) {
    dir.create(path = cache_dir, recursive = TRUE, showWarnings = FALSE)
  }
  cache_dir
}

#' Generate cache key for download parameters
#'
#' @param source Data source: "era5" or "imd"
#' @param variables Variable names
#' @param start_date Start date
#' @param end_date End date
#' @param area Bounding box for ERA5
#' @param resolution Spatial resolution
#' @param dataset_type For ERA5: "single" or "pressure"
#' @param var_type For IMD: "tmax", "tmin", or "rainfall"
#' @param pressure_levels Pressure levels for ERA5 pressure data
#' @return Character string with cache key
#' @keywords internal
generate_cache_key <- function(source, variables = NULL, start_date, end_date,
                               area = NULL, resolution = NULL,
                               dataset_type = NULL, var_type = NULL,
                               pressure_levels = NULL) {
  components <- list(
    source = tolower(x = source),
    vars = if (!is.null(x = variables)) paste(sort(x = variables), collapse = "_") else NULL,
    start = format(x = as.Date(x = start_date), format = "%Y%m%d"),
    end = format(x = as.Date(x = end_date), format = "%Y%m%d"),
    bbox = if (!is.null(x = area)) paste(round(x = area, digits = 3), collapse = "_") else NULL,
    res = if (!is.null(x = resolution)) sprintf(fmt = "%.2f", resolution) else NULL,
    dtype = dataset_type,
    vtype = var_type,
    plevels = if (!is.null(x = pressure_levels)) paste(sort(x = pressure_levels), collapse = "_") else NULL
  )
  components <- components[!vapply(X = components, FUN = is.null, FUN.VALUE = logical(1))]

  key_string <- paste(names(x = components), components, sep = "=", collapse = "&")
  cache_key <- digest(object = key_string, algo = "md5")
  prefix <- paste(components$source, components$start, components$end, sep = "_")
  paste0(prefix, "_", cache_key)
}

#' Check if data exists in cache
#' @param cache_key Cache key to check
#' @return Path to cached file if exists, NULL otherwise
#' @keywords internal
check_cache <- function(cache_key) {
  cache_dir <- get_cache_dir(create = FALSE)
  if (!dir.exists(paths = cache_dir)) {
    return(NULL)
  }

  cached_files <- list.files(
    path = cache_dir,
    pattern = paste0("^", cache_key, ".*\\.(nc|grd)$"),
    full.names = TRUE
  )
  if (length(x = cached_files) > 0) cached_files[1] else NULL
}

#' Save file to cache
#' @param file_path Path to file to cache
#' @param cache_key Cache key for the file
#' @return Path to cached file
#' @keywords internal
save_to_cache <- function(file_path, cache_key) {
  if (!file.exists(file_path)) stop("File does not exist: ", file_path)

  cache_dir <- get_cache_dir(create = TRUE)
  ext <- file_ext(x = file_path)
  cache_file <- file.path(cache_dir, paste0(cache_key, ".", ext))
  file.copy(from = file_path, to = cache_file, overwrite = TRUE)
  message("Cached to: ", cache_file)
  cache_file
}

#' List cached files
#'
#' @param source Filter by source: "era5", "imd", or NULL for all
#' @return data.frame with cache information
#' @export
list_cache <- function(source = NULL) {
  cache_dir <- get_cache_dir(create = FALSE)
  empty_df <- data.frame(
    file = character(), source = character(),
    size_mb = numeric(), modified = character()
  )

  if (!dir.exists(paths = cache_dir)) {
    message("Cache directory does not exist: ", cache_dir)
    return(empty_df)
  }

  files <- list.files(path = cache_dir, pattern = "\\.(nc|grd)$", full.names = TRUE)
  if (length(x = files) == 0) {
    message("No cached files found")
    return(empty_df)
  }

  file_info <- file.info(files)
  basenames <- basename(path = files)
  sources <- ifelse(
    test = grepl(pattern = "^era5", x = basenames), yes = "era5",
    no = ifelse(test = grepl(pattern = "^imd", x = basenames), yes = "imd", no = "unknown")
  )

  if (!is.null(x = source)) {
    keep <- sources == tolower(x = source)
    files <- files[keep]
    file_info <- file_info[keep, , drop = FALSE]
    sources <- sources[keep]
  }

  if (length(x = files) == 0) {
    message("No ", source, " files in cache")
    return(empty_df)
  }

  result <- data.frame(
    file = basename(path = files),
    source = sources,
    size_mb = round(x = file_info$size / 1024^2, digits = 2),
    modified = format(x = file_info$mtime, format = "%Y-%m-%d %H:%M:%S")
  )
  message("Found ", nrow(x = result), " cached file(s), total: ", round(x = sum(result$size_mb), digits = 2), " MB")
  result
}

#' Clear cache
#'
#' @param source Clear only "era5", "imd", or NULL for all
#' @param older_than Remove files older than this many days (NULL = all)
#' @param confirm Ask for confirmation (default: TRUE)
#' @return Number of files deleted (invisible)
#' @export
clear_cache <- function(source = NULL, older_than = NULL, confirm = TRUE) {
  cache_dir <- get_cache_dir(create = FALSE)
  if (!dir.exists(paths = cache_dir)) {
    message("Cache directory does not exist")
    return(invisible(x = 0))
  }

  files <- list.files(path = cache_dir, pattern = "\\.(nc|grd)$", full.names = TRUE)
  if (length(x = files) == 0) {
    message("No cached files to delete")
    return(invisible(x = 0))
  }

  # Filter by source
  if (!is.null(x = source)) {
    files <- files[grepl(pattern = paste0("^", tolower(x = source)), x = basename(path = files))]
  }

  # Filter by age
  if (!is.null(x = older_than)) {
    file_info <- file.info(files)
    age_days <- as.numeric(x = difftime(time1 = Sys.time(), time2 = file_info$mtime, units = "days"))
    files <- files[age_days > older_than]
  }

  if (length(x = files) == 0) {
    message("No files match the criteria")
    return(invisible(x = 0))
  }

  total_size_mb <- sum(file.info(files)$size) / 1024^2

  if (confirm) {
    message("About to delete ", length(x = files), " file(s) (", round(x = total_size_mb, digits = 2), " MB)")
    response <- readline(prompt = "Are you sure? (yes/no): ")
    if (tolower(x = response) != "yes") {
      message("Cancelled")
      return(invisible(x = 0))
    }
  }

  deleted <- sum(file.remove(files))
  message("Deleted ", deleted, " file(s) (", round(x = total_size_mb, digits = 2), " MB)")
  invisible(x = deleted)
}

#' Get cache statistics
#' @return List with cache statistics
#' @export
cache_stats <- function() {
  cache_dir <- get_cache_dir(create = FALSE)
  if (!dir.exists(paths = cache_dir)) {
    return(list(location = cache_dir, exists = FALSE, n_files = 0, total_size_mb = 0))
  }

  files <- list.files(path = cache_dir, pattern = "\\.(nc|grd)$", full.names = TRUE)
  if (length(x = files) == 0) {
    return(list(location = cache_dir, exists = TRUE, n_files = 0, total_size_mb = 0))
  }

  file_info <- file.info(files)
  basenames <- basename(path = files)

  list(
    location = cache_dir,
    exists = TRUE,
    n_files = length(x = files),
    n_era5 = sum(grepl(pattern = "^era5", x = basenames)),
    n_imd = sum(grepl(pattern = "^imd", x = basenames)),
    total_size_mb = round(x = sum(file_info$size) / 1024^2, digits = 2),
    oldest_file = format(x = min(file_info$mtime), format = "%Y-%m-%d %H:%M:%S"),
    newest_file = format(x = max(file_info$mtime), format = "%Y-%m-%d %H:%M:%S")
  )
}

#' Show cache contents and statistics
#' @return data.frame with cache information (invisible)
#' @export
show_cache_info <- function() {
  cache_dir <- get_cache_dir(create = FALSE)

  if (!dir.exists(paths = cache_dir)) {
    message("Cache directory does not exist yet: ", cache_dir)
    return(invisible(x = NULL))
  }

  message("\n## Cache Information\n")
  message("Location: ", cache_dir)

  files <- list.files(path = cache_dir, recursive = TRUE, full.names = TRUE)
  if (length(x = files) == 0) {
    message("Cache is empty")
    return(invisible(x = NULL))
  }

  file_info <- file.info(files)
  file_info$name <- basename(path = files)
  file_info$size_mb <- round(x = file_info$size / 1024^2, digits = 2)

  message("Found ", nrow(x = file_info), " file(s), total: ", round(x = sum(file_info$size_mb), digits = 1), " MB\n")

  # Group by source
  imd_files <- file_info[grepl(pattern = "imd", x = file_info$name, ignore.case = TRUE), ]
  era5_files <- file_info[grepl(pattern = "era5", x = file_info$name, ignore.case = TRUE), ]

  if (nrow(x = imd_files) > 0) {
    message("IMD: ", nrow(x = imd_files), " files (", round(x = sum(imd_files$size_mb), digits = 1), " MB)")
  }
  if (nrow(x = era5_files) > 0) {
    message("ERA5: ", nrow(x = era5_files), " files (", round(x = sum(era5_files$size_mb), digits = 1), " MB)")
  }

  invisible(x = file_info[, c("name", "size_mb", "mtime")])
}

#' Populate cache with sample IMD data
#'
#' Copies sample IMD data files to cache for offline testing.
#'
#' @param force Overwrite existing cached files (default: FALSE)
#' @return List of cached files (invisible)
#' @export
populate_sample_cache <- function(force = FALSE) {
  pkg_dir <- system.file(package = "varunayan")
  sample_dirs <- c(
    file.path(pkg_dir, "imd_samples"),
    file.path(getwd(), "imd_samples")
  )

  sample_dir <- NULL
  for (dir in sample_dirs) {
    if (dir.exists(paths = dir)) {
      sample_dir <- dir
      break
    }
  }

  if (is.null(x = sample_dir)) {
    warning("Sample data directory not found")
    return(invisible(x = NULL))
  }

  message("Populating cache with sample IMD data...")

  samples <- list(
    list(file = "rain_2024.nc", var_type = "rainfall", res = 0.25, desc = "Rainfall 0.25° (2024)"),
    list(file = "tmax_2024.grd", var_type = "tmax", res = 1.0, desc = "Max Temp 1.0° (2024)"),
    list(file = "tmin_2024.grd", var_type = "tmin", res = 1.0, desc = "Min Temp 1.0° (2024)")
  )

  cached_files <- list()
  for (s in samples) {
    source_path <- file.path(sample_dir, s$file)
    if (!file.exists(source_path)) next

    cache_key <- generate_cache_key(
      source = "imd", start_date = "2024-01-01", end_date = "2024-12-31",
      resolution = s$res, var_type = s$var_type
    )

    existing <- check_cache(cache_key = cache_key)
    if (!is.null(x = existing) && !force) {
      message(s$desc, ": already cached")
      cached_files[[s$desc]] <- existing
      next
    }

    cached_path <- save_to_cache(file_path = source_path, cache_key = cache_key)
    message(s$desc, ": cached")
    cached_files[[s$desc]] <- cached_path
  }

  if (length(x = cached_files) > 0) {
    message("Cached ", length(x = cached_files), " sample file(s)")
  }
  invisible(x = cached_files)
}
