# Apply temporal chunking for large date ranges

Apply temporal chunking for large date ranges

## Usage

``` r
create_temporal_chunks(
  start_date,
  end_date,
  frequency,
  max_days_per_chunk = 31
)
```

## Arguments

- start_date:

  Start date

- end_date:

  End date

- frequency:

  Temporal frequency

- max_days_per_chunk:

  Maximum days per chunk

## Value

List of date pairs for chunked processing
