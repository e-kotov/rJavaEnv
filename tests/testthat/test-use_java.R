# Additional coverage tests for use_java.R

# Test use_java cache hit path
test_that("use_java returns early when version found in cache", {
  cache_path <- withr::local_tempdir()

  # Create fake installed cache structure
  installed_path <- file.path(
    cache_path,
    "installed",
    "macos",
    "aarch64",
    "21",
    "Contents",
    "Home"
  )
  dir.create(installed_path, recursive = TRUE)

  local_mocked_bindings(
    java_list_installed_cache = function(...) {
      data.frame(
        path = dirname(dirname(installed_path)),
        version = "21",
        platform = "macos",
        arch = "aarch64",
        stringsAsFactors = FALSE
      )
    },
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    ._java_env_set_impl = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    platform_detect = function(...) list(os = "macos", arch = "aarch64"),
    .package = "rJavaEnv"
  )

  result <- use_java(
    version = 21,
    cache_path = cache_path,
    quiet = TRUE
  )

  expect_true(result)
})

# Test use_java cache hit with quiet = FALSE
test_that("use_java cache hit outputs messages when quiet = FALSE", {
  cache_path <- withr::local_tempdir()

  # Create fake installed cache structure
  installed_path <- file.path(
    cache_path,
    "installed",
    "linux",
    "x64",
    "17",
    "bin"
  )
  dir.create(installed_path, recursive = TRUE)

  local_mocked_bindings(
    java_list_installed_cache = function(...) {
      data.frame(
        path = dirname(installed_path),
        version = "17",
        platform = "linux",
        arch = "x64",
        stringsAsFactors = FALSE
      )
    },
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    ._java_env_set_impl = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    platform_detect = function(...) list(os = "linux", arch = "x64"),
    .package = "rJavaEnv"
  )

  expect_message(
    use_java(
      version = 17,
      cache_path = cache_path,
      quiet = FALSE
    ),
    "found in cache"
  )
})

# Test use_java cache miss - triggers download path
test_that("use_java downloads when version not in cache", {
  cache_path <- withr::local_tempdir()

  local_mocked_bindings(
    java_list_installed_cache = function(...) {
      data.frame(
        path = character(0),
        version = character(0),
        platform = character(0),
        arch = character(0),
        stringsAsFactors = FALSE
      )
    },
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    java_valid_versions = function(...) c("8", "11", "17", "21"),
    .package = "rJavaEnv"
  )

  download_called <- FALSE
  local_mocked_bindings(
    java_download = function(...) {
      download_called <<- TRUE
      file.path(cache_path, "fake-distrib.tar.gz")
    },
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    java_unpack = function(...) {
      file.path(cache_path, "installed", "21")
    },
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    ._java_env_set_impl = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  result <- use_java(
    version = 21,
    cache_path = cache_path,
    quiet = TRUE
  )

  expect_true(download_called)
  expect_true(result)
})

# Test use_java download path with quiet = FALSE
test_that("use_java download path outputs success message", {
  cache_path <- withr::local_tempdir()

  local_mocked_bindings(
    java_list_installed_cache = function(...) {
      data.frame(
        path = character(0),
        version = character(0),
        platform = character(0),
        arch = character(0),
        stringsAsFactors = FALSE
      )
    },
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    java_valid_versions = function(...) c("8", "11", "17", "21"),
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    java_download = function(...) {
      file.path(cache_path, "fake-distrib.tar.gz")
    },
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    java_unpack = function(...) {
      file.path(cache_path, "installed", "21")
    },
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    ._java_env_set_impl = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  expect_message(
    use_java(
      version = 21,
      cache_path = cache_path,
      quiet = FALSE
    ),
    "was set"
  )
})
