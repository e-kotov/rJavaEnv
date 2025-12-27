test_that("java_valid_versions returns a character vector with required versions", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  # Clear any cached values
  options(
    rJavaEnv.valid_versions_cache = NULL,
    rJavaEnv.valid_versions_timestamp = NULL
  )

  # Retrieve Java versions
  versions <- java_valid_versions()

  # Verify the result is a character vector and contains "8" and "11"
  expect_type(versions, "character")
  expect_true("8" %in% versions)
  expect_true("11" %in% versions)
  expect_true("24" %in% versions)
})

test_that("force parameter bypasses the cache", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  # Set a fake cache in the options
  fake_cache <- c("8", "11")
  options(
    rJavaEnv.valid_versions_cache = fake_cache,
    rJavaEnv.valid_versions_timestamp = Sys.time()
  )

  # Force a refresh by setting force = TRUE.
  versions_force <- java_valid_versions(force = TRUE)

  # The returned value should not equal the fake cache.
  expect_false(identical(versions_force, fake_cache))
})

test_that("fallback is used when the API call fails", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  # Clear the cache to force an API call.
  options(
    rJavaEnv.valid_versions_cache = NULL,
    rJavaEnv.valid_versions_timestamp = NULL
  )

  local_mocked_bindings(
    read_json = function(...) stop("Simulated API failure"),
    .package = "jsonlite"
  )

  fallback <- getOption("rJavaEnv.fallback_valid_versions_current_platform")
  versions <- java_valid_versions(force = TRUE)

  ## When the API call fails, the fallback list should be returned.
  expect_equal(versions, fallback)
})
