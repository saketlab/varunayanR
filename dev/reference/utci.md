# Calculate UTCI (Universal Thermal Climate Index)

Calculates UTCI using the polynomial approximation from Bröde et al.
(2012). UTCI is the most comprehensive thermal comfort index, based on a
multi-node model of human thermoregulation.

## Usage

``` r
utci(temp_c, wind_speed, dewpoint_c, tmrt = NULL)
```

## Arguments

- temp_c:

  Air temperature in Celsius (-50 to 50)

- wind_speed:

  Wind speed at 10m height in m/s (0.5 to 17)

- dewpoint_c:

  Dewpoint temperature in Celsius (to calculate vapor pressure)

- tmrt:

  Mean radiant temperature in Celsius (optional, defaults to temp_c)

## Value

UTCI in Celsius

## References

Bröde, P., et al. (2012). Deriving the operational procedure for the
Universal Thermal Climate Index (UTCI). International Journal of
Biometeorology, 56(3), 481-494.

## Examples

``` r
utci(30, wind_speed = 2, dewpoint_c = 20)
#> [1] 30.03632
utci(35, wind_speed = 1, dewpoint_c = 25, tmrt = 45)
#> [1] 39.65806
```
