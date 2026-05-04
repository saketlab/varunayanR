# CRAN Submission Checklist

## 1. Standard R CMD check

``` r
devtools::check()
```

## 2. CRAN-specific checks (stricter)

``` r
devtools::check(cran = TRUE)
```

## 3. All-in-one thorough local check

``` r
devtools::check(
  cran = TRUE,
  remote = TRUE,
  manual = TRUE
)
```

## 4. Multi-platform checks

``` r
# R-hub (multiple platforms)
devtools::check_rhub()

# Windows (R-devel and R-release)
devtools::check_win_devel()
devtools::check_win_release()
```

## 5. Additional checks

``` r
# Spelling in documentation
devtools::spell_check()

# URLs in documentation
urlchecker::url_check()

# Package dependencies
devtools::check_dep_versions()

# Run examples
devtools::run_examples()

# Build and check vignettes
devtools::build_vignettes()
```

## 6. Reverse dependency check (for updates)

``` r
devtools::revdep_check()
```

## Goal

**0 errors, 0 warnings, 0 notes** for CRAN submission.

Notes are sometimes acceptable if explained in `cran-comments.md`.
