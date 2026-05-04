# Compute optimal chunk size to stay within CDS field limits

Uses 90% of the CDS limit as headroom. Returns max years for monthly
frequency, max days for hourly/daily.

## Usage

``` r
compute_optimal_chunk_size(n_variables, frequency, n_pressure_levels = 1L)
```

## Arguments

- n_variables:

  Number of variables

- frequency:

  "hourly", "daily", or "monthly"

- n_pressure_levels:

  Number of pressure levels (1 for single-level)

## Value

Integer: max years (monthly) or max days (hourly/daily) per chunk
