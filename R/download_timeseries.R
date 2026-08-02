#' Download ERA5 data for a point via the CDS time-series endpoint
#'
#' Retrieves `reanalysis-era5-single-levels-timeseries`, which serves a single
#' location directly instead of returning gridded fields that must be subset.
#' For long hourly requests at one point this is substantially faster than
#' `download_era5_single()`, which pays field-retrieval cost per timestep.
#'
#' @param variables Character vector of ERA5 variable names.
#' @param start_date Start date (Date or "YYYY-MM-DD").
#' @param end_date End date (Date or "YYYY-MM-DD").
#' @param lat Latitude of the point location.
#' @param lon Longitude of the point location.
#' @param output_dir Directory to save files (default: tempdir()).
#' @param timeout Seconds to wait for the request before giving up.
#' @param verbose Whether to print detailed progress messages.
#' @return data.frame with datetime, latitude, longitude, variable, and value
#'   columns, in original ERA5 units.
#' @keywords internal
download_era5_timeseries <- function(variables, start_date, end_date, lat, lon,
                                     output_dir = tempdir(), timeout = 1800,
                                     verbose = FALSE) {
  if (!get_cds_credentials(silent = TRUE)) {
    stop(
      "CDS credentials not found. Please either:\n",
      "  1. Create ~/.cdsapirc file with your API key, or\n",
      "  2. Run setup_cds_credentials(key = 'your-api-key')"
    )
  }
  key <- wf_get_key()

  creds <- read_cdsapirc()
  base_url <- if (!is.null(x = creds) && "url" %in% names(x = creds)) {
    creds$url
  } else {
    "https://cds.climate.copernicus.eu/api"
  }
  process_url <- paste0(base_url, "/retrieve/v1/processes/reanalysis-era5-single-levels-timeseries")

  output_dir <- ensure_output_dir(output_dir)

  request <- list(inputs = list(
    variable = as.list(x = variables),
    location = list(latitude = lat, longitude = lon),
    date = list(sprintf(
      fmt = "%s/%s",
      format(x = as.Date(x = start_date)), format(x = as.Date(x = end_date))
    )),
    data_format = "csv"
  ))

  if (verbose) {
    message(sprintf(fmt = "Submitting time-series request for (%s, %s)", lat, lon))
  }

  response <- httr::POST(
    paste0(process_url, "/execute"),
    httr::add_headers("PRIVATE-TOKEN" = key, "Content-Type" = "application/json"),
    body = jsonlite::toJSON(x = request, auto_unbox = TRUE), encode = "raw"
  )
  # A rejected request returns an HTML error page, which content() parses to an
  # xml_node rather than a list; report the body instead of failing on the parse.
  parsed <- tryCatch(httr::content(response, "parsed"), error = function(e) NULL)
  job_id <- if (is.list(x = parsed)) parsed$jobID else NULL
  if (is.null(x = job_id)) {
    stop(
      "CDS time-series request failed (HTTP ", httr::status_code(response), "): ",
      substr(x = httr::content(response, "text", encoding = "UTF-8"), start = 1, stop = 200)
    )
  }

  start_time <- Sys.time()
  repeat {
    status <- tryCatch(
      httr::content(httr::GET(
        paste0(base_url, "/retrieve/v1/jobs/", job_id),
        httr::add_headers("PRIVATE-TOKEN" = key)
      ), "parsed")$status,
      error = function(e) NA_character_
    )
    if (identical(x = status, y = "successful")) break
    if (identical(x = status, y = "failed")) {
      stop("CDS time-series request failed for job ", job_id)
    }
    if (as.numeric(x = difftime(Sys.time(), start_time, units = "secs")) > timeout) {
      stop("Request timed out after ", timeout, " seconds")
    }
    Sys.sleep(5)
  }

  result <- httr::content(httr::GET(
    paste0(base_url, "/retrieve/v1/jobs/", job_id, "/results"),
    httr::add_headers("PRIVATE-TOKEN" = key)
  ), "parsed")
  href <- result$asset$value$href
  if (is.null(x = href)) {
    stop("CDS returned no download location for job ", job_id)
  }

  zip_file <- file.path(output_dir, sprintf(fmt = "era5_ts_%s.zip", job_id))
  httr::GET(href, httr::write_disk(zip_file, overwrite = TRUE))
  extract_dir <- file.path(output_dir, sprintf(fmt = "era5_ts_%s", job_id))
  dir.create(path = extract_dir, showWarnings = FALSE, recursive = TRUE)
  utils::unzip(zip_file, exdir = extract_dir)
  csv_file <- list.files(path = extract_dir, pattern = "\\.csv$", full.names = TRUE)[1]
  if (is.na(x = csv_file)) {
    stop("No CSV file found in the CDS time-series response")
  }
  raw <- utils::read.csv(csv_file, stringsAsFactors = FALSE)
  unlink(c(zip_file, extract_dir), recursive = TRUE)

  time_col <- intersect(x = c("valid_time", "time", "date"), y = names(x = raw))[1]
  value_cols <- setdiff(x = names(x = raw), y = c(time_col, "latitude", "longitude"))

  processed <- do.call(rbind, lapply(value_cols, function(v) {
    data.frame(
      datetime = as.POSIXct(x = raw[[time_col]], tz = "UTC"),
      latitude = lat,
      longitude = lon,
      variable = v,
      value = suppressWarnings(as.numeric(x = raw[[v]])),
      stringsAsFactors = FALSE
    )
  }))

  # ERA5 begins 1940-01-01 07:00 UTC; earlier hours are returned as empty values.
  processed[!is.na(x = processed$value), ]
}
