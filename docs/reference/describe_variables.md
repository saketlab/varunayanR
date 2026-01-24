# Describe ERA5 variables in detail

Describe ERA5 variables in detail

## Usage

``` r
DescribeVariables(...)

describe_variables(variables, dataset_type = "all")
```

## Arguments

- variables:

  Character vector of variable names to describe

- dataset_type:

  Character string indicating dataset type ("single", "pressure", or
  "all")

## Value

data.frame with detailed variable descriptions

## Examples

``` r
if (FALSE) { # \dontrun{
# Describe specific variables
descriptions <- describe_variables(c("2m_temperature", "total_precipitation"))

# Get descriptions for pressure level variables
pressure_desc <- describe_variables("temperature", dataset_type = "pressure")
} # }
```
