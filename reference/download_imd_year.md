# Internal function to download a single year of IMD data

Internal function to download a single year of IMD data

## Usage

``` r
download_imd_year(
  year,
  php_file,
  param_name,
  base_url,
  output_file,
  max_retries = 3
)
```

## Arguments

- year:

  Year to download.

- php_file:

  PHP endpoint file.

- param_name:

  POST parameter name.

- base_url:

  Base URL.

- output_file:

  Path to save the downloaded file.

- max_retries:

  Maximum number of retry attempts.

## Value

Character string path to downloaded file
