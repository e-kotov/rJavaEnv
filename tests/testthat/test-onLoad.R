test_that(".onLoad sets default options", {
  # Save original options to restore later
  op <- options()
  on.exit(options(op))

  # Clear specific options to test if they get set
  options(
    rJavaEnv.fallback_valid_versions_current_platform = NULL,
    rJavaEnv.valid_versions_cache = NULL
  )

  # Manually trigger .onLoad
  rJavaEnv:::.onLoad("rJavaEnv", "rJavaEnv")

  # Check if the platform fallback was set
  fallback <- getOption("rJavaEnv.fallback_valid_versions_current_platform")
  expect_false(is.null(fallback))
  expect_true(length(fallback) > 0)

  # Check if valid_versions_cache was initialized (it's set to NULL, which removes it)
  # We just verify that .onLoad ran without error and set the other options correctly
  expect_true(is.null(getOption("rJavaEnv.valid_versions_cache")))
})
