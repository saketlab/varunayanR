# Search and description functions for ERA5 variables Search for ERA5 variables by keyword

Search and description functions for ERA5 variables Search for ERA5
variables by keyword

## Usage

``` r
SearchVariable(...)

search_variable(keyword, dataset_type = "all", exact_match = FALSE)
```

## Arguments

- keyword:

  Character string to search for in variable names and descriptions

- dataset_type:

  Character string indicating dataset type ("single", "pressure", or
  "all")

- exact_match:

  Logical indicating whether to use exact matching

## Value

data.frame with matching variables and their descriptions

## Examples

``` r
if (FALSE) { # \dontrun{
# Search for temperature variables
temp_vars <- search_variable("temperature")

# Search in pressure level data only
pressure_temp <- search_variable("temperature", dataset_type = "pressure")
} # }
```
