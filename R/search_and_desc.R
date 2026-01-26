#' Search and description functions for ERA5 variables

#' Search for ERA5 variables by keyword
#'
#' @param keyword Character string to search for in variable names and descriptions
#' @param dataset_type Character string indicating dataset type ("single", "pressure", or "all")
#' @param exact_match Logical indicating whether to use exact matching
#' @param ... Arguments passed to the main function (used by aliases).
#' @return data.frame with matching variables and their descriptions
#' @export
#' @examples
#' \dontrun{
#' # Search for temperature variables
#' temp_vars <- search_variable("temperature")
#'
#' # Search in pressure level data only
#' pressure_temp <- search_variable("temperature", dataset_type = "pressure")
#' }
search_variable <- function(keyword, dataset_type = "all", exact_match = FALSE) {
  dataset_type <- tolower(x = dataset_type)
  if (!dataset_type %in% c("single", "pressure", "all")) {
    stop("dataset_type must be one of 'single', 'pressure', or 'all'")
  }


  datasets_to_search <- list()

  if (dataset_type %in% c("single", "all")) {
    datasets_to_search[["single"]] <- get_single_level_variables()
  }

  if (dataset_type %in% c("pressure", "all")) {
    datasets_to_search[["pressure"]] <- get_pressure_level_variables()
  }


  results <- data.frame(
    variable_name = character(0),
    description = character(0),
    units = character(0),
    dataset_type = character(0),
    category = character(0),
    stringsAsFactors = FALSE
  )

  for (ds_name in names(datasets_to_search)) {
    dataset <- datasets_to_search[[ds_name]]

    for (category_name in names(dataset)) {
      category <- dataset[[category_name]]

      for (var_name in names(category)) {
        var_info <- category[[var_name]]

        # Search in variable name and description
        search_text <- paste(tolower(x = var_name), tolower(x = var_info$description))
        keyword_lower <- tolower(x = keyword)

        match_found <- if (exact_match) {
          keyword_lower == tolower(x = var_name)
        } else {
          grepl(keyword_lower, search_text, fixed = TRUE)
        }

        if (match_found) {
          new_row <- data.frame(
            variable_name = var_name,
            description = var_info$description,
            units = if ("units" %in% names(var_info)) var_info$units else "N/A",
            dataset_type = ds_name,
            category = category_name,
            stringsAsFactors = FALSE
          )
          results <- rbind(results, new_row)
        }
      }
    }
  }


  if (nrow(x = results) > 0) {
    order_idx <- order(results$variable_name)
    results <- results[order_idx, ]
    rownames(results) <- NULL
  }

  return(results)
}

#' Describe ERA5 variables in detail
#'
#' @param variables Character vector of variable names to describe
#' @param dataset_type Character string indicating dataset type ("single", "pressure", or "all")
#' @param ... Arguments passed to the main function (used by aliases).
#' @return data.frame with detailed variable descriptions
#' @export
#' @examples
#' \dontrun{
#' # Describe specific variables
#' descriptions <- describe_variables(c("2m_temperature", "total_precipitation"))
#'
#' # Get descriptions for pressure level variables
#' pressure_desc <- describe_variables("temperature", dataset_type = "pressure")
#' }
describe_variables <- function(variables, dataset_type = "all") {
  dataset_type <- tolower(x = dataset_type)
  if (!dataset_type %in% c("single", "pressure", "all")) {
    stop("dataset_type must be one of 'single', 'pressure', or 'all'")
  }


  datasets_to_search <- list()

  if (dataset_type %in% c("single", "all")) {
    datasets_to_search[["single"]] <- get_single_level_variables()
  }

  if (dataset_type %in% c("pressure", "all")) {
    datasets_to_search[["pressure"]] <- get_pressure_level_variables()
  }


  results <- data.frame(
    variable_name = character(0),
    description = character(0),
    units = character(0),
    dataset_type = character(0),
    category = character(0),
    stringsAsFactors = FALSE
  )

  for (var_name in variables) {
    found <- FALSE

    for (ds_name in names(datasets_to_search)) {
      if (found) break

      dataset <- datasets_to_search[[ds_name]]

      for (category_name in names(dataset)) {
        if (found) break

        category <- dataset[[category_name]]

        if (var_name %in% names(category)) {
          var_info <- category[[var_name]]

          new_row <- data.frame(
            variable_name = var_name,
            description = var_info$description,
            units = if ("units" %in% names(var_info)) var_info$units else "N/A",
            dataset_type = ds_name,
            category = category_name,
            stringsAsFactors = FALSE
          )
          results <- rbind(results, new_row)

          found <- TRUE
        }
      }
    }

    if (!found) {
      not_found_row <- data.frame(
        variable_name = var_name,
        description = "Variable not found",
        units = "N/A",
        dataset_type = "unknown",
        category = "unknown",
        stringsAsFactors = FALSE
      )
      results <- rbind(results, not_found_row)
    }
  }

  rownames(results) <- NULL
  return(results)
}

#' Get available dataset types
#'
#' @return Character vector of available dataset types
#' @export
get_available_datasets <- function() {
  return(c("single", "pressure"))
}

#' List all available variables for a dataset type
#'
#' @param dataset_type Character string indicating dataset type
#' @param ... Arguments passed to the main function (used by aliases).
#' @return Character vector of variable names
#' @export
list_available_variables <- function(dataset_type = "all") {
  dataset_type <- tolower(x = dataset_type)
  if (!dataset_type %in% c("single", "pressure", "all")) {
    stop("dataset_type must be one of 'single', 'pressure', or 'all'")
  }

  all_variables <- character(0)

  if (dataset_type %in% c("single", "all")) {
    single_vars <- get_single_level_variables()
    for (category in single_vars) {
      all_variables <- c(all_variables, names(category))
    }
  }

  if (dataset_type %in% c("pressure", "all")) {
    pressure_vars <- get_pressure_level_variables()
    for (category in pressure_vars) {
      all_variables <- c(all_variables, names(category))
    }
  }

  return(sort(x = unique(x = all_variables)))
}

#' Get single-level variables dataset
#'
#' @return List containing single-level variable categories
get_single_level_variables <- function() {
  list(
    temperature_and_pressure = list(
      "2m_temperature" = list(
        description = "2 metre temperature",
        units = "K"
      ),
      "surface_pressure" = list(
        description = "Surface pressure",
        units = "Pa"
      ),
      "mean_sea_level_pressure" = list(
        description = "Mean sea level pressure",
        units = "Pa"
      ),
      "2m_dewpoint_temperature" = list(
        description = "2 metre dewpoint temperature",
        units = "K"
      ),
      "skin_temperature" = list(
        description = "Skin temperature",
        units = "K"
      )
    ),
    precipitation_variables = list(
      "total_precipitation" = list(
        description = "Total precipitation",
        units = "m"
      ),
      "convective_precipitation" = list(
        description = "Convective precipitation",
        units = "m"
      ),
      "large_scale_precipitation" = list(
        description = "Large scale precipitation",
        units = "m"
      )
    ),
    wind_variables = list(
      "10m_u_component_of_wind" = list(
        description = "10 metre U wind component",
        units = "m s**-1"
      ),
      "10m_v_component_of_wind" = list(
        description = "10 metre V wind component",
        units = "m s**-1"
      )
    ),
    radiation_variables = list(
      "surface_solar_radiation_downwards" = list(
        description = "Surface solar radiation downwards",
        units = "J m**-2"
      ),
      "surface_thermal_radiation_downwards" = list(
        description = "Surface thermal radiation downwards",
        units = "J m**-2"
      ),
      "surface_latent_heat_flux" = list(
        description = "Surface latent heat flux",
        units = "J m**-2"
      ),
      "surface_sensible_heat_flux" = list(
        description = "Surface sensible heat flux",
        units = "J m**-2"
      )
    ),
    cloud_variables = list(
      "total_cloud_cover" = list(
        description = "Total cloud cover",
        units = "(0 - 1)"
      ),
      "low_cloud_cover" = list(
        description = "Low cloud cover",
        units = "(0 - 1)"
      ),
      "medium_cloud_cover" = list(
        description = "Medium cloud cover",
        units = "(0 - 1)"
      ),
      "high_cloud_cover" = list(
        description = "High cloud cover",
        units = "(0 - 1)"
      )
    ),
    surface_fluxes = list(
      "evaporation" = list(
        description = "Evaporation",
        units = "m of water equivalent"
      ),
      "runoff" = list(
        description = "Runoff",
        units = "m"
      )
    ),
    soil_variables = list(
      "soil_temperature_level_1" = list(
        description = "Soil temperature level 1",
        units = "K"
      ),
      "soil_temperature_level_2" = list(
        description = "Soil temperature level 2",
        units = "K"
      ),
      "soil_temperature_level_3" = list(
        description = "Soil temperature level 3",
        units = "K"
      ),
      "soil_temperature_level_4" = list(
        description = "Soil temperature level 4",
        units = "K"
      ),
      "volumetric_soil_water_layer_1" = list(
        description = "Volumetric soil water layer 1",
        units = "m**3 m**-3"
      ),
      "volumetric_soil_water_layer_2" = list(
        description = "Volumetric soil water layer 2",
        units = "m**3 m**-3"
      ),
      "volumetric_soil_water_layer_3" = list(
        description = "Volumetric soil water layer 3",
        units = "m**3 m**-3"
      ),
      "volumetric_soil_water_layer_4" = list(
        description = "Volumetric soil water layer 4",
        units = "m**3 m**-3"
      )
    ),
    snow_variables = list(
      "snow_depth" = list(
        description = "Snow depth",
        units = "m of water equivalent"
      ),
      "snow_density" = list(
        description = "Snow density",
        units = "kg m**-3"
      )
    )
  )
}

#' Get pressure-level variables dataset
#'
#' @return List containing pressure-level variable categories
get_pressure_level_variables <- function() {
  list(
    atmospheric_variables = list(
      "temperature" = list(
        description = "Temperature",
        units = "K"
      ),
      "u_component_of_wind" = list(
        description = "U component of wind",
        units = "m s**-1"
      ),
      "v_component_of_wind" = list(
        description = "V component of wind",
        units = "m s**-1"
      ),
      "geopotential" = list(
        description = "Geopotential",
        units = "m**2 s**-2"
      ),
      "relative_humidity" = list(
        description = "Relative humidity",
        units = "%"
      ),
      "specific_humidity" = list(
        description = "Specific humidity",
        units = "kg kg**-1"
      ),
      "vertical_velocity" = list(
        description = "Vertical velocity",
        units = "Pa s**-1"
      ),
      "vorticity" = list(
        description = "Vorticity (relative)",
        units = "s**-1"
      ),
      "divergence" = list(
        description = "Divergence",
        units = "s**-1"
      )
    )
  )
}

#' Get standard pressure levels available in ERA5
#'
#' @param ... Arguments passed to the main function (used by aliases).
#' @return Character vector of pressure levels in hPa
#' @export
get_available_pressure_levels <- function() {
  c(
    "1000", "975", "950", "925", "900", "875", "850", "825", "800", "775",
    "750", "700", "650", "600", "550", "500", "450", "400", "350", "300",
    "250", "225", "200", "175", "150", "125", "100", "70", "50", "30",
    "20", "10", "7", "5", "3", "2", "1"
  )
}
