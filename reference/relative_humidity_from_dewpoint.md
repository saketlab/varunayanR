# Calculate relative humidity from temperature and dewpoint

Uses the Magnus-Tetens approximation to calculate relative humidity from
air temperature and dewpoint temperature.

## Usage

``` r
relative_humidity_from_dewpoint(temp_c, dewpoint_c)
```

## Arguments

- temp_c:

  Air temperature in celsius

- dewpoint_c:

  Dewpoint temperature in celsius

## Value

Relative humidity as percentage (0-100)

## Examples

``` r
relative_humidity_from_dewpoint(25, 18)
#> [1] 65.14551
```
