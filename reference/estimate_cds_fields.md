# Estimate the number of CDS "fields" in a request

The CDS API limits requests to 120,000 fields for hourly/daily
reanalysis and 10,000 fields for monthly means. A field is one variable
x one time step x one pressure level.

## Usage

``` r
estimate_cds_fields(
  n_variables,
  start_date,
  end_date,
  frequency,
  n_pressure_levels = 1L
)
```

## Arguments

- n_variables:

  Number of variables requested

- start_date:

  Start date

- end_date:

  End date

- frequency:

  "hourly", "daily", or "monthly"

- n_pressure_levels:

  Number of pressure levels (1 for single-level)

## Value

Integer number of estimated fields
