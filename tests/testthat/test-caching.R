test_that("java_check_version_cmd caching works", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  skip_if_not(nzchar(Sys.which("java")), "Java not available")

  v1 <- java_check_version_cmd(quiet = TRUE)
  expect_type(v1, "character")

  # Second call should return same cached result
  v2 <- java_check_version_cmd(quiet = TRUE)
  expect_identical(v1, v2)
})

test_that("java_find_system caching works", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  r1 <- java_find_system(quiet = TRUE)
  r2 <- java_find_system(quiet = TRUE)

  # Multiple calls return identical results
  expect_identical(r1, r2)
  expect_s3_class(r1, "data.frame")
})

test_that("quiet parameter doesn't affect cache", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  skip_if_not(nzchar(Sys.which("java")), "Java not available")

  v1 <- java_check_version_cmd(quiet = TRUE)
  v2 <- suppressMessages(java_check_version_cmd(quiet = FALSE))

  expect_identical(v1, v2)
})
