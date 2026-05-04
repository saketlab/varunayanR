# heat stress risk categories

Classify heat stress risk based on WBGT values using ISO 7243
guidelines.

## Usage

``` r
wbgt_risk_category(wbgt)
```

## Arguments

- wbgt:

  WBGT value in celsius

## Value

Factor with risk category

## Examples

``` r
wbgt_risk_category(c(25, 28, 31, 34))
#> [1] Moderate  High      Very high Extreme  
#> Levels: Low Moderate High Very high Extreme
```
