# Heat index risk categories

Classify heat stress risk based on heat index using NWS categories.

## Usage

``` r
heat_index_risk_category(hi)
```

## Arguments

- hi:

  Heat index value in Celsius

## Value

Factor with risk category

## Examples

``` r
heat_index_risk_category(c(27, 33, 40, 46, 55))
#> [1] Caution         Extreme Caution Extreme Caution Danger         
#> [5] Extreme Danger 
#> Levels: Normal Caution Extreme Caution Danger Extreme Danger
```
