# Unit tests for java_build_env.R functions
# Tests java_build_env_unset and build environment setup

test_that("java_build_env_unset removes build config from .Rprofile", {
  proj_dir <- withr::local_tempdir()
  rprof <- file.path(proj_dir, ".Rprofile")

  # Create a .Rprofile with build environment markers
  writeLines(
    c(
      "# Other config",
      "library(utils)",
      "# rJavaEnvBuild begin: Manage Java Build Environment",
      "if (requireNamespace(\"rJavaEnv\", quietly = TRUE)) {",
      "  rJavaEnv:::set_java_build_env_vars(java_home = '/path/to/java')",
      "}",
      "# rJavaEnvBuild end: Manage Java Build Environment",
      "# More user config"
    ),
    rprof
  )

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  java_build_env_unset(project_path = proj_dir, quiet = TRUE)

  content <- readLines(rprof)
  # rJavaEnvBuild lines should be removed
  expect_false(any(grepl("# rJavaEnvBuild", content)))
  # Other content should remain
  expect_true(any(grepl("library\\(utils\\)", content)))
  expect_true(any(grepl("More user config", content)))
})

test_that("java_build_env_unset handles missing .Rprofile gracefully", {
  proj_dir <- withr::local_tempdir()

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  # Should not error when .Rprofile doesn't exist
  expect_silent(
    java_build_env_unset(project_path = proj_dir, quiet = TRUE)
  )
})

test_that("java_build_env_unset informs when .Rprofile not found", {
  proj_dir <- withr::local_tempdir()

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  # Should inform user when quiet = FALSE
  expect_message(
    java_build_env_unset(project_path = proj_dir, quiet = FALSE),
    "No .Rprofile found"
  )
})

test_that("java_build_env_unset uses current working directory by default", {
  original_wd <- getwd()
  on.exit(setwd(original_wd), add = TRUE)

  proj_dir <- withr::local_tempdir()
  setwd(proj_dir)

  rprof <- file.path(proj_dir, ".Rprofile")
  writeLines(
    c(
      "# rJavaEnvBuild begin: Manage Java Build Environment",
      "# build config",
      "# rJavaEnvBuild end: Manage Java Build Environment"
    ),
    rprof
  )

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  # Call without project_path should use current working directory
  java_build_env_unset(quiet = TRUE)

  content <- readLines(rprof)
  expect_false(any(grepl("# rJavaEnvBuild", content)))
})

test_that("java_build_env_unset removes only build-related lines", {
  proj_dir <- withr::local_tempdir()
  rprof <- file.path(proj_dir, ".Rprofile")

  # Create .Rprofile with both java env and build env markers
  writeLines(
    c(
      "# User config at top",
      "# rJavaEnv begin: Manage JAVA_HOME",
      "Sys.setenv(JAVA_HOME = '/path')",
      "# rJavaEnv end: Manage JAVA_HOME",
      "# rJavaEnvBuild begin: Manage Java Build Environment",
      "Sys.setenv(JAVA = '/path/bin/java')",
      "# rJavaEnvBuild end: Manage Java Build Environment",
      "# More config"
    ),
    rprof
  )

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  java_build_env_unset(project_path = proj_dir, quiet = TRUE)

  content <- readLines(rprof)
  # Build env should be removed
  expect_false(any(grepl("# rJavaEnvBuild", content)))
  # Java env should remain
  expect_true(any(grepl("# rJavaEnv", content)))
})

test_that("set_java_build_env_vars sets JAVA_HOME and PATH", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  java_home <- "/mock/java/home"

  # Mock installed.packages
  local_mocked_bindings(
    installed.packages = function(...) matrix(character(0), nrow = 0, ncol = 2),
    .package = "utils"
  )

  local_mocked_bindings(
    loadedNamespaces = function() character(0),
    .package = "base"
  )

  # Mock file system operations for Linux-specific code
  local_mocked_bindings(
    Sys.info = function() c(sysname = "Darwin"),
    .package = "base"
  )

  # Call the function with a temporary PATH
  withr::with_envvar(c("PATH" = "/usr/bin"), {
    set_java_build_env_vars(java_home, quiet = TRUE)

    # Check that JAVA_HOME was set
    expect_equal(Sys.getenv("JAVA_HOME"), java_home)
    # Check that JAVA, JAVAC, JAR were set
    expect_equal(Sys.getenv("JAVA"), file.path(java_home, "bin", "java"))
    expect_equal(Sys.getenv("JAVAC"), file.path(java_home, "bin", "javac"))
    expect_equal(Sys.getenv("JAR"), file.path(java_home, "bin", "jar"))
  })
})

test_that("set_java_build_env_vars sets JAVAH when available", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  java_home <- "/mock/java/home"
  javah_path <- file.path(java_home, "bin", "javah")

  local_mocked_bindings(
    installed.packages = function(...) matrix(character(0), nrow = 0, ncol = 2),
    .package = "utils"
  )

  local_mocked_bindings(
    loadedNamespaces = function() character(0),
    .package = "base"
  )

  # Mock file.exists to say javah exists
  local_mocked_bindings(
    file.exists = function(x) {
      if (x == javah_path) TRUE else FALSE
    },
    .package = "base"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Darwin"),
    .package = "base"
  )

  withr::with_envvar(c("PATH" = "/usr/bin"), {
    set_java_build_env_vars(java_home, quiet = TRUE)

    # JAVAH should be set when file exists
    expect_equal(Sys.getenv("JAVAH"), javah_path)
  })
})

test_that("set_java_build_env_vars handles missing javah", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  java_home <- "/mock/java/home"

  local_mocked_bindings(
    installed.packages = function(...) matrix(character(0), nrow = 0, ncol = 2),
    .package = "utils"
  )

  local_mocked_bindings(
    loadedNamespaces = function() character(0),
    .package = "base"
  )

  # Mock file.exists to say javah doesn't exist
  local_mocked_bindings(
    file.exists = function(x) FALSE,
    .package = "base"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Darwin"),
    .package = "base"
  )

  withr::with_envvar(c("PATH" = "/usr/bin"), {
    set_java_build_env_vars(java_home, quiet = TRUE)

    # JAVAH should be empty string when file doesn't exist
    expect_equal(Sys.getenv("JAVAH"), "")
  })
})

test_that("set_java_build_env_vars sets Linux-specific variables", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  skip_on_os("windows")
  skip_on_os("mac")

  java_home <- "/mock/java/home"
  libjvm_path <- file.path(java_home, "lib", "server", "libjvm.so")

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Linux"),
    .package = "base"
  )

  local_mocked_bindings(
    get_libjvm_path = function(...) libjvm_path,
    file.exists = function(x) TRUE,
    system2 = function(...) "mock_config",
    dyn.load = function(...) NULL,
    .package = "rJavaEnv"
  )

  withr::with_envvar(c("LD_LIBRARY_PATH" = "/usr/lib"), {
    set_java_build_env_vars(java_home, quiet = TRUE)

    expect_equal(
      Sys.getenv("JAVA_LD_LIBRARY_PATH"),
      "/mock/java/home/lib/server"
    )
    expect_true(grepl(
      "/mock/java/home/lib/server",
      Sys.getenv("LD_LIBRARY_PATH")
    ))
    expect_true(any(grepl("JAVA_LIBS", names(Sys.envvar()))))
    expect_true(any(grepl("JAVA_CPPFLAGS", names(Sys.envvar()))))
  })
})
