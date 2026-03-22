# data.table non-standard evaluation bindings
utils::globalVariables(c("datetime_date", "weight", "col_name"))

#' Get ERA5 country-level temperature data
#'
#' Convenience function to download and aggregate ERA5 temperature data for a
#' country. Resolves the country boundary, downloads monthly data via
#' [era5ify_geojson()], and returns area-weighted (cosine-latitude) country-level
#' averages by year and month.
#'
#' @param country One of: a country name string (resolved via
#'   [maps::map()]), a path to a GeoJSON file, or an `sf` object.
#'   Common aliases like `"USA"` and `"UK"` are handled automatically.
#' @param start_date Start date in `"YYYY-MM-DD"` format.
#' @param end_date End date in `"YYYY-MM-DD"` format.
#' @param variables Character vector of temperature shorthand names or ERA5
#'   variable names. Shorthands: `"mean"` (2m_temperature), `"max"`
#'   (maximum_2m_temperature_since_previous_post_processing), `"min"`
#'   (minimum_2m_temperature_since_previous_post_processing). Default: `"mean"`.
#' @param request_id Optional request identifier. Auto-generated from the
#'   country name if not provided.
#' @param resolution Spatial resolution in degrees (default: 0.25).
#' @param verbose Whether to print detailed progress messages.
#' @param ... Additional arguments passed to [era5ify_geojson()].
#'
#' @return A data.frame with columns `year`, `month`, and one column per
#'   requested variable (e.g., `temperature_mean`, `temperature_max`,
#'   `temperature_min`). Temperature values are in Celsius.
#'
#' @export
#' @examples
#' \dontrun{
#' # Monthly mean temperature for India
#' get_era5_country_temperature("India", "2023-06-01", "2023-06-30")
#'
#' # Mean and max temperature for USA
#' get_era5_country_temperature("USA", "2023-01-01", "2023-12-31",
#'   variables = c("mean", "max"))
#'
#' # Using an sf object directly
#' library(sf)
#' poly <- st_read("my_country.geojson")
#' get_era5_country_temperature(poly, "2023-01-01", "2023-06-30")
#' }

get_era5_country_temperature <- function(country, start_date, end_date,
                                         variables = "mean",
                                         request_id = NULL,
                                         resolution = 0.25,
                                         verbose = FALSE, ...) {
  var_map <- c(
    mean = "2m_temperature",
    max  = "maximum_2m_temperature_since_previous_post_processing",
    min  = "minimum_2m_temperature_since_previous_post_processing"
  )

  col_map <- c(
    "2m_temperature" = "temperature_mean",
    "maximum_2m_temperature_since_previous_post_processing" = "temperature_max",
    "minimum_2m_temperature_since_previous_post_processing" = "temperature_min",
    "t2m"  = "temperature_mean",
    "mx2t" = "temperature_max",
    "mn2t" = "temperature_min"
  )

  era5_vars <- vapply(variables, function(v) {
    if (v %in% names(var_map)) var_map[[v]] else v
  }, character(1), USE.NAMES = FALSE)

  era5_vars <- unique(era5_vars)

  polygon <- .resolve_country_polygon(country)

  tmp_geojson <- tempfile(fileext = ".geojson")
  sf::st_write(polygon, tmp_geojson, driver = "GeoJSON", quiet = TRUE)
  on.exit(unlink(tmp_geojson), add = TRUE)

  if (is.null(request_id)) {
    country_label <- if (is.character(country)) country else "custom"
    request_id <- paste0("country_", gsub("[^a-zA-Z0-9]", "_", tolower(country_label)))
  }

  raw_list <- lapply(era5_vars, function(v) {
    rid <- paste0(request_id, "_", gsub("[^a-zA-Z0-9]", "_", v))
    era5ify_geojson(
      request_id = rid,
      variables   = v,
      start_date  = start_date,
      end_date    = end_date,
      json_file   = tmp_geojson,
      frequency   = "monthly",
      resolution  = resolution,
      verbose     = verbose,
      ...
    )
  })
  raw <- do.call(rbind, raw_list)

  dt <- data.table::as.data.table(raw)
  dt[, datetime_date := as.Date(datetime)]
  dt[, c("year", "month") := .(data.table::year(datetime_date),
                                data.table::month(datetime_date))]
  dt[, datetime_date := NULL]
  dt[, weight := cos(latitude * pi / 180)]

  agg <- dt[, .(value = stats::weighted.mean(value, weight, na.rm = TRUE)),
            by = .(year, month, variable)]

  agg[, col_name := col_map[variable]]
  agg[is.na(col_name), col_name := variable]

  wide <- data.table::dcast(agg, year + month ~ col_name, value.var = "value")
  data.table::setorder(wide, year, month)

  as.data.frame(wide)
}

#' Resolve a country specification to an sf polygon
#'
#' @param country A country name (string), file path to GeoJSON, or sf object.
#' @return An sf object with the country polygon.
#' @keywords internal
.resolve_country_polygon <- function(country) {
  if (inherits(country, "sf") || inherits(country, "sfc")) {
    return(sf::st_sf(geometry = sf::st_geometry(country)))
  }

  if (!is.character(country) || length(country) != 1) {
    stop("'country' must be a country name (string), file path, or sf object.")
  }

  if (file.exists(country)) {
    return(sf::st_read(country, quiet = TRUE))
  }

  if (!requireNamespace("maps", quietly = TRUE)) {
    stop("Package 'maps' is required to resolve country names. ",
         "Install it with: install.packages('maps')")
  }

  aliases <- c(
    "USA"    = "USA",
    "US"     = "USA",
    "UK"     = "UK",
    "Russia" = "USSR"
  )

  region <- if (country %in% names(aliases)) aliases[[country]] else country

  map_data <- tryCatch(
    maps::map("world", regions = region, plot = FALSE, fill = TRUE),
    error = function(e) NULL
  )

  if (is.null(map_data)) {
    stop(
      sprintf("Country '%s' not found in maps database. ", country),
      "Check available names with: maps::map('world')$names"
    )
  }

  sf::st_as_sf(map_data)
}
