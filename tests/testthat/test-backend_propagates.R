test_that("backend argument propagates in use_java", {
  local_mocked_bindings(
    java_list_installed = function(...) {
      data.frame(
        path = "path/to/java",
        version = "21",
        platform = "linux",
        arch = "x64",
        distribution = "Corretto",
        backend = "sdkman",
        stringsAsFactors = FALSE
      )
    },
    ._java_env_set_impl = function(...) invisible(NULL),
    platform_detect = function(...) list(os = "linux", arch = "x64"),
    .package = "rJavaEnv"
  )

  # Should NOT find in cache because we ask for "native" (default) but cache has "sdkman"
  download_called_backend <- NULL
  local_mocked_bindings(
    java_download = function(..., backend) {
      download_called_backend <<- backend
      return("mock_dist_path")
    },
    java_unpack = function(...) "mock_unpack_path",
    java_valid_versions = function(...) "21",
    .package = "rJavaEnv"
  )

  use_java(
    version = 21,
    distribution = "Corretto",
    backend = "native",
    quiet = TRUE
  )
  expect_equal(download_called_backend, "native")

  # Should FIND in cache because backend matches
  download_called_backend <- NULL
  use_java(
    version = 21,
    distribution = "Corretto",
    backend = "sdkman",
    quiet = TRUE
  )
  expect_null(download_called_backend)
})

test_that("backend argument propagates in java_resolve", {
  local_mocked_bindings(
    java_list_installed = function(...) {
      data.frame(
        path = "path/to/java",
        version = "21",
        platform = "linux",
        arch = "x64",
        distribution = "Corretto",
        backend = "sdkman",
        stringsAsFactors = FALSE
      )
    },
    java_check_version_cmd = function(...) FALSE,
    java_find_system = function(...) data.frame(),
    platform_detect = function(...) list(os = "linux", arch = "x64"),
    .package = "rJavaEnv"
  )

  # Should NOT find in cache
  download_called_backend <- NULL
  local_mocked_bindings(
    java_download = function(..., backend) {
      download_called_backend <<- backend
      return("mock_dist_path")
    },
    java_unpack = function(...) "mock_unpack_path",
    java_valid_versions = function(...) "21",
    rje_consent_check = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  java_resolve(
    version = 21,
    distribution = "Corretto",
    backend = "native",
    quiet = TRUE
  )
  expect_equal(download_called_backend, "native")

  # Should FIND in cache
  download_called_backend <- NULL
  res <- java_resolve(
    version = 21,
    distribution = "Corretto",
    backend = "sdkman",
    quiet = TRUE
  )
  expect_null(download_called_backend)
  expect_equal(res, "path/to/java")
})

test_that("backend argument propagates in java_quick_install", {
  download_called_backend <- NULL
  local_mocked_bindings(
    java_download = function(..., backend) {
      download_called_backend <<- backend
      return("mock_dist_path")
    },
    java_install = function(...) "mock_home",
    rje_consent_check = function(...) invisible(NULL),
    platform_detect = function(...) list(os = "linux", arch = "x64"),
    .package = "rJavaEnv"
  )

  java_quick_install(
    version = 21,
    distribution = "Corretto",
    backend = "sdkman",
    quiet = TRUE,
    temp_dir = TRUE
  )
  expect_equal(download_called_backend, "sdkman")
})

test_that("backend argument propagates in java_ensure", {
  local_mocked_bindings(
    java_resolve = function(..., backend) {
      expect_equal(backend, "sdkman")
      return("mock_path")
    },
    ._java_env_set_impl = function(...) invisible(NULL),
    check_rjava_initialized = function(...) FALSE,
    java_check_current_rjava_version = function(...) NULL,
    platform_detect = function(...) list(os = "linux", arch = "x64"),
    .package = "rJavaEnv"
  )

  java_ensure(
    version = 21,
    distribution = "Corretto",
    backend = "sdkman",
    quiet = TRUE
  )
})
