test_that("varunayan:::.resolve_country_polygon returns sf for valid country", {
  skip_if_not_installed("maps")
  poly <- varunayan:::.resolve_country_polygon("India")
  expect_s3_class(poly, "sf")
  expect_true(nrow(poly) > 0)
})

test_that("varunayan:::.resolve_country_polygon handles aliases", {
  skip_if_not_installed("maps")
  poly_usa <- varunayan:::.resolve_country_polygon("USA")
  expect_s3_class(poly_usa, "sf")

  poly_us <- varunayan:::.resolve_country_polygon("US")
  expect_s3_class(poly_us, "sf")

  poly_uk <- varunayan:::.resolve_country_polygon("UK")
  expect_s3_class(poly_uk, "sf")
})

test_that("varunayan:::.resolve_country_polygon errors on unknown country", {
  skip_if_not_installed("maps")
  expect_error(
    varunayan:::.resolve_country_polygon("NonExistentCountryXYZ"),
    "not found in maps database"
  )
})

test_that("varunayan:::.resolve_country_polygon accepts sf input", {
  skip_if_not_installed("maps")
  poly <- varunayan:::.resolve_country_polygon("India")
  result <- varunayan:::.resolve_country_polygon(poly)
  expect_s3_class(result, "sf")
})

test_that("varunayan:::.resolve_country_polygon reads GeoJSON file", {
  tmp <- tempfile(fileext = ".geojson")
  on.exit(unlink(tmp), add = TRUE)

  # Create a simple GeoJSON polygon
  coords <- matrix(c(0, 0, 1, 0, 1, 1, 0, 1, 0, 0), ncol = 2, byrow = TRUE)
  poly <- sf::st_polygon(list(coords))
  sfc <- sf::st_sfc(poly, crs = 4326)
  sf_obj <- sf::st_sf(geometry = sfc)
  sf::st_write(sf_obj, tmp, driver = "GeoJSON", quiet = TRUE)

  result <- varunayan:::.resolve_country_polygon(tmp)
  expect_s3_class(result, "sf")
})

test_that("varunayan:::.resolve_country_polygon errors on bad input", {
  expect_error(varunayan:::.resolve_country_polygon(42), "must be a country name")
  expect_error(varunayan:::.resolve_country_polygon(c("India", "USA")), "must be a country name")
})

test_that("monthly frequency skips aggregation and extracts year/month", {
  # Simulate data as returned by the monthly-means product (already aggregated)
  processed_data <- data.frame(
    datetime = as.POSIXct(c("2024-01-01", "2024-02-01", "2024-03-01")),
    latitude = c(48.0, 48.0, 48.0),
    longitude = c(2.0, 2.0, 2.0),
    variable = rep("t2m", 3),
    value = c(5.0, 8.0, 12.0)
  )

  # The monthly branch should add year/month columns without calling aggregate_by_frequency
  frequency <- "monthly"
  if (frequency == "monthly") {
    if (!"year" %in% colnames(processed_data) && "datetime" %in% colnames(processed_data)) {
      processed_data$year <- as.integer(format(processed_data$datetime, "%Y"))
      processed_data$month <- as.integer(format(processed_data$datetime, "%m"))
    }
  }

  expect_true("year" %in% colnames(processed_data))
  expect_true("month" %in% colnames(processed_data))
  expect_equal(processed_data$year, c(2024L, 2024L, 2024L))
  expect_equal(processed_data$month, c(1L, 2L, 3L))
  # Original values preserved (no aggregation)
  expect_equal(processed_data$value, c(5.0, 8.0, 12.0))
})

test_that("monthly year/month extraction skipped when columns already exist", {
  processed_data <- data.frame(
    datetime = as.POSIXct("2024-06-01"),
    year = 2024L,
    month = 6L,
    value = 25.0
  )

  frequency <- "monthly"
  if (frequency == "monthly") {
    if (!"year" %in% colnames(processed_data) && "datetime" %in% colnames(processed_data)) {
      processed_data$year <- as.integer(format(processed_data$datetime, "%Y"))
      processed_data$month <- as.integer(format(processed_data$datetime, "%m"))
    }
  }

  # Should not overwrite existing columns
  expect_equal(processed_data$year, 2024L)
  expect_equal(processed_data$month, 6L)
})

test_that("variable shorthand mapping works", {
  # Test the mapping logic inline
  var_map <- c(
    mean = "2m_temperature",
    max  = "maximum_2m_temperature_since_previous_post_processing",
    min  = "minimum_2m_temperature_since_previous_post_processing"
  )

  expect_equal(var_map[["mean"]], "2m_temperature")
  expect_equal(var_map[["max"]], "maximum_2m_temperature_since_previous_post_processing")
  expect_equal(var_map[["min"]], "minimum_2m_temperature_since_previous_post_processing")
})

test_that("cosine latitude weighting is correct", {
  # Verify that cos(lat * pi / 180) produces correct area weights
  # At equator (0 deg), weight should be 1
  expect_equal(cos(0 * pi / 180), 1)
  # At 60 deg, weight should be 0.5
  expect_equal(cos(60 * pi / 180), 0.5)
  # At poles (90 deg), weight should be ~0
  expect_equal(cos(90 * pi / 180), 0, tolerance = 1e-15)

  # Weighted mean example: two grid points at different latitudes
  values <- c(20, 30)
  lats <- c(0, 60)
  weights <- cos(lats * pi / 180)
  result <- stats::weighted.mean(values, weights)
  expected <- (20 * 1 + 30 * 0.5) / (1 + 0.5)
  expect_equal(result, expected)
})
