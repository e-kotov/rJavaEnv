# Tests for java_build_env_set() and related functions

test_that("java_build_env_set validates java_home argument", {
  # Test that empty JAVA_HOME triggers error
  withr::local_envvar(JAVA_HOME = "")

  expect_error(
    java_build_env_set(java_home = "", quiet = TRUE),
    "java_home"
  )
})

test_that("java_build_env_set writes to .Rprofile in project", {
  proj_dir <- withr::local_tempdir()
  local_mocked_bindings(rje_consent_check = function() TRUE, .package = "rJavaEnv")

  # Mock set_java_build_env_vars to avoid side effects when testing "both"
  local_mocked_bindings(
    set_java_build_env_vars = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  java_build_env_set(
    java_home = "/mock/java",
    where = "project",
    project_path = proj_dir,
    quiet = TRUE
  )

  rprof <- file.path(proj_dir, ".Rprofile")
  expect_true(file.exists(rprof))
  content <- readLines(rprof)
  expect_true(any(grepl("rJavaEnvBuild begin", content)))
  expect_true(any(grepl("/mock/java", content)))
})

test_that("java_build_env_set writes to .Rprofile with 'both' option", {
  proj_dir <- withr::local_tempdir()
  local_mocked_bindings(rje_consent_check = function() TRUE, .package = "rJavaEnv")

  # Mock set_java_build_env_vars to avoid side effects
  set_env_called <- FALSE
  local_mocked_bindings(
    set_java_build_env_vars = function(...) {
      set_env_called <<- TRUE
      invisible(NULL)
    },
    .package = "rJavaEnv"
  )

  java_build_env_set(
    java_home = "/mock/java",
    where = "both",
    project_path = proj_dir,
    quiet = TRUE
  )

  # Check both session and project were affected
  expect_true(set_env_called)
  rprof <- file.path(proj_dir, ".Rprofile")
  expect_true(file.exists(rprof))
})

test_that("java_build_env_unset removes entries from .Rprofile", {
  proj_dir <- withr::local_tempdir()
  local_mocked_bindings(rje_consent_check = function() TRUE, .package = "rJavaEnv")

  # First write the .Rprofile with build env entries
  rprof <- file.path(proj_dir, ".Rprofile")
  writeLines(c(
    "# Some existing content",
    "# rJavaEnvBuild begin: Manage Java Build Environment",
    "if (requireNamespace(\"rJavaEnv\", quietly = TRUE)) { rJavaEnv:::set_java_build_env_vars(java_home = '/mock/java', quiet = TRUE) } # rJavaEnvBuild",
    "# rJavaEnvBuild end: Manage Java Build Environment",
    "# More existing content"
  ), rprof)

  java_build_env_unset(project_path = proj_dir, quiet = TRUE)

  content <- readLines(rprof)
  expect_false(any(grepl("rJavaEnvBuild", content)))
  expect_true(any(grepl("Some existing content", content)))
  expect_true(any(grepl("More existing content", content)))
})

test_that("java_build_env_unset handles missing .Rprofile gracefully", {
  proj_dir <- withr::local_tempdir()
  local_mocked_bindings(rje_consent_check = function() TRUE, .package = "rJavaEnv")

  # No .Rprofile exists - should not error

  expect_silent(
    java_build_env_unset(project_path = proj_dir, quiet = TRUE)
  )
})

test_that("java_build_env_set session mode sets basic env vars", {
  skip_on_cran()

  proj_dir <- withr::local_tempdir()
  java_home <- withr::local_tempdir()

  # Create fake Java structure
  bin_dir <- file.path(java_home, "bin")
  dir.create(bin_dir, recursive = TRUE)
  file.create(file.path(bin_dir, "java"))
  file.create(file.path(bin_dir, "javac"))
  file.create(file.path(bin_dir, "jar"))

  # Clean up env vars after test
  withr::defer({
    Sys.unsetenv(c("JAVA", "JAVAC", "JAR", "JAVAH"))
  })

  # Mock dyn.load and list.files to avoid actual file system operations
  local_mocked_bindings(
    dyn.load = function(...) invisible(NULL),
    .package = "base"
  )

  # Mock set_java_build_env_vars to only set basic vars we can test
  local_mocked_bindings(
    java_env_set_session = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  # Use the actual set_java_build_env_vars but limit its scope
  # Just verify it doesn't error with a valid java_home structure
  expect_silent(
    java_build_env_set(java_home = java_home, where = "session", quiet = TRUE)
  )
})

test_that("java_build_env_set appends to existing .Rprofile", {
  proj_dir <- withr::local_tempdir()
  local_mocked_bindings(rje_consent_check = function() TRUE, .package = "rJavaEnv")

  # Create existing .Rprofile
  rprof <- file.path(proj_dir, ".Rprofile")
  writeLines("# Existing content\noptions(foo = TRUE)", rprof)

  # Mock set_java_build_env_vars
  local_mocked_bindings(
    set_java_build_env_vars = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  java_build_env_set(
    java_home = "/mock/java",
    where = "project",
    project_path = proj_dir,
    quiet = TRUE
  )

  content <- readLines(rprof)
  # Original content preserved
  expect_true(any(grepl("Existing content", content)))
  expect_true(any(grepl("options\\(foo = TRUE\\)", content)))
  # New content added
  expect_true(any(grepl("rJavaEnvBuild begin", content)))
})

test_that("java_build_env_set replaces old entries when called again", {
  proj_dir <- withr::local_tempdir()
  local_mocked_bindings(rje_consent_check = function() TRUE, .package = "rJavaEnv")

  # Mock set_java_build_env_vars
  local_mocked_bindings(
    set_java_build_env_vars = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  # First call
  java_build_env_set(
    java_home = "/old/java",
    where = "project",
    project_path = proj_dir,
    quiet = TRUE
  )

  # Second call with different path
  java_build_env_set(
    java_home = "/new/java",
    where = "project",
    project_path = proj_dir,
    quiet = TRUE
  )

  content <- readLines(file.path(proj_dir, ".Rprofile"))
  # Old path should be gone, new path present
  expect_false(any(grepl("/old/java", content)))
  expect_true(any(grepl("/new/java", content)))
  # Should only have one begin/end block
  expect_equal(sum(grepl("rJavaEnvBuild begin", content)), 1)
})
