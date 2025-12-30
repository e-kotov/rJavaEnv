# Unit tests for java_env.R functions
# Tests java_env_set and java_env_unset with mocked system calls

test_that("java_env_set (session) sets JAVA_HOME in the environment", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  # Mock rje_consent_check to avoid interactive prompts
  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  # Mock installed.packages to avoid rJava check
  local_mocked_bindings(
    installed.packages = function(...) matrix(character(0), nrow = 0, ncol = 2),
    .package = "utils"
  )

  # Mock loadedNamespaces to say rJava is not loaded
  local_mocked_bindings(
    loadedNamespaces = function() character(0),
    .package = "base"
  )

  # Mock Sys.info to return non-Linux system
  local_mocked_bindings(
    Sys.info = function() c(sysname = "Darwin"),
    .package = "base"
  )

  java_home_mock <- "/mock/java/home"

  # Use withr to temporarily capture original PATH
  withr::with_envvar(c("PATH" = "/usr/bin:/bin"), {
    java_env_set(where = "session", java_home = java_home_mock, quiet = TRUE)

    # Check that JAVA_HOME was set
    expect_equal(Sys.getenv("JAVA_HOME"), java_home_mock)
    # Check that PATH was modified to include java bin dir
    expect_true(grepl("/mock/java/home/bin", Sys.getenv("PATH")))
  })
})

test_that("java_env_set (project) writes to .Rprofile", {
  proj_dir <- withr::local_tempdir()

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    installed.packages = function(...) matrix(character(0), nrow = 0, ncol = 2),
    .package = "utils"
  )

  local_mocked_bindings(
    loadedNamespaces = function() character(0),
    .package = "base"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Darwin"),
    .package = "base"
  )

  java_env_set(
    where = "project",
    java_home = "/mock/java",
    project_path = proj_dir,
    quiet = TRUE
  )

  rprof <- file.path(proj_dir, ".Rprofile")
  expect_true(file.exists(rprof))

  content <- readLines(rprof)
  # Check that .Rprofile contains the rJavaEnv markers
  expect_true(any(grepl("# rJavaEnv begin", content)))
  expect_true(any(grepl("# rJavaEnv end", content)))
  # Check that it sets JAVA_HOME
  expect_true(any(grepl("Sys.setenv\\(JAVA_HOME", content)))
})

test_that("java_env_set (both) sets session and project", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  proj_dir <- withr::local_tempdir()

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    installed.packages = function(...) matrix(character(0), nrow = 0, ncol = 2),
    .package = "utils"
  )

  local_mocked_bindings(
    loadedNamespaces = function() character(0),
    .package = "base"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Darwin"),
    .package = "base"
  )

  java_home_mock <- "/mock/java"
  withr::with_envvar(c("PATH" = "/usr/bin"), {
    java_env_set(
      where = "both",
      java_home = java_home_mock,
      project_path = proj_dir,
      quiet = TRUE
    )

    # Check .Rprofile was created
    rprof <- file.path(proj_dir, ".Rprofile")
    expect_true(file.exists(rprof))

    # Check that session env was set
    expect_equal(Sys.getenv("JAVA_HOME"), java_home_mock)
  })
})

test_that("java_env_unset removes settings from .Rprofile", {
  proj_dir <- withr::local_tempdir()
  rprof <- file.path(proj_dir, ".Rprofile")

  # Create a .Rprofile with rJavaEnv markers
  writeLines(
    c(
      "# Some other config",
      "# rJavaEnv begin: Manage JAVA_HOME",
      "Sys.setenv(JAVA_HOME = '/path/to/java')",
      "# rJavaEnv end: Manage JAVA_HOME",
      "# More config"
    ),
    rprof
  )

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  java_env_unset(project_path = proj_dir, quiet = TRUE)

  content <- readLines(rprof)
  # rJavaEnv lines should be removed
  expect_false(any(grepl("# rJavaEnv", content)))
  # Other content should remain
  expect_true(any(grepl("Some other config", content)))
  expect_true(any(grepl("More config", content)))
})

test_that("java_env_unset handles missing .Rprofile gracefully", {
  proj_dir <- withr::local_tempdir()

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  # Should not error when .Rprofile doesn't exist
  expect_silent(
    java_env_unset(project_path = proj_dir, quiet = TRUE)
  )
})

test_that("java_env_set validates input", {
  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  # Should error on invalid 'where' argument
  expect_error(
    java_env_set(where = "invalid", java_home = "/mock/java"),
    "should be one of"
  )

  # Should error on non-string java_home
  expect_error(
    java_env_set(where = "session", java_home = 123),
    "Assertion on 'java_home' failed"
  )
})

test_that("java_check_version_rjava handles missing rJava package", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  local_mocked_bindings(
    installed.packages = function() {
      matrix(
        character(0),
        nrow = 0,
        ncol = 2,
        dimnames = list(NULL, c("Package", "Version"))
      )
    },
    .package = "utils"
  )
  local_mocked_bindings(
    find.package = function(...) character(0),
    .package = "base"
  )

  expect_message(
    java_check_version_rjava(java_home = "/some/path"),
    "rJava package is not installed"
  )
})
