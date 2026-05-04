# List available HadEX3 ETCCDI indices

Returns a data.frame describing all ETCCDI climate extremes indices
available in the HadEX3 dataset, including their temporal availability
and physical interpretation.

## Usage

``` r
ListHadEX3Indices(...)

list_hadex3_indices(frequency = "all")
```

## Arguments

- ...:

  Arguments passed to the main function (used by aliases).

- frequency:

  Filter by frequency: "annual", "monthly", or "all" (default).

## Value

data.frame with columns: index, category, description, unit, annual,
monthly.

## Examples

``` r
list_hadex3_indices()
#>      index               category                                description
#> 1      TXx            Temperature        Max of daily max temp (hottest day)
#> 2      TXn            Temperature        Min of daily max temp (coldest day)
#> 3      TNx            Temperature      Max of daily min temp (warmest night)
#> 4      TNn            Temperature      Min of daily min temp (coldest night)
#> 5    TX90p Temperature percentile           % days with TX > 90th percentile
#> 6    TX10p Temperature percentile           % days with TX < 10th percentile
#> 7    TN90p Temperature percentile           % days with TN > 90th percentile
#> 8    TN10p Temperature percentile           % days with TN < 10th percentile
#> 9       TR  Temperature threshold                Tropical nights (TN > 20°C)
#> 10      SU  Temperature threshold                    Summer days (TX > 25°C)
#> 11      FD  Temperature threshold                      Frost days (TN < 0°C)
#> 12      ID  Temperature threshold                        Ice days (TX < 0°C)
#> 13    CSDI   Temperature duration                  Cold spell duration index
#> 14    WSDI   Temperature duration                  Warm spell duration index
#> 15     DTR   Temperature duration          Diurnal temperature range (TX-TN)
#> 16     GSL            Temperature                      Growing season length
#> 17     ETR            Temperature     Intra-annual extreme temperature range
#> 18     CDD          Precipitation            Consecutive dry days (P < 1 mm)
#> 19     CWD          Precipitation           Consecutive wet days (P >= 1 mm)
#> 20 PRCPTOT          Precipitation                Total wet-day precipitation
#> 21   R10mm          Precipitation      Heavy precipitation days (P >= 10 mm)
#> 22   R20mm          Precipitation Very heavy precipitation days (P >= 20 mm)
#> 23  Rx1day          Precipitation                    Max 1-day precipitation
#> 24  Rx5day          Precipitation                    Max 5-day precipitation
#> 25    R95p          Precipitation      Precipitation > 95th percentile total
#> 26    R99p          Precipitation      Precipitation > 99th percentile total
#> 27 R95pTOT          Precipitation           Fraction of total from R95p days
#> 28 R99pTOT          Precipitation           Fraction of total from R99p days
#> 29    SDII          Precipitation               Simple daily intensity index
#>      unit annual monthly
#> 1      °C   TRUE    TRUE
#> 2      °C   TRUE    TRUE
#> 3      °C   TRUE    TRUE
#> 4      °C   TRUE    TRUE
#> 5       %   TRUE    TRUE
#> 6       %   TRUE    TRUE
#> 7       %   TRUE    TRUE
#> 8       %   TRUE    TRUE
#> 9    days   TRUE    TRUE
#> 10   days   TRUE    TRUE
#> 11   days   TRUE    TRUE
#> 12   days   TRUE    TRUE
#> 13   days   TRUE   FALSE
#> 14   days   TRUE   FALSE
#> 15     °C   TRUE    TRUE
#> 16   days   TRUE   FALSE
#> 17     °C   TRUE    TRUE
#> 18   days   TRUE   FALSE
#> 19   days   TRUE   FALSE
#> 20     mm   TRUE    TRUE
#> 21   days   TRUE   FALSE
#> 22   days   TRUE   FALSE
#> 23     mm   TRUE    TRUE
#> 24     mm   TRUE    TRUE
#> 25     mm   TRUE   FALSE
#> 26     mm   TRUE   FALSE
#> 27      %   TRUE   FALSE
#> 28      %   TRUE   FALSE
#> 29 mm/day   TRUE    TRUE
list_hadex3_indices(frequency = "monthly")
#>      index               category                            description   unit
#> 1      TXx            Temperature    Max of daily max temp (hottest day)     °C
#> 2      TXn            Temperature    Min of daily max temp (coldest day)     °C
#> 3      TNx            Temperature  Max of daily min temp (warmest night)     °C
#> 4      TNn            Temperature  Min of daily min temp (coldest night)     °C
#> 5    TX90p Temperature percentile       % days with TX > 90th percentile      %
#> 6    TX10p Temperature percentile       % days with TX < 10th percentile      %
#> 7    TN90p Temperature percentile       % days with TN > 90th percentile      %
#> 8    TN10p Temperature percentile       % days with TN < 10th percentile      %
#> 9       TR  Temperature threshold            Tropical nights (TN > 20°C)   days
#> 10      SU  Temperature threshold                Summer days (TX > 25°C)   days
#> 11      FD  Temperature threshold                  Frost days (TN < 0°C)   days
#> 12      ID  Temperature threshold                    Ice days (TX < 0°C)   days
#> 15     DTR   Temperature duration      Diurnal temperature range (TX-TN)     °C
#> 17     ETR            Temperature Intra-annual extreme temperature range     °C
#> 20 PRCPTOT          Precipitation            Total wet-day precipitation     mm
#> 23  Rx1day          Precipitation                Max 1-day precipitation     mm
#> 24  Rx5day          Precipitation                Max 5-day precipitation     mm
#> 29    SDII          Precipitation           Simple daily intensity index mm/day
#>    annual monthly
#> 1    TRUE    TRUE
#> 2    TRUE    TRUE
#> 3    TRUE    TRUE
#> 4    TRUE    TRUE
#> 5    TRUE    TRUE
#> 6    TRUE    TRUE
#> 7    TRUE    TRUE
#> 8    TRUE    TRUE
#> 9    TRUE    TRUE
#> 10   TRUE    TRUE
#> 11   TRUE    TRUE
#> 12   TRUE    TRUE
#> 15   TRUE    TRUE
#> 17   TRUE    TRUE
#> 20   TRUE    TRUE
#> 23   TRUE    TRUE
#> 24   TRUE    TRUE
#> 29   TRUE    TRUE
```
