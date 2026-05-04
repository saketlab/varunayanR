# Calculate WBGT from dewpoint

Calculate WBGT from dewpoint

## Usage

``` r
wbgt_from_dewpoint(
  temp_c,
  dewpoint_c,
  wind_speed = 0.5,
  solar_radiation = NULL
)
```

## Arguments

- temp_c:

  Air temperature in celsius

- dewpoint_c:

  Dewpoint temperature in celsius

- wind_speed:

  Wind speed in m/s (default: 0.5)

- solar_radiation:

  Solar radiation in W/m2 (NULL for indoor/shaded)

## Value

WBGT in Celsius

## Examples

``` r
wbgt_from_dewpoint(35, 25)
#> [1] 29.96159
wbgt_from_dewpoint(35, 25, wind_speed = 3, solar_radiation = 800)
#> [1] 34.40243
```
