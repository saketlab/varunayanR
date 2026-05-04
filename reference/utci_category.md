# UTCI thermal stress categories

Classify thermal stress based on UTCI values.

## Usage

``` r
utci_category(utci_val)
```

## Arguments

- utci_val:

  UTCI value in Celsius

## Value

Factor with thermal stress category

## Examples

``` r
utci_category(c(-20, 0, 20, 30, 40))
#> [1] strong cold stress      Slight cold stress      No thermal stress      
#> [4] Moderate heat stress    Very strong heat stress
#> 10 Levels: Extreme cold stress Very strong cold stress ... Extreme heat stress
```
