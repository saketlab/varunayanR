#' IMD weather stations with coordinates
#'
#' Retrieves the India Meteorological Department (IMD) city-weather station list
#' and, optionally, each station's latitude/longitude. IMD's legacy endpoints
#' expose only station names; its responsive site serves a per-station JSON record
#' (`api/fetchCity_static.php`) that includes `lat`/`lon`, which this function
#' pairs with the station list. The returned coordinates can be fed directly to
#' [era5ify_point()] or used to build maps.
#'
#' @param with_coordinates Logical; if `TRUE` (default) fetch `latitude` and
#'   `longitude` for every station (one request per station). If `FALSE`, return
#'   only `station_id` and `name`.
#' @param cores Integer; number of parallel workers used to fetch coordinates
#'   (passed to [parallel::mclapply()]). Defaults to 4; set to 1 on Windows.
#' @param ... Ignored (present for alias compatibility).
#'
#' @return A `data.frame` with columns `station_id`, `name`, and — when
#'   `with_coordinates = TRUE` — `latitude`, `longitude` (`NA` where IMD has no
#'   coordinate for a station).
#'
#' @examples
#' \dontrun{
#' stations <- imd_stations()
#' shimla <- stations[grepl("Shimla", stations$name), ]
#' }
#' @export
imd_stations <- function(with_coordinates = TRUE, cores = 4) {
  ua <- "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/126 Safari/537.36"
  list_url <- "https://internal.imd.gov.in/pages/city_weather_main_mausam.php"
  api_url <- "https://city.imd.gov.in/citywx/responsive/api/fetchCity_static.php"
  referer <- "https://city.imd.gov.in/citywx/responsive/"

  resp <- httr::GET(list_url, httr::add_headers(`User-Agent` = ua), httr::timeout(30))
  if (httr::status_code(resp) != 200) {
    stop("Failed to fetch IMD station list (HTTP ", httr::status_code(resp), ")")
  }
  html <- httr::content(resp, as = "text", encoding = "UTF-8")

  pat <- "<option value='([0-9]{4,6})([^']*)'>"
  hits <- regmatches(html, gregexpr(pat, html, perl = TRUE))[[1]]
  if (length(hits) == 0) stop("No stations found in IMD city list")
  station_id <- as.integer(sub(pat, "\\1", hits, perl = TRUE))
  name <- tools::toTitleCase(tolower(trimws(sub(pat, "\\2", hits, perl = TRUE))))
  stations <- data.frame(station_id = station_id, name = name, stringsAsFactors = FALSE)
  stations <- stations[!duplicated(stations$station_id), ]
  rownames(stations) <- NULL

  if (!isTRUE(with_coordinates)) {
    return(stations)
  }

  fetch_coord <- function(id) {
    r <- tryCatch(
      httr::POST(
        api_url,
        body = list(ID = id), encode = "form",
        httr::add_headers(`User-Agent` = ua, Referer = referer), httr::timeout(30)
      ),
      error = function(e) NULL
    )
    if (is.null(r) || httr::status_code(r) != 200) {
      return(c(NA_real_, NA_real_))
    }
    d <- tryCatch(
      jsonlite::fromJSON(httr::content(r, as = "text", encoding = "UTF-8")),
      error = function(e) NULL
    )
    if (is.null(d)) {
      return(c(NA_real_, NA_real_))
    }
    rec <- if (is.data.frame(d)) d[1, , drop = FALSE] else as.list(d)
    lat <- suppressWarnings(as.numeric(rec$lat))
    lon <- suppressWarnings(as.numeric(rec$lon))
    if (length(lat) != 1 || length(lon) != 1 || is.na(lat) || is.na(lon) ||
      lat < 6 || lat > 38 || lon < 67 || lon > 99) {
      return(c(NA_real_, NA_real_))
    }
    c(lat, lon)
  }

  coords <- parallel::mclapply(stations$station_id, fetch_coord, mc.cores = cores)
  coord_mat <- do.call(rbind, coords)
  stations$latitude <- coord_mat[, 1]
  stations$longitude <- coord_mat[, 2]
  stations
}
