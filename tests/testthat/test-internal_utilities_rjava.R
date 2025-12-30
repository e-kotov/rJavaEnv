# tests/testthat/test-internal_utilities_rjava.R

test_that("java_check_current_rjava_version returns NULL when rJava not loaded", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  # Mock loadedNamespaces to exclude rJava
  local_mocked_bindings(
    loadedNamespaces = function() c("base", "utils"),
    .package = "base"
  )

  result <- rJavaEnv:::java_check_current_rjava_version()
  expect_null(result)
})

test_that("java_check_current_rjava_version parses version correctly", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  # Mock rJava as loaded
  local_mocked_bindings(
    loadedNamespaces = function() c("rJava", "base"),
    .package = "base"
  )

  # Mock rJava functions to return known version
  local_mocked_bindings(
    `.jinit` = function(...) 0,
    `.jcall` = function(...) "17.0.2",
    .package = "rJava"
  )

  result <- rJavaEnv:::java_check_current_rjava_version()
  expect_equal(result, "17")
})

test_that("java_check_current_rjava_version handles 1.8 style versions", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  local_mocked_bindings(
    loadedNamespaces = function() c("rJava", "base"),
    .package = "base"
  )

  local_mocked_bindings(
    `.jinit` = function(...) 0,
    `.jcall` = function(...) "1.8.0_292",
    .package = "rJava"
  )

  result <- rJavaEnv:::java_check_current_rjava_version()
  expect_equal(result, "8")
})

test_that("java_check_current_rjava_version returns NULL on rJava error", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  local_mocked_bindings(
    loadedNamespaces = function() c("rJava", "base"),
    .package = "base"
  )

  local_mocked_bindings(
    `.jinit` = function(...) stop("JVM init failed"),
    .package = "rJava"
  )

  result <- rJavaEnv:::java_check_current_rjava_version()
  expect_null(result)
})

test_that("java_version_check_rscript sets JAVA_HOME correctly", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  skip_on_os("windows") # Different behavior

  local_tempdir <- withr::local_tempdir()
  java_home <- file.path(local_tempdir, "fake_java")
  bin_dir <- file.path(java_home, "bin")
  dir.create(bin_dir, recursive = TRUE)

  # Mock rJava initialization
  local_mocked_bindings(
    `.jinit` = function(...) 0,
    `.jcall` = function(...) "21.0.1",
    .package = "rJava"
  )

  # Mock get_libjvm_path to return NULL (no libjvm needed)
  local_mocked_bindings(
    get_libjvm_path = function(...) NULL,
    .package = "rJavaEnv"
  )

  result <- rJavaEnv:::java_version_check_rscript(java_home)

  expect_true(grepl("21", result))
})

test_that("java_version_check_rscript handles errors gracefully", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  local_mocked_bindings(
    `.jinit` = function(...) stop("JVM failed to start"),
    .package = "rJava"
  )

  result <- rJavaEnv:::java_version_check_rscript("/nonexistent/path")

  expect_true(grepl("Error", result))
})
