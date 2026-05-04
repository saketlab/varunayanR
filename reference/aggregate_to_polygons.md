# Spatial utilities for aggregating gridded data to polygons Aggregate gridded data to polygon regions

Spatial utilities for aggregating gridded data to polygons Aggregate
gridded data to polygon regions

## Usage

``` r
aggregate_to_polygons(
  data,
  polygons,
  value_col,
  method = c("nearest_centroid", "point_in_polygon"),
  polygon_id_cols = NULL,
  agg_fun = mean
)
```

## Arguments

- data:

  Data frame with longitude, latitude, and value columns

- polygons:

  sf object with polygon geometries

- value_col:

  Name of the column containing values to aggregate

- method:

  Aggregation method: "point_in_polygon" or "nearest_centroid"

- polygon_id_cols:

  Character vector of column names to use as polygon identifiers

- agg_fun:

  Aggregation function (default: mean)

## Value

Data frame with aggregated values per polygon
