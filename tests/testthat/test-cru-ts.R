test_that("list_cru_ts_variables returns correct structure", {
  vars <- list_cru_ts_variables()
  expect_s3_class(vars, "data.frame")
  expect_true(all(c("variable", "name", "description", "unit", "era5_equivalent") %in% names(vars)))
  expect_equal(nrow(vars), 10L)
  expect_true("tmp" %in% vars$variable)
  expect_true("pre" %in% vars$variable)
  expect_true("tmx" %in% vars$variable)
  expect_true("tmn" %in% vars$variable)
})

test_that("list_cru_ts_variables has common names column", {
  vars <- list_cru_ts_variables()
  tmp_row <- vars[vars$variable == "tmp", ]
  expect_equal(tmp_row$name, "mean_temperature")
  expect_equal(tmp_row$era5_equivalent, "2m_temperature")
})

test_that(".cru_ts_url builds correct URL", {
  url <- varunayan:::.cru_ts_url("tmp", 1981L, 1990L)
  expect_match(url, "cru_ts4\\.07\\.1981\\.1990\\.tmp\\.dat\\.nc\\.gz")
  expect_match(url, "crudata\\.uea\\.ac\\.uk")
  expect_match(url, "/tmp/")
})

test_that(".cru_ts_needed_decades returns correct files", {
  decades <- varunayan:::.cru_ts_needed_decades(1981L, 2000L)
  expect_equal(length(decades), 2L)
  expect_equal(decades[[1]], c(1981L, 1990L))
  expect_equal(decades[[2]], c(1991L, 2000L))
})

test_that(".cru_ts_needed_decades handles partial overlap", {
  decades <- varunayan:::.cru_ts_needed_decades(1985L, 1995L)
  expect_equal(length(decades), 2L)
  expect_equal(decades[[1]][1], 1981L)
  expect_equal(decades[[2]][2], 2000L)
})

test_that(".cru_ts_needed_decades handles single decade", {
  decades <- varunayan:::.cru_ts_needed_decades(1985L, 1989L)
  expect_equal(length(decades), 1L)
  expect_equal(decades[[1]], c(1981L, 1990L))
})

test_that(".cru_ts_needed_decades handles final partial decade (2021-2022)", {
  decades <- varunayan:::.cru_ts_needed_decades(2020L, 2022L)
  expect_equal(length(decades), 2L)
  end_years <- sapply(decades, function(d) d[2])
  expect_true(2022L %in% end_years)
})

test_that(".validate_cru_ts_inputs rejects invalid variable", {
  expect_error(
    varunayan:::.validate_cru_ts_inputs("xyz", 1981L, 2010L),
    "not a valid CRU TS variable"
  )
})

test_that(".validate_cru_ts_inputs rejects out-of-range years", {
  expect_error(
    varunayan:::.validate_cru_ts_inputs("tmp", 1800L, 2010L),
    "1901-2022"
  )
  expect_error(
    varunayan:::.validate_cru_ts_inputs("tmp", 1981L, 2025L),
    "1901-2022"
  )
  expect_error(
    varunayan:::.validate_cru_ts_inputs("tmp", 2010L, 2005L),
    "start_year must be"
  )
})

test_that("cru_ts_bbox validates bounding box", {
  expect_error(
    cru_ts_bbox("tmp", 1981L, 2010L, north = -10, south = 10, east = 40, west = -10),
    "Invalid bounding box"
  )
})

test_that("cru_ts_geojson errors on missing file", {
  expect_error(
    cru_ts_geojson("tmp", 1981L, 2010L, geojson_file = "/nonexistent.geojson"),
    "not found"
  )
})

test_that(".parse_cru_ts_time handles days since", {
  dates <- varunayan:::.parse_cru_ts_time(c(0, 31, 59), "days since 1901-01-01")
  expect_s3_class(dates, "Date")
  expect_equal(format(dates[1], "%Y-%m-%d"), "1901-01-01")
  expect_equal(format(dates[2], "%Y-%m-%d"), "1901-02-01")
})

test_that("CRU TS aliases are functions", {
  expect_true(is.function(varunayan::CRUTSBbox))
  expect_true(is.function(varunayan::CRUTSGeojson))
  expect_true(is.function(varunayan::ListCRUTSVariables))
})

test_that("list_cru_ts_variables has hadex3_equivalent column", {
  vars <- list_cru_ts_variables()
  expect_true("hadex3_equivalent" %in% names(vars))
  # dtr should map to DTR
  dtr_row <- vars[vars$variable == "dtr", ]
  expect_equal(dtr_row$hadex3_equivalent, "DTR")
  # frs should map to FD
  frs_row <- vars[vars$variable == "frs", ]
  expect_equal(frs_row$hadex3_equivalent, "FD")
})
