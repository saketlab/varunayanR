test_that("search_variable returns data.frame with correct columns", {
  results <- search_variable("temperature")

  expect_s3_class(results, "data.frame")
  expected_cols <- c("variable_name", "description", "units", "dataset_type", "category")
  expect_true(all(expected_cols %in% names(results)))
  expect_true(nrow(results) > 0)
})

test_that("search_variable filters by dataset_type", {
  single_results <- search_variable("temperature", dataset_type = "single")
  pressure_results <- search_variable("temperature", dataset_type = "pressure")
  all_results <- search_variable("temperature", dataset_type = "all")

  expect_true(all(single_results$dataset_type == "single"))
  expect_true(all(pressure_results$dataset_type == "pressure"))
  expect_true(nrow(all_results) >= max(nrow(single_results), nrow(pressure_results)))
})

test_that("search_variable validates dataset_type", {
  expect_error(
    search_variable("temperature", dataset_type = "invalid"),
    "dataset_type must be one of"
  )
})

test_that("search_variable exact_match works", {
  exact_results <- search_variable("2m_temperature", exact_match = TRUE)
  fuzzy_results <- search_variable("2m_temperature", exact_match = FALSE)

  # Exact match should only return exact variable name matches
  if (nrow(exact_results) > 0) {
    expect_true(all(exact_results$variable_name == "2m_temperature"))
  }

  # Fuzzy search might return more results
  expect_true(nrow(fuzzy_results) >= nrow(exact_results))
})

test_that("describe_variables returns descriptions for valid variables", {
  descriptions <- describe_variables(c("2m_temperature"))

  expect_s3_class(descriptions, "data.frame")
  expected_cols <- c("variable_name", "description", "units", "dataset_type", "category")
  expect_true(all(expected_cols %in% names(descriptions)))
  expect_equal(nrow(descriptions), 1)
  expect_equal(descriptions$variable_name[1], "2m_temperature")
  expect_false(descriptions$description[1] == "Variable not found")
})

test_that("describe_variables handles unknown variables", {
  descriptions <- describe_variables(c("unknown_variable"))

  expect_equal(descriptions$description[1], "Variable not found")
  expect_equal(descriptions$dataset_type[1], "unknown")
})

test_that("describe_variables validates dataset_type", {
  expect_error(
    describe_variables(c("2m_temperature"), dataset_type = "invalid"),
    "dataset_type must be one of"
  )
})

test_that("get_available_datasets returns expected values", {
  datasets <- get_available_datasets()
  expect_true(all(c("single", "pressure") %in% datasets))
  expect_type(datasets, "character")
})

test_that("list_available_variables returns character vector", {
  variables <- list_available_variables()
  expect_type(variables, "character")
  expect_true(length(variables) > 0)

  # Check that results are sorted
  expect_equal(variables, sort(variables))

  # Test dataset-specific listings
  single_vars <- list_available_variables("single")
  pressure_vars <- list_available_variables("pressure")

  expect_type(single_vars, "character")
  expect_type(pressure_vars, "character")
  expect_true(length(single_vars) > 0)
  expect_true(length(pressure_vars) > 0)
})

test_that("list_available_variables validates dataset_type", {
  expect_error(
    list_available_variables("invalid"),
    "dataset_type must be one of"
  )
})

test_that("get_available_pressure_levels returns expected format", {
  levels <- get_available_pressure_levels()
  expect_type(levels, "character")
  expect_true(length(levels) > 0)

  # Should include common pressure levels
  expect_true("1000" %in% levels) # Surface pressure
  expect_true("500" %in% levels) # Mid-troposphere
  expect_true("100" %in% levels) # Lower stratosphere

  # Check that all values are numeric when converted
  numeric_levels <- as.numeric(levels)
  expect_true(all(numeric_levels > 0))
  expect_false(any(is.na(numeric_levels)))
})

test_that("get_single_level_variables returns proper structure", {
  single_vars <- get_single_level_variables()

  expect_type(single_vars, "list")
  expect_true(length(single_vars) > 0)

  # Check structure of first category
  first_category <- single_vars[[1]]
  expect_type(first_category, "list")

  if (length(first_category) > 0) {
    first_var <- first_category[[1]]
    expect_true("description" %in% names(first_var))
    expect_true("units" %in% names(first_var))
  }
})

test_that("get_pressure_level_variables returns proper structure", {
  pressure_vars <- get_pressure_level_variables()

  expect_type(pressure_vars, "list")
  expect_true(length(pressure_vars) > 0)

  # Check structure of first category
  first_category <- pressure_vars[[1]]
  expect_type(first_category, "list")

  if (length(first_category) > 0) {
    first_var <- first_category[[1]]
    expect_true("description" %in% names(first_var))
    expect_true("units" %in% names(first_var))
  }
})
