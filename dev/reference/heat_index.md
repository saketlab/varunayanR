# Calculate heat index (apparent temperature)

Calculate heat index (apparent temperature)

## Usage

``` r
heat_index(temp_c, rh)
```

## Arguments

- temp_c:

  Air temperature in celsius

- rh:

  Relative humidity as percentage (0-100)

## Value

Heat index in celsius

## References

Rothfusz, L.P. (1990). The Heat Index Equation. NWS Southern Region
Technical Attachment, SR/SSD 90-23.
https://www.weather.gov/media/ffc/ta_htindx.PDF

## Examples

``` r
heat_index(35, 70)
#> [1] 50.34058
```
