test_that("is_valid_geojson works correctly", {
  # Valid GeoJSON examples
  valid_feature <- list(
    type = "Feature",
    geometry = list(
      type = "Point",
      coordinates = c(-74.0060, 40.7128)
    ),
    properties = list()
  )
  expect_true(is_valid_geojson(valid_feature))

  valid_collection <- list(
    type = "FeatureCollection",
    features = list(valid_feature)
  )
  expect_true(is_valid_geojson(valid_collection))

  # Invalid examples
  expect_false(is_valid_geojson(list(invalid = "data")))
  expect_false(is_valid_geojson("not a list"))
  expect_false(is_valid_geojson(list(type = "InvalidType")))
})

test_that("create_geojson_from_bbox creates valid GeoJSON", {
  geojson <- create_geojson_from_bbox(40, 35, -70, -75)

  expect_true(is_valid_geojson(geojson))
  expect_equal(geojson$type, "Feature")
  expect_equal(geojson$geometry$type, "Polygon")
  expect_length(geojson$geometry$coordinates[[1]], 5) # 5 points for closed polygon

  # Check coordinates are correct
  coords <- geojson$geometry$coordinates[[1]]
  expect_equal(coords[[1]], c(-75, 35)) # SW corner
  expect_equal(coords[[3]], c(-70, 40)) # NE corner
})

test_that("validate_coordinates works correctly", {
  expect_true(validate_coordinates(40.7128, -74.0060)) # NYC
  expect_true(validate_coordinates(0, 0)) # Equator/Prime Meridian
  expect_true(validate_coordinates(-90, -180)) # Extreme valid values
  expect_true(validate_coordinates(90, 180)) # Extreme valid values

  expect_false(validate_coordinates(91, 0)) # Invalid latitude
  expect_false(validate_coordinates(-91, 0)) # Invalid latitude
  expect_false(validate_coordinates(0, 181)) # Invalid longitude
  expect_false(validate_coordinates(0, -181)) # Invalid longitude
  expect_false(validate_coordinates(NA, 0)) # NA values
  expect_false(validate_coordinates(0, NA)) # NA values
})

test_that("validate_bbox works correctly", {
  expect_true(validate_bbox(40, 35, -70, -75)) # Valid bbox
  expect_false(validate_bbox(35, 40, -70, -75)) # North < South
  expect_false(validate_bbox(40, 35, -75, -70)) # East < West
  expect_false(validate_bbox(91, 35, -70, -75)) # Invalid north
  expect_false(validate_bbox(40, -91, -70, -75)) # Invalid south
})

test_that("format_pressure_levels works correctly", {
  expect_null(format_pressure_levels(NULL))

  numeric_levels <- c(1000, 850, 500)
  char_levels <- format_pressure_levels(numeric_levels)
  expect_type(char_levels, "character")
  expect_equal(char_levels, c("1000", "850", "500"))

  # Already character
  expect_equal(format_pressure_levels(c("1000", "850")), c("1000", "850"))
})

test_that("format_date_range works correctly", {
  start_date <- as.Date("2023-01-01")
  end_date <- as.Date("2023-01-03")

  date_range <- format_date_range(start_date, end_date)
  expected <- c("2023-01-01", "2023-01-02", "2023-01-03")

  expect_equal(date_range, expected)
  expect_type(date_range, "character")
})

test_that("get_time_values works correctly", {
  hourly_times <- get_time_values("hourly")
  expect_length(hourly_times, 24)
  expect_equal(hourly_times[1], "00:00")
  expect_equal(hourly_times[24], "23:00")

  daily_times <- get_time_values("daily")
  expect_equal(daily_times, "12:00")

  monthly_times <- get_time_values("monthly")
  expect_equal(monthly_times, "12:00")
})

test_that("create_temp_geojson_file creates file", {
  geojson_data <- list(
    type = "Feature",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    properties = list()
  )

  temp_file <- create_temp_geojson_file(geojson_data, "test")

  expect_true(file.exists(temp_file))
  expect_true(grepl("\\.geojson$", temp_file))
  expect_true(grepl("varunayan_test_", basename(temp_file)))

  # Check content
  read_data <- jsonlite::fromJSON(temp_file)
  expect_equal(read_data$type, "Feature")

  # Clean up
  unlink(temp_file)
})
