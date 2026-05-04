# Download and decompress a HadEX3 NetCDF file

Download and decompress a HadEX3 NetCDF file

## Usage

``` r
.download_hadex3_file(index, frequency, baseline, output_dir)
```

## Arguments

- index:

  ETCCDI index name.

- frequency:

  "annual" or "monthly".

- baseline:

  Baseline period for annual data.

- output_dir:

  Directory for temporary files.

## Value

Path to decompressed .nc file.
