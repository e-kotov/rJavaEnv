# Mocked unit tests for java_install()
# NOTE: Common mocks (java_valid_versions, rje_consent_check, java_unpack)
# are defined globally in the setup-mock-globals.R file.

test_that("java_install succeeds with symlink on Unix-like systems", {
  # This test is for non-Windows behavior
  skip_on_os("windows")

  local_proj_path <- withr::local_tempdir(pattern = "project")
  local_cache_path <- withr::local_tempdir(pattern = "cache")
  withr::local_options(rJavaEnv.cache_path = local_cache_path)

  fake_distrib_path <- file.path(
    local_cache_path,
    "distrib",
    "amazon-corretto-21-x64-linux-jdk.tar.gz"
  )
  # The global mock will generate the unpacked path based on the distrib path
  fake_unpacked_path <- java_unpack(fake_distrib_path)
  expected_symlink_path <- file.path(
    local_proj_path,
    "rjavaenv",
    "linux",
    "x64",
    "21"
  )

  env_set_calls <- 0
  local_mocked_bindings(
    java_env_set = function(...) {
      env_set_calls <<- env_set_calls + 1
    }
  )

  symlink_calls <- 0
  symlink_args <- list()
  local_mocked_bindings(
    file.symlink = function(from, to) {
      symlink_calls <<- symlink_calls + 1
      symlink_args <<- list(from = from, to = to)
    },
    .package = "base"
  )

  return_val <- java_install(
    java_distrib_path = fake_distrib_path,
    project_path = local_proj_path,
    quiet = TRUE
  )

  expect_equal(env_set_calls, 1)
  expect_equal(symlink_calls, 1)
  expect_equal(symlink_args$from, fake_unpacked_path)
  expect_equal(symlink_args$to, expected_symlink_path)
  expect_equal(return_val, fake_unpacked_path)
})


test_that("java_install falls back to file.copy when symlink fails on Unix", {
  skip_on_os("windows")

  local_proj_path <- withr::local_tempdir()
  local_cache_path <- withr::local_tempdir()
  withr::local_options(rJavaEnv.cache_path = local_cache_path)

  fake_distrib_path <- file.path(
    local_cache_path,
    "distrib",
    "amazon-corretto-21-x64-linux-jdk.tar.gz"
  )

  local_mocked_bindings(java_env_set = function(...) TRUE)

  local_mocked_bindings(
    file.symlink = function(from, to) stop("Permission denied"),
    .package = "base"
  )

  copy_calls <- 0
  local_mocked_bindings(
    file.copy = function(from, to, ...) {
      if (grepl(basename(local_proj_path), to, fixed = TRUE)) {
        copy_calls <<- copy_calls + 1
      }
      TRUE
    },
    .package = "base"
  )

  java_install(
    java_distrib_path = fake_distrib_path,
    project_path = local_proj_path,
    quiet = TRUE
  )

  expect_equal(copy_calls, 1)
})


test_that("java_install respects autoset_java_env = FALSE", {
  local_proj_path <- withr::local_tempdir()
  local_cache_path <- withr::local_tempdir()
  withr::local_options(rJavaEnv.cache_path = local_cache_path)

  fake_distrib_path <- file.path(
    local_cache_path,
    "distrib",
    "amazon-corretto-21-x64-linux-jdk.tar.gz"
  )

  # CORRECTED: Add an explicit mock for java_unpack for this test
  # to prevent the real function from being called and issuing a warning.
  local_mocked_bindings(
    java_unpack = function(...) {
      # Return a simple, predictable path string
      "/mock/cache/path/installed/linux/x64/21"
    }
  )

  # Mock file.symlink to succeed
  local_mocked_bindings(
    file.symlink = function(...) TRUE,
    .package = "base"
  )

  # Mock java_env_set to fail the test if it's ever called
  local_mocked_bindings(
    java_env_set = function(...) {
      stop("java_env_set should not have been called!")
    }
  )

  # This test will now pass silently because java_unpack is properly mocked.
  expect_silent(
    java_install(
      java_distrib_path = fake_distrib_path,
      project_path = local_proj_path,
      autoset_java_env = FALSE,
      quiet = TRUE
    )
  )
})


test_that("java_install succeeds with mklink junction on Windows", {
  skip_on_os("mac")
  skip_on_os("linux")
  skip_on_os("solaris")

  local_proj_path <- withr::local_tempdir()
  local_cache_path <- withr::local_tempdir()
  withr::local_options(rJavaEnv.cache_path = local_cache_path)

  fake_distrib_path <- file.path(
    local_cache_path,
    "distrib",
    "amazon-corretto-21-x64-windows-jdk.zip"
  )

  local_mocked_bindings(java_env_set = function(...) TRUE)

  system2_args <- list()
  local_mocked_bindings(
    system2 = function(command, args, ...) {
      system2_args <<- list(command = command, args = args)
      "Junction created for ... " # Simulate success message
    },
    .package = "base"
  )

  java_install(
    java_distrib_path = fake_distrib_path,
    project_path = local_proj_path,
    quiet = TRUE
  )

  expect_equal(system2_args$command, "cmd.exe")
  expect_true(grepl("mklink /J", system2_args$args[2]))
})
