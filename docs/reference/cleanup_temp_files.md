# Clean up temporary files matching pattern

Clean up temporary files matching pattern

## Usage

``` r
cleanup_temp_files(pattern = "varunayan_.*", directory = tempdir())
```

## Arguments

- pattern:

  Regular expression pattern to match files

- directory:

  Directory to search (default: tempdir())

## Value

Number of files removed
