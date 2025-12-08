# Tests for java_quick_install() and use_java()

test_that("java_quick_install executes flow correctly", {
  # Setup temp directories
  local_cache <- withr::local_tempdir()
  local_proj <- withr::local_tempdir()

  # Mock dependencies to prevent actual download/install
  local_mocked_bindings(
    java_download = function(...) file.path("mock", "distrib.tar.gz"),
    java_install = function(...) file.path("mock", "java_home"),
    rje_consent_check = function(...) TRUE,
    .package = "rJavaEnv"
  )

  # Test 1: Standard Execution
  expect_invisible(
    result <- java_quick_install(
      version = 17,
      project_path = local_proj,
      quiet = TRUE
    )
  )
  expect_equal(result, file.path("mock", "java_home"))

  # Test 2: Temp Directory execution
  # We can't easily check internal variables, but we ensure it runs without error
  # and returns the mocked path, implying logic held up.

  expect_invisible(
    res_temp <- java_quick_install(version = 17, temp_dir = TRUE, quiet = TRUE)
  )
  expect_equal(res_temp, file.path("mock", "java_home"))
})

test_that("use_java executes flow correctly", {
  # Mock dependencies
  local_mocked_bindings(
    java_download = function(...) "mock_distrib_path",
    java_unpack = function(...) "mock_install_path",
    # Capture the arguments passed to java_env_set to verify logic
    java_env_set = function(where, java_home, quiet) {
      if (where != "session") stop("Wrong 'where' argument")
      if (java_home != "mock_install_path") stop("Wrong 'java_home' argument")
      invisible(NULL)
    },
    java_valid_versions = function(...) c("8", "11", "17", "21"),
    .package = "rJavaEnv"
  )

  # Should run silently and pass verification inside the mock
  expect_silent(use_java(version = 17, quiet = TRUE))

  # Test message output when not quiet
  expect_message(use_java(version = 17, quiet = FALSE), "Java version 17 was set")
})
