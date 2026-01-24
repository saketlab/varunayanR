# Filter NetCDF data by spatial boundaries (bounding box)

Filter NetCDF data by spatial boundaries (bounding box)

## Usage

``` r
filter_netcdf_by_bbox(netcdf_file, north, south, east, west)
```

## Arguments

- netcdf_file:

  Character string path to NetCDF file

- north:

  Northern latitude boundary

- south:

  Southern latitude boundary

- east:

  Eastern longitude boundary

- west:

  Western longitude boundary

## Value

data.frame with spatially filtered data
