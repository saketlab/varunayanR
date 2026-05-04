# Calculate WBGT (Wet Bulb Globe Temperature)

Calculates WBGT for occupational heat stress assessment. Uses the
standard formula: WBGT = 0.7*Tnwb + 0.2*Tg + 0.1*Ta (outdoor) or WBGT =
0.7*Tnwb + 0.3\*Tg (indoor/shaded).

## Usage

``` r
wbgt_simple(temp_c, rh, wind_speed = 0.5, solar_radiation = NULL)
```

## Arguments

- temp_c:

  Air temperature in Celsius

- rh:

  Relative humidity as percentage (0-100)

- wind_speed:

  Wind speed in m/s (default: 0.5 for still air)

- solar_radiation:

  Solar radiation in W/m2 (NULL for indoor/shaded)

## Value

WBGT in Celsius

## References

Liljegren, J.C., et al. (2008). Modeling the Wet Bulb Globe Temperature
Using Standard Meteorological Measurements. J. Occup. Environ. Hyg.,
5(10), 645-655. Methods for Estimating Wet Bulb Globe Temperature

## Examples

``` r
wbgt_simple(35, 70)
#> [1] 31.67735
wbgt_simple(35, 70, wind_speed = 2, solar_radiation = 800)
#> [1] 36.10711
```
