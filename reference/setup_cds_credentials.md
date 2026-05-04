# Set up CDS credentials for ERA5 data access

Sets up Copernicus Climate Data Store (CDS) credentials for ERA5
downloads. Credentials are checked in the following order:

1.  Directly provided `key` argument

2.  `CDS_API_KEY` environment variable

3.  `~/.cdsapirc` file

## Usage

``` r
SetupCdsCredentials(...)

setup_cds_credentials(key = NULL)
```

## Arguments

- ...:

  Arguments passed to the main function (used by aliases).

- key:

  Your CDS API key (UUID format). If NULL, attempts to read from
  environment variable `CDS_API_KEY` or ~/.cdsapirc file.

## Value

Invisible TRUE if successful

## Examples

``` r
if (FALSE) { # \dontrun{
setup_cds_credentials(key = "your-cds-api-key-here")
Sys.setenv(CDS_API_KEY = "your-cds-api-key-here")
setup_cds_credentials()
} # }
```
