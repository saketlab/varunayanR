# Filter data.frame by GeoJSON polygon (optimized)

Uses geometry simplification and spatial pre-aggregation for large
datasets.

## Usage

``` r
filter_dataframe_by_geojson(df, geojson_file)
```

## Arguments

- df:

  data.frame with latitude and longitude columns

- geojson_file:

  Character string path to GeoJSON file

## Value

data.frame with spatially filtered data
