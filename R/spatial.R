#' Spatial utilities for aggregating gridded data to polygons

#' Aggregate gridded data to polygon regions
#'
#' @param data Data frame with longitude, latitude, and value columns
#' @param polygons sf object with polygon geometries
#' @param value_col Name of the column containing values to aggregate
#' @param method Aggregation method: "point_in_polygon" or "nearest_centroid"
#' @param polygon_id_cols Character vector of column names to use as polygon identifiers
#' @param agg_fun Aggregation function (default: mean)
#' @return Data frame with aggregated values per polygon
#' @export
aggregate_to_polygons <- function(data, polygons, value_col,
                                  method = c("nearest_centroid", "point_in_polygon"),
                                  polygon_id_cols = NULL,
                                  agg_fun = mean) {
  method <- match.arg(method)

  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required for spatial operations")
  }

  if (is.null(polygon_id_cols)) {
    polygon_id_cols <- setdiff(names(polygons), attr(polygons, "sf_column"))
  }

  old_s2 <- sf::sf_use_s2()
  sf::sf_use_s2(FALSE)

  on.exit(sf::sf_use_s2(old_s2), add = TRUE)

  if (method == "point_in_polygon") {
    result <- aggregate_point_in_polygon(data, polygons, value_col, polygon_id_cols, agg_fun)
  } else {
    result <- aggregate_nearest_centroid(data, polygons, value_col, polygon_id_cols, agg_fun)
  }

  return(result)
}

#' Aggregate using point-in-polygon method
#' @noRd
aggregate_point_in_polygon <- function(data, polygons, value_col, polygon_id_cols, agg_fun) {
  pts <- sf::st_as_sf(data, coords = c("longitude", "latitude"), crs = 4326)
  joined <- sf::st_join(polygons, pts)

  result <- joined %>%
    as.data.frame() %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(polygon_id_cols))) %>%
    dplyr::summarise(value = agg_fun(.data[[value_col]], na.rm = TRUE), .groups = "drop")

  return(result)
}

#' Aggregate using nearest centroid method
#' @noRd
aggregate_nearest_centroid <- function(data, polygons, value_col, polygon_id_cols, agg_fun) {
  centroids <- sf::st_centroid(polygons)
  pts <- sf::st_as_sf(data, coords = c("longitude", "latitude"), crs = 4326)

  nearest_idx <- sf::st_nearest_feature(centroids, pts)

  result <- polygons %>%
    as.data.frame() %>%
    dplyr::select(dplyr::all_of(polygon_id_cols))

  result$value <- data[[value_col]][nearest_idx]

  if (!identical(agg_fun, identity)) {
    result <- result %>%
      dplyr::group_by(dplyr::across(dplyr::all_of(polygon_id_cols))) %>%
      dplyr::summarise(value = agg_fun(value, na.rm = TRUE), .groups = "drop")
  }

  return(result)
}

#' Visualize grid-polygon overlap
#'
#' @param grid_data Data frame with longitude and latitude columns, or path to NetCDF/CSV
#' @param polygons sf object or path to GeoJSON file
#' @param show_centroids Logical, whether to show polygon centroids
#' @param grid_color Color for grid points
#' @param polygon_fill Fill color for polygons
#' @param polygon_color Border color for polygons
#' @param centroid_color Color for centroids
#' @param title Plot title
#' @return ggplot object
#' @export
visualize_grid_overlap <- function(grid_data, polygons,
                                   show_centroids = TRUE,
                                   grid_color = "#E74C3C",
                                   polygon_fill = NA,
                                   polygon_color = "#2C3E50",
                                   centroid_color = "#3498DB",
                                   title = "Grid-Polygon Overlap") {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required")
  }

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required")
  }

  if (is.character(polygons)) {
    polygons <- sf::st_read(polygons, quiet = TRUE)
  }

  if (is.character(grid_data)) {
    if (grepl("\\.nc$", grid_data, ignore.case = TRUE)) {
      stop("NetCDF input not yet supported. Please provide a data frame.")
    } else {
      grid_data <- utils::read.csv(grid_data)
    }
  }

  grid_pts <- grid_data %>%
    dplyr::distinct(longitude, latitude)

  grid_sf <- sf::st_as_sf(grid_pts, coords = c("longitude", "latitude"), crs = 4326)

  p <- ggplot2::ggplot() +
    ggplot2::geom_sf(data = polygons, fill = polygon_fill, color = polygon_color, linewidth = 0.3) +
    ggplot2::geom_sf(data = grid_sf, color = grid_color, size = 1, alpha = 0.7)

  if (show_centroids) {
    old_s2 <- sf::sf_use_s2()
    sf::sf_use_s2(FALSE)
    centroids <- sf::st_centroid(polygons)
    sf::sf_use_s2(old_s2)
    p <- p + ggplot2::geom_sf(data = centroids, color = centroid_color, size = 0.8, shape = 4)
  }

  p <- p +
    ggplot2::labs(
      title = title,
      subtitle = sprintf("Grid points: %d | Polygons: %d", nrow(grid_pts), nrow(polygons))
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold"),
      panel.grid = ggplot2::element_line(color = "grey90")
    )

  return(p)
}

#' Compare multiple grids
#'
#' @param ... Named data frames with longitude and latitude columns
#' @param polygons Optional sf object to show polygon boundaries
#' @param colors Named vector of colors for each grid
#' @param shapes Named vector of point shapes for each grid
#' @param point_size Size of grid points
#' @param polygon_color Color for polygon boundaries
#' @param title Plot title
#' @return ggplot object
#' @export
compare_grids <- function(..., polygons = NULL, colors = NULL, shapes = NULL,
                          point_size = 1, polygon_color = "#2C3E50",
                          title = "Grid Comparison") {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required")
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required")
  }

  grids <- list(...)
  grid_names <- names(grids)

  if (is.null(grid_names) || any(grid_names == "")) {
    stop("All grids must be named (e.g., compare_grids(IMD = imd_data, ERA5 = era5_data))")
  }

  if (is.null(colors)) {
    default_colors <- c("#E74C3C", "#3498DB", "#27AE60", "#9B59B6", "#F39C12")
    colors <- setNames(default_colors[seq_along(grids)], grid_names)
  }

  if (is.null(shapes)) {
    default_shapes <- c(16, 16, 16, 16, 16)
    shapes <- setNames(default_shapes[seq_along(grids)], grid_names)
  }

  grid_pts_list <- lapply(grid_names, function(name) {
    df <- grids[[name]] %>%
      dplyr::distinct(longitude, latitude) %>%
      dplyr::mutate(grid = name)
    df
  })

  all_pts <- dplyr::bind_rows(grid_pts_list)
  all_pts$grid <- factor(all_pts$grid, levels = grid_names)

  p <- ggplot2::ggplot()

  if (!is.null(polygons)) {
    if (is.character(polygons)) {
      polygons <- sf::st_read(polygons, quiet = TRUE)
    }
    p <- p + ggplot2::geom_sf(data = polygons, fill = NA, color = polygon_color, linewidth = 0.2)
  }

  p <- p +
    ggplot2::geom_point(
      data = all_pts,
      ggplot2::aes(x = longitude, y = latitude, color = grid, shape = grid),
      size = point_size, alpha = 0.7
    ) +
    ggplot2::scale_color_manual(values = colors, name = "Grid") +
    ggplot2::scale_shape_manual(values = shapes, name = "Grid") +
    ggplot2::labs(title = title) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold"),
      legend.position = "bottom"
    )

  if (!is.null(polygons)) {
    bbox <- sf::st_bbox(polygons)
    p <- p + ggplot2::coord_sf(
      xlim = c(bbox["xmin"], bbox["xmax"]),
      ylim = c(bbox["ymin"], bbox["ymax"])
    )
  } else {
    p <- p + ggplot2::coord_fixed()
  }

  counts <- sapply(grid_names, function(n) nrow(grids[[n]] %>% dplyr::distinct(longitude, latitude)))
  subtitle <- paste(sapply(grid_names, function(n) sprintf("%s: %d pts", n, counts[n])), collapse = " | ")
  p <- p + ggplot2::labs(subtitle = subtitle)

  return(p)
}

#' Check grid coverage statistics for polygons
#'
#' @param grid_data Data frame with longitude and latitude columns
#' @param polygons sf object with polygon geometries
#' @param polygon_id_cols Column names to identify polygons
#' @return List with coverage statistics
#' @export
check_grid_coverage <- function(grid_data, polygons, polygon_id_cols = NULL) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required")
  }

  if (is.null(polygon_id_cols)) {
    polygon_id_cols <- setdiff(names(polygons), attr(polygons, "sf_column"))
  }

  old_s2 <- sf::sf_use_s2()
  sf::sf_use_s2(FALSE)

  on.exit(sf::sf_use_s2(old_s2), add = TRUE)

  grid_pts <- grid_data %>% dplyr::distinct(longitude, latitude)
  pts_sf <- sf::st_as_sf(grid_pts, coords = c("longitude", "latitude"), crs = 4326)

  containment <- sf::st_contains(polygons, pts_sf)
  n_points_per_polygon <- lengths(containment)

  points_per_polygon <- polygons %>%
    as.data.frame() %>%
    dplyr::select(dplyr::all_of(polygon_id_cols))
  points_per_polygon$n_points <- n_points_per_polygon

  n_with_points <- sum(n_points_per_polygon > 0)
  n_without_points <- nrow(polygons) - n_with_points

  list(
    total_polygons = nrow(polygons),
    total_grid_points = nrow(grid_pts),
    polygons_with_points = n_with_points,
    polygons_without_points = n_without_points,
    coverage_percent = round(100 * n_with_points / nrow(polygons), 1),
    points_per_polygon = points_per_polygon,
    summary = sprintf(
      "%d/%d polygons (%.1f%%) contain at least one grid point",
      n_with_points, nrow(polygons), 100 * n_with_points / nrow(polygons)
    )
  )
}
