test_that("list_hadex3_indices returns correct structure", {
  all_idx <- list_hadex3_indices()
  expect_s3_class(all_idx, "data.frame")
  expect_true(all(c("index", "category", "description", "unit", "annual", "monthly") %in% names(all_idx)))
  expect_true("TXx" %in% all_idx$index)
  expect_true("Rx1day" %in% all_idx$index)
})

test_that("list_hadex3_indices frequency filter works", {
  monthly <- list_hadex3_indices(frequency = "monthly")
  annual <- list_hadex3_indices(frequency = "annual")
  all_idx <- list_hadex3_indices(frequency = "all")

  expect_true(nrow(monthly) < nrow(all_idx))
  expect_true(nrow(annual) <= nrow(all_idx))
  expect_true(all(monthly$monthly))

  # Indices not available monthly should not appear
  expect_false("CSDI" %in% monthly$index)
  expect_false("GSL" %in% monthly$index)
  # But should appear in annual
  expect_true("CSDI" %in% annual$index)
})

test_that(".hadex3_url builds correct annual URL", {
  url <- varunayan:::.hadex3_url("TXx", "annual", "61-90")
  expect_match(url, "HadEX3_TXx_1901-2018_ADW_61-90_1.25x1.875deg.nc.gz")
  expect_match(url, "hadobs/hadex3/data")
})

test_that(".hadex3_url builds correct monthly URL", {
  url <- varunayan:::.hadex3_url("Rx1day", "monthly")
  expect_match(url, "HadEX3_Rx1day_MON.nc.gz")
})

test_that(".hadex3_url uses correct baseline", {
  url_6190 <- varunayan:::.hadex3_url("TX90p", "annual", "61-90")
  url_8110 <- varunayan:::.hadex3_url("TX90p", "annual", "81-10")
  expect_match(url_6190, "61-90")
  expect_match(url_8110, "81-10")
})

test_that(".validate_hadex3_inputs rejects invalid index", {
  expect_error(
    varunayan:::.validate_hadex3_inputs("INVALID", "annual", "61-90", 1981, 2010),
    "not available"
  )
})

test_that(".validate_hadex3_inputs rejects out-of-range years", {
  expect_error(
    varunayan:::.validate_hadex3_inputs("TXx", "annual", "61-90", 1800, 2010),
    "1901-2018"
  )
  expect_error(
    varunayan:::.validate_hadex3_inputs("TXx", "annual", "61-90", 1981, 2025),
    "1901-2018"
  )
})

test_that(".validate_hadex3_inputs rejects monthly-only index for monthly", {
  # CSDI is annual-only
  expect_error(
    varunayan:::.validate_hadex3_inputs("CSDI", "monthly", "61-90", 1981, 2010),
    "not available"
  )
})

test_that(".validate_hadex3_inputs rejects 81-10 baseline for unsupported index", {
  expect_error(
    varunayan:::.validate_hadex3_inputs("TXx", "annual", "81-10", 1981, 2010),
    "81-10"
  )
})

test_that(".parse_hadex3_years handles 'years since' units", {
  years <- varunayan:::.parse_hadex3_years(0:5, "years since 1901-01-01")
  expect_equal(years, 1901:1906)
})

test_that(".parse_hadex3_years handles 'days since' units", {
  # 0 days since 1901-01-01 = 1901, 365 days = 1902
  years <- varunayan:::.parse_hadex3_years(c(0, 365), "days since 1901-01-01")
  expect_equal(years[1], 1901L)
  expect_equal(years[2], 1902L)
})

test_that(".parse_hadex3_months handles 'months since' units", {
  ym <- varunayan:::.parse_hadex3_months(0:2, "months since 1901-01-15")
  expect_equal(ym$year, c(1901L, 1901L, 1901L))
  expect_equal(ym$month, c(1L, 2L, 3L))
})

test_that("hadex3_bbox validates bounding box", {
  expect_error(
    hadex3_bbox("TXx", 1981, 2010, north = -10, south = 10, east = 40, west = -10),
    "Invalid bounding box"
  )
})

test_that("hadex3_geojson errors on missing GeoJSON", {
  expect_error(
    hadex3_geojson("TXx", 1981, 2010, geojson_file = "/nonexistent/file.geojson"),
    "not found"
  )
})

test_that("HadEX3 aliases exist and are exported", {
  expect_true(existsMethod("HadEX3Bbox") || is.function(varunayan::HadEX3Bbox))
  expect_true(is.function(varunayan::HadEX3Geojson))
  expect_true(is.function(varunayan::ListHadEX3Indices))
})
