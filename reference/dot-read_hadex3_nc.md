# Read a HadEX3 NetCDF file into a data.frame

HadEX3 NetCDF files use dimension names "longitude"/"latitude" (not
"lon"/"lat"), longitudes in 0-360 range, and variable name "Ann" for
annual files vs. the index name (e.g. "TXx") for monthly files. All
files have dims (longitude, latitude, time).

## Usage

``` r
.read_hadex3_nc(nc_file, index, frequency)
```

## Arguments

- nc_file:

  Path to decompressed .nc file.

- index:

  ETCCDI index name.

- frequency:

  "annual" or "monthly".

## Value

data.frame with columns year (+ month for monthly), latitude, longitude,
value.
