# Calculate UTCI using sparse regression approximation

Calculates UTCI using the sparse regression approximation with Legendre
polynomials from Roman et al. (2025). This is a more accurate
approximation than the original Bröde et al. (2012) polynomial, with
fewer terms and better numerical stability.

## Usage

``` r
utci_sparse(temp_c, tmrt, wind_speed, rh)
```

## Arguments

- temp_c:

  Air temperature in Celsius (-50 to 50)

- tmrt:

  Mean radiant temperature in Celsius

- wind_speed:

  Wind speed at 10m height in m/s (0.5 to 30.3)

- rh:

  Relative humidity as percentage (5 to 100)

## Value

UTCI in Celsius

## References

Roman, S., Skok, G., Todorovski, L., & Dzeroski, S. (2025). UTCI
approximation using sparse regression with orthogonal polynomials.
Zenodo. https://doi.org/10.5281/zenodo.17465548
https://arxiv.org/abs/2508.11307

## Examples

``` r
utci_sparse(30, tmrt = 40, wind_speed = 2, rh = 60)
#> [1] 32.75453
utci_sparse(35, tmrt = 35, wind_speed = 1, rh = 80)
#> [1] 43.45678
```
