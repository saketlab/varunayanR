# Compare multiple grids

Compare multiple grids

## Usage

``` r
compare_grids(
  ...,
  polygons = NULL,
  colors = NULL,
  shapes = NULL,
  point_size = 1,
  polygon_color = "#2C3E50",
  title = "Grid Comparison"
)
```

## Arguments

- ...:

  Named data frames with longitude and latitude columns

- polygons:

  Optional sf object to show polygon boundaries

- colors:

  Named vector of colors for each grid

- shapes:

  Named vector of point shapes for each grid

- point_size:

  Size of grid points

- polygon_color:

  Color for polygon boundaries

- title:

  Plot title

## Value

ggplot object
