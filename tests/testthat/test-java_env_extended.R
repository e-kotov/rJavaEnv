# Additional coverage tests for java_env.R

# Test java_env_set with project writes to .Rprofile
test_that("java_env_set project mode creates .Rprofile", {
  proj_dir <- withr::local_tempdir()

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    java_env_set_session = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  ._java_env_set_impl(
    where = "project",
    java_home = "/mock/java",
    project_path = proj_dir,
    quiet = TRUE
  )

  rprof <- file.path(proj_dir, ".Rprofile")
  expect_true(file.exists(rprof))
  content <- readLines(rprof)
  expect_true(any(grepl("rJavaEnv begin", content)))
  expect_true(any(grepl("/mock/java", content)))
})

# Test java_env_set with both mode
test_that("java_env_set both mode sets session and writes .Rprofile", {
  proj_dir <- withr::local_tempdir()

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  session_set <- FALSE
  local_mocked_bindings(
    java_env_set_session = function(...) {
      session_set <<- TRUE
      invisible(NULL)
    },
    .package = "rJavaEnv"
  )

  ._java_env_set_impl(
    where = "both",
    java_home = "/mock/java",
    project_path = proj_dir,
    quiet = TRUE
  )

  expect_true(session_set)
  expect_true(file.exists(file.path(proj_dir, ".Rprofile")))
})

# Test java_env_set outputs success message
test_that("java_env_set outputs success message when quiet = FALSE", {
  proj_dir <- withr::local_tempdir()

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    java_env_set_session = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Darwin"),
    .package = "base"
  )

  expect_message(
    ._java_env_set_impl(
      where = "project",
      java_home = "/mock/java",
      project_path = proj_dir,
      quiet = FALSE
    ),
    "JAVA_HOME and PATH set"
  )
})

# Test java_env_set Linux info message
test_that("java_env_set outputs Linux-specific info", {
  proj_dir <- withr::local_tempdir()

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    java_env_set_session = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Linux"),
    .package = "base"
  )

  expect_message(
    ._java_env_set_impl(
      where = "session",
      java_home = "/mock/java",
      project_path = proj_dir,
      quiet = FALSE
    ),
    "libjvm.so"
  )
})

# Test java_env_set_session sets JAVA_HOME and PATH
test_that("java_env_set_session sets environment variables", {
  java_home <- "/mock/java/home"

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

  withr::local_envvar(PATH = "/usr/bin", JAVA_HOME = "")

  java_env_set_session(java_home, quiet = TRUE)

  expect_equal(Sys.getenv("JAVA_HOME"), java_home)
  expect_true(grepl(file.path(java_home, "bin"), Sys.getenv("PATH")))
})

# Test java_env_set_session warns when libjvm not found on Linux
test_that("java_env_set_session warns when libjvm not found on Linux", {
  java_home <- "/mock/java/home"

  local_mocked_bindings(
    installed.packages = function(...) matrix(character(0), nrow = 0, ncol = 2),
    .package = "utils"
  )

  local_mocked_bindings(
    loadedNamespaces = function() character(0),
    .package = "base"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Linux"),
    .package = "base"
  )

  local_mocked_bindings(
    get_libjvm_path = function(...) NULL,
    .package = "rJavaEnv"
  )

  withr::local_envvar(PATH = "/usr/bin", JAVA_HOME = "")

  expect_warning(
    java_env_set_session(java_home, quiet = FALSE),
    "Could not find libjvm"
  )
})

# Test java_env_set_rprofile creates new file
test_that("java_env_set_rprofile creates new .Rprofile", {
  proj_dir <- withr::local_tempdir()
  rprof <- file.path(proj_dir, ".Rprofile")

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Darwin"),
    .package = "base"
  )

  java_env_set_rprofile("/mock/java", proj_dir)

  expect_true(file.exists(rprof))
  content <- readLines(rprof)
  expect_true(any(grepl("rJavaEnv begin", content)))
  expect_true(any(grepl("rJavaEnv end", content)))
})

# Test java_env_set_rprofile appends to existing file
test_that("java_env_set_rprofile appends to existing .Rprofile", {
  proj_dir <- withr::local_tempdir()
  rprof <- file.path(proj_dir, ".Rprofile")
  writeLines("# Existing user config", rprof)

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Darwin"),
    .package = "base"
  )

  java_env_set_rprofile("/new/java", proj_dir)

  content <- readLines(rprof)
  expect_true(any(grepl("Existing user config", content)))
  expect_true(any(grepl("rJavaEnv begin", content)))
  expect_true(any(grepl("/new/java", content)))
})

# Test java_env_set_rprofile adds dyn.load for Linux
test_that("java_env_set_rprofile adds dyn.load for Linux", {
  proj_dir <- withr::local_tempdir()
  rprof <- file.path(proj_dir, ".Rprofile")
  java_home <- "/mock/java"

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Linux"),
    .package = "base"
  )

  local_mocked_bindings(
    get_libjvm_path = function(...) "/mock/java/lib/server/libjvm.so",
    .package = "rJavaEnv"
  )

  java_env_set_rprofile(java_home, proj_dir)

  content <- readLines(rprof)
  expect_true(any(grepl("dyn.load", content)))
  expect_true(any(grepl("libjvm.so", content)))
})

# Test java_check_version_rjava when rJava not installed
test_that("java_check_version_rjava handles missing rJava", {
  local_mocked_bindings(
    find.package = function(pkg, quiet = FALSE) {
      if (pkg == "rJava") {
        character(0)
      } else {
        base::find.package(pkg, quiet = quiet)
      }
    },
    .package = "base"
  )

  result <- java_check_version_rjava(quiet = TRUE)

  # Returns FALSE (not NULL) when rJava is not installed
  expect_false(result)
})
