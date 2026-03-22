# Visualize grid-polygon overlap

Visualize grid-polygon overlap

## Usage

``` r
visualize_grid_overlap(
  grid_data,
  polygons,
  show_centroids = TRUE,
  grid_color = "#E74C3C",
  polygon_fill = NA,
  polygon_color = "#2C3E50",
  centroid_color = "#3498DB",
  title = "Grid-Polygon Overlap"
)
```

## Arguments

- grid_data:

  Data frame with longitude and latitude columns, or path to NetCDF/CSV

- polygons:

  sf object or path to GeoJSON file

- show_centroids:

  Logical, whether to show polygon centroids

- grid_color:

  Color for grid points

- polygon_fill:

  Fill color for polygons

- polygon_color:

  Border color for polygons

- centroid_color:

  Color for centroids

- title:

  Plot title

## Value

ggplot object
