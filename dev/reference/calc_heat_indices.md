# Calculate all heat stress indices

Convenience function to calculate all heat stress indices at once from
temperature and dewpoint (standard ERA5 output).

## Usage

``` r
calc_heat_indices(
  temp_c,
  dewpoint_c,
  solar_radiation = NULL,
  wind_speed = NULL
)
```

## Arguments

- temp_c:

  Air temperature in celsius

- dewpoint_c:

  Dewpoint temperature in celsius

- solar_radiation:

  Optional solar radiation in W/m2 for WBGT

- wind_speed:

  Optional wind speed in m/s for WBGT

## Value

Data frame with columns: temp_c, dewpoint_c, rh, wet_bulb, heat_index,
wbgt, humidex

## Examples

``` r
calc_heat_indices(35, 25)
#>   temp_c dewpoint_c   rh wet_bulb heat_index  wbgt humidex
#> 1     35         25 56.3     27.8      43.32 29.96   47.34
calc_heat_indices(c(30, 35, 40), c(20, 25, 28))
#>   temp_c dewpoint_c   rh wet_bulb heat_index  wbgt humidex
#> 1     30         20 55.1    23.17      31.90 25.22   37.57
#> 2     35         25 56.3    27.80      43.32 29.96   47.34
#> 3     40         28 51.2    31.15      55.62 33.80   55.89
```
