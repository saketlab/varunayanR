# ERA5 data download functions using ecmwfr Set up CDS credentials for ERA5 data access

This function helps users set up their Copernicus Climate Data Store
(CDS) credentials for downloading ERA5 data. If no key is provided, it
will attempt to read credentials from the standard ~/.cdsapirc file.

## Usage

``` r
SetupCdsCredentials(...)

setup_cds_credentials(key = NULL)
```

## Arguments

- key:

  Your CDS API key (UUID format). If NULL, attempts to read from
  ~/.cdsapirc

## Value

Invisible TRUE if successful

## Examples

``` r
if (FALSE) { # \dontrun{
setup_cds_credentials(key = "your-cds-api-key-here")
setup_cds_credentials()
} # }
```
