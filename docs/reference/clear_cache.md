# Clear cache

Clear cache

## Usage

``` r
ClearCache(...)

clear_cache(source = NULL, older_than = NULL, confirm = TRUE)
```

## Arguments

- source:

  Clear only "era5", "imd", or NULL for all

- older_than:

  Remove files older than this many days (NULL = all)

- confirm:

  Ask for confirmation (default: TRUE)

## Value

Number of files deleted (invisible)
