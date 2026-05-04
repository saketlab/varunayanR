# Variable data dictionary for CRU TS

Maps CRU TS variable codes to common names, units, and ERA5 equivalents.

## Usage

``` r
ListCRUTSVariables(...)

list_cru_ts_variables(...)
```

## Arguments

- ...:

  Arguments passed to the main function (used by aliases).

## Value

data.frame with columns: variable, name, description, unit,
era5_equivalent, hadex3_equivalent.

## Examples

``` r
list_cru_ts_variables()
#>    variable                         name
#> 1       tmp             mean_temperature
#> 2       tmx              max_temperature
#> 3       tmn              min_temperature
#> 4       dtr    diurnal_temperature_range
#> 5       pre                precipitation
#> 6       wet            wet_day_frequency
#> 7       frs          frost_day_frequency
#> 8       vap              vapour_pressure
#> 9       cld                  cloud_cover
#> 10      pet potential_evapotranspiration
#>                                                     description       unit
#> 1                           Monthly mean daily mean temperature         °C
#> 2                        Monthly mean daily maximum temperature         °C
#> 3                        Monthly mean daily minimum temperature         °C
#> 4            Monthly mean diurnal temperature range (tmx - tmn)         °C
#> 5                                   Monthly total precipitation   mm/month
#> 6           Monthly count of wet days (precipitation >= 0.1 mm) days/month
#> 7       Monthly count of frost days (minimum temperature < 0°C) days/month
#> 8                                  Monthly mean vapour pressure        hPa
#> 9               Monthly mean cloud cover (oktas converted to %)          %
#> 10 Monthly total potential evapotranspiration (Penman-Monteith)   mm/month
#>                                          era5_equivalent hadex3_equivalent
#> 1                                         2m_temperature              <NA>
#> 2  maximum_2m_temperature_since_previous_post_processing           TXx/TXn
#> 3  minimum_2m_temperature_since_previous_post_processing           TNx/TNn
#> 4                                                   <NA>               DTR
#> 5                                    total_precipitation           PRCPTOT
#> 6                                                   <NA>               CWD
#> 7                                                   <NA>                FD
#> 8                                2m_dewpoint_temperature              <NA>
#> 9                                      total_cloud_cover              <NA>
#> 10                                                  <NA>              <NA>
```
