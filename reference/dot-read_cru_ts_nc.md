# Read a CRU TS NetCDF file into a data.frame

Read a CRU TS NetCDF file into a data.frame

## Usage

``` r
.read_cru_ts_nc(nc_file, variable)
```

## Arguments

- nc_file:

  Path to decompressed .nc file.

- variable:

  CRU TS variable code.

## Value

data.frame with year, month, latitude, longitude, value, variable.
