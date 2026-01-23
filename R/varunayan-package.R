#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @import sf
#' @import stars
#' @importFrom data.table .SD .N .I .GRP .BY .EACHI := data.table as.data.table setDT setorder setnames year month
#' @importFrom dplyr arrange group_by summarise select semi_join n
#' @importFrom digest digest
#' @importFrom ecmwfr wf_set_key wf_request wf_get_key
#' @importFrom httr GET POST content headers status_code timeout config
#' @importFrom jsonlite fromJSON toJSON write_json
#' @importFrom lubridate ymd
#' @importFrom magrittr "%>%"
#' @importFrom ncdf4 nc_open nc_close ncvar_get
#' @importFrom rlang .data
#' @importFrom terra rast extract
#' @importFrom tools R_user_dir file_ext file_path_sans_ext
#' @importFrom utils unzip sessionInfo packageVersion install.packages
## usethis namespace: end

# Required for data.table operations
.datatable.aware <- TRUE

# Package startup message - only show CDS setup hint if credentials not found
.onAttach <- function(libname, pkgname) {
  # Check ~/.cdsapirc file first (most common setup)
  cdsapirc <- path.expand("~/.cdsapirc")
  has_creds <- file.exists(cdsapirc)

  # Also check ecmwfr credentials if file not found
  if (!has_creds) {
    has_creds <- tryCatch(
      {
        key <- wf_get_key()
        !is.null(object = key) && nchar(x = key) > 0
      },
      error = function(e) FALSE
    )
  }

  if (!has_creds) {
    packageStartupMessage("varunayan: Configure CDS credentials with setup_cds_credentials()")
    packageStartupMessage("Visit: https://cds.climate.copernicus.eu/api-how-to")
  }
}

# Package detach cleanup
.onUnload <- function(libpath) {
  # Clean up any temporary files
  temp_files <- list.files(path = tempdir(), pattern = "varunayan_.*\\.(nc|geojson)", full.names = TRUE)
  if (length(x = temp_files) > 0) {
    unlink(x = temp_files)
  }
}
