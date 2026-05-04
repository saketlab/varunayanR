# Calculate humidex (Canadian heat index)

Calculate humidex (Canadian heat index)

## Usage

``` r
humidex(temp_c, dewpoint_c)
```

## Arguments

- temp_c:

  Air temperature in celsius

- dewpoint_c:

  Dewpoint temperature in celsius

## Value

Humidex in celsius

## References

Masterson, J. & Richardson, F.A. (1979). Humidex, A Method of
Quantifying Human Discomfort Due to Excessive Heat and Humidity.
Environment Canada, Atmospheric Environment Service.

## Examples

``` r
humidex(30, 22)
#> [1] 39.32078
```
