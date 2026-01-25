test_that("validate_era5_variables works correctly", {
  # Test single-level variables
  valid_single <- c("2m_temperature", "total_precipitation")
  result_single <- validate_era5_variables(valid_single, "single")
  expect_true(all(result_single))
  expect_equal(length(result_single), 2)

  # Test pressure-level variables
  valid_pressure <- c("temperature", "u_component_of_wind")
  result_pressure <- validate_era5_variables(valid_pressure, "pressure")
  expect_true(all(result_pressure))
  expect_equal(length(result_pressure), 2)

  # Test invalid variables
  invalid_vars <- c("invalid_variable", "another_invalid")
  result_invalid <- validate_era5_variables(invalid_vars, "single")
  expect_false(any(result_invalid))
  expect_equal(length(result_invalid), 2)

  # Test mixed valid/invalid
  mixed_vars <- c("2m_temperature", "invalid_variable")
  result_mixed <- validate_era5_variables(mixed_vars, "single")
  expect_true(result_mixed[1])
  expect_false(result_mixed[2])
})

test_that("validate_era5_variables validates dataset_type", {
  expect_error(
    validate_era5_variables(c("temperature"), "invalid"),
    "Invalid dataset_type"
  )
})

test_that("get_single_level_variable_names returns character vector", {
  vars <- get_single_level_variable_names()

  expect_type(vars, "character")
  expect_true(length(vars) > 0)

  # Check for some expected variables
  expect_true("2m_temperature" %in% vars)
  expect_true("total_precipitation" %in% vars)
  expect_true("10m_u_component_of_wind" %in% vars)
})

test_that("get_pressure_level_variable_names returns character vector", {
  vars <- get_pressure_level_variable_names()

  expect_type(vars, "character")
  expect_true(length(vars) > 0)

  # Check for some expected variables
  expect_true("temperature" %in% vars)
  expect_true("u_component_of_wind" %in% vars)
  expect_true("geopotential" %in% vars)
  expect_true("relative_humidity" %in% vars)
})

test_that("variable name lists don't overlap inappropriately", {
  single_vars <- get_single_level_variable_names()
  pressure_vars <- get_pressure_level_variable_names()

  # There might be some overlap (e.g., both have temperature variables but with different names)
  # But they should be distinct lists
  expect_true(length(single_vars) > 0)
  expect_true(length(pressure_vars) > 0)

  # Check that specific variables are in correct lists
  expect_true("2m_temperature" %in% single_vars)
  expect_false("2m_temperature" %in% pressure_vars)

  expect_true("temperature" %in% pressure_vars)
  expect_false("temperature" %in% single_vars)
})
