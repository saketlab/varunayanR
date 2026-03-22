# Estimate mean radiant temperature

Estimates mean radiant temperature (Tmrt) from meteorological variables.
Uses simplified approach when full radiation data unavailable.

## Usage

``` r
mean_radiant_temperature(temp_c, solar_radiation = NULL, wind_speed = NULL)
```

## Arguments

- temp_c:

  Air temperature in Celsius

- solar_radiation:

  Solar radiation in W/m2 (optional)

- wind_speed:

  Wind speed in m/s (optional)

## Value

Mean radiant temperature in Celsius

## Examples

``` r
mean_radiant_temperature(30, solar_radiation = 800, wind_speed = 2)
#> [1] 32.68402
```
