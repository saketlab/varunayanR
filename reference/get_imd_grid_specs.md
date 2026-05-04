# Get IMD grid specifications

Returns grid specifications for different IMD datasets.

## Usage

``` r
get_imd_grid_specs(dataset)
```

## Arguments

- dataset:

  Dataset identifier: "rainfall_0.25", "rainfall_1.0", "tmax_1.0",
  "tmin_1.0".

## Value

List with grid specifications.

## Examples

``` r
specs <- get_imd_grid_specs("rainfall_0.25")
```
