# Mocked unit tests for java_install()
# NOTE: Common mocks (java_valid_versions, rje_consent_check, java_unpack)
# are defined globally in the setup-mock-globals.R file.

test_that("java_install succeeds with symlink on Unix-like systems", {
  # This test is for non-Windows behavior
  skip_on_os("windows")

  local_proj_path <- withr::local_tempdir(pattern = "project")
  local_cache_path <- withr::local_tempdir(pattern = "cache")
  withr::local_options(rJavaEnv.cache_path = local_cache_path)

  # 1. Detect the current platform of the runner.
  platform_info <- platform_detect(quiet = TRUE)
  os <- platform_info$os
  arch <- platform_info$arch

  # 2. Construct a filename that matches the runner's OS.
  fake_filename <- paste0("amazon-corretto-21-", arch, "-", os, "-jdk.tar.gz")
  distrib_dir <- file.path(local_cache_path, "distrib")
  dir.create(distrib_dir, recursive = TRUE)
  fake_distrib_path <- file.path(distrib_dir, fake_filename)

  # 3. CRITICAL: Create the empty dummy file for untar to find.
  file.create(fake_distrib_path)

  # Apply the mocks
  mock_java_globals()

  # The global mock will generate the unpacked path based on the distrib path
  # Since we mocked java_unpack in the namespace but the attached version might be stale,
  # we manually construct the expected path to match the mock's logic.
  # New structure: platform/arch/distribution/backend/version
  fake_unpacked_path <- file.path(
    "/mock/cache/path",
    "installed",
    os,
    arch,
    "unknown",
    "unknown",
    "21"
  )
  expected_symlink_path <- file.path(
    local_proj_path,
    "rjavaenv",
    os,
    arch,
    "unknown",
    "unknown",
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

  # With the dummy file in place, this will now run silently without warnings.
  expect_silent({
    return_val <- java_install(
      java_distrib_path = fake_distrib_path,
      project_path = local_proj_path,
      quiet = TRUE
    )
  })

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

  platform_info <- platform_detect(quiet = TRUE)
  os <- platform_info$os
  arch <- platform_info$arch

  fake_filename <- paste0("amazon-corretto-21-", arch, "-", os, "-jdk.tar.gz")
  distrib_dir <- file.path(local_cache_path, "distrib")
  dir.create(distrib_dir, recursive = TRUE)
  fake_distrib_path <- file.path(distrib_dir, fake_filename)
  file.create(fake_distrib_path)

  mock_java_globals()
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

  expect_silent(
    java_install(
      java_distrib_path = fake_distrib_path,
      project_path = local_proj_path,
      quiet = TRUE
    )
  )

  expect_equal(copy_calls, 1)
})
test_that("java_install respects autoset_java_env = FALSE", {
  skip_on_os("windows") # Uses Linux filename, not applicable on Windows
  local_proj_path <- withr::local_tempdir()
  # Use a valid-looking filename that can be properly parsed
  fake_distrib_path <- "any/fake/path/amazon-corretto-21-x64-linux-jdk.tar.gz"

  # --- THE FIX ---
  # Add a local mock for java_unpack(). This prevents the real function
  # (and its call to utils::untar) from ever running.
  # This isolates the test to only check the logic we care about.
  mock_java_globals()

  # Mock file.symlink to prevent another potential side-effect
  local_mocked_bindings(
    file.symlink = function(...) TRUE,
    .package = "base"
  )

  # This mock remains the core of the test: fail if java_env_set is ever called.
  local_mocked_bindings(
    java_env_set = function(...) {
      stop("java_env_set should not have been called!")
    }
  )

  # Now, with java_unpack properly mocked, no warnings will be produced.
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

  # This test is Windows-specific, so a hardcoded windows path is fine.
  fake_distrib_path <- file.path(
    local_cache_path,
    "distrib",
    "amazon-corretto-21-x64-windows-jdk.zip"
  )
  # No need to create the file, as it doesn't call untar/unzip.

  mock_java_globals()
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
