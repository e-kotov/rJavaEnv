# Cached Java must be usable without network access

offline_metadata <- function(...) {
  stop("Corretto index download error: Could not resolve host: corretto.github.io")
}

make_java_home <- function(...) {
  path <- file.path(...)
  dir.create(file.path(path, "bin"), recursive = TRUE)
  path
}

test_that("java_installed_matching keeps exact matches first and legacy Corretto installs", {
  cache_path <- withr::local_tempdir()
  installed <- file.path(cache_path, "installed")
  exact <- make_java_home(installed, "linux", "x64", "Corretto", "native", "21")
  legacy <- make_java_home(installed, "linux", "x64", "17")
  make_java_home(installed, "linux", "x64", "unknown", "unknown", "11")
  make_java_home(installed, "linux", "x64", "Temurin", "native", "21")
  make_java_home(installed, "macos", "aarch64", "21")

  cache <- java_list_installed(cache_path = cache_path)

  corretto <- java_installed_matching(cache, "Corretto", "native", "linux", "x64")
  expect_equal(corretto$path, c(exact, legacy))

  # Legacy installs were always Corretto via the native backend
  temurin <- java_installed_matching(cache, "Temurin", "native", "linux", "x64")
  expect_equal(temurin$version, "21")
  expect_equal(temurin$distribution, "Temurin")
  sdkman <- java_installed_matching(cache, "Corretto", "sdkman", "linux", "x64")
  expect_equal(nrow(sdkman), 0)

  expect_equal(nrow(java_installed_matching(character(0), "Corretto", "native", "linux", "x64")), 0)
})

test_that("use_java uses a legacy-layout install without network access", {
  cache_path <- withr::local_tempdir()
  legacy <- make_java_home(cache_path, "installed", "linux", "x64", "21")

  set_home <- NULL
  local_mocked_bindings(
    ._java_env_set_impl = function(java_home, ...) set_home <<- java_home,
    java_valid_versions = function(...) stop("network used"),
    resolve_java_metadata = function(...) stop("network used")
  )

  expect_true(use_java(21, cache_path = cache_path, platform = "linux", arch = "x64"))
  expect_equal(set_home, legacy)
})

test_that("java_resolve uses a legacy-layout install without network access", {
  cache_path <- withr::local_tempdir()
  legacy <- make_java_home(cache_path, "installed", "linux", "x64", "21")

  local_mocked_bindings(resolve_java_metadata = function(...) stop("network used"))

  expect_equal(
    java_resolve(
      21,
      accept_system_java = FALSE,
      quiet = TRUE,
      cache_path = cache_path,
      platform = "linux",
      arch = "x64"
    ),
    legacy
  )
})

test_that("find_cached_native_distrib picks the newest matching Corretto build", {
  dest_dir <- withr::local_tempdir()
  file.create(file.path(dest_dir, c(
    "native-amazon-corretto-21.0.9.10.1-linux-x64.tar.gz",
    "native-amazon-corretto-21.0.13.0.10-linux-x64.tar.gz",
    "native-amazon-corretto-17.0.17.10.1-linux-x64.tar.gz",
    "native-amazon-corretto-21.0.13.0.10-linux-aarch64.tar.gz",
    "native-amazon-corretto-21.0.13.0.10-alpine-linux-x64.tar.gz",
    "native-amazon-corretto-21.0.13.0.10-macosx-aarch64.tar.gz",
    "native-amazon-corretto-21.0.13.0.10-windows-x64-jdk.zip"
  )))

  find <- function(version, platform = "linux", arch = "x64") {
    basename(find_cached_native_distrib(dest_dir, version, "Corretto", platform, arch) %||% NA_character_)
  }

  expect_equal(find("21"), "native-amazon-corretto-21.0.13.0.10-linux-x64.tar.gz")
  expect_equal(find("21.0.9"), "native-amazon-corretto-21.0.9.10.1-linux-x64.tar.gz")
  expect_equal(find("17"), "native-amazon-corretto-17.0.17.10.1-linux-x64.tar.gz")
  expect_equal(find("21", arch = "aarch64"), "native-amazon-corretto-21.0.13.0.10-linux-aarch64.tar.gz")
  expect_equal(find("21", platform = "macos", arch = "aarch64"), "native-amazon-corretto-21.0.13.0.10-macosx-aarch64.tar.gz")
  expect_equal(find("21", platform = "windows"), "native-amazon-corretto-21.0.13.0.10-windows-x64-jdk.zip")
  expect_equal(find("2"), NA_character_)
  expect_equal(find("11"), NA_character_)
  expect_equal(find("21.0.1"), NA_character_)
})

test_that("find_cached_native_distrib handles Temurin, Zulu and pre-0.4.0 Corretto names", {
  dest_dir <- withr::local_tempdir()
  expect_null(find_cached_native_distrib(dest_dir, "21", "Corretto", "linux", "x64"))

  file.create(file.path(dest_dir, c(
    "native-temurin-21-linux-x64.tar.gz",
    "native-zulu-17-macos-aarch64.tar.gz",
    "amazon-corretto-11-x64-linux-jdk.tar.gz",
    "sdkman-corretto-21-linux-x64.tar.gz"
  )))

  expect_equal(
    basename(find_cached_native_distrib(dest_dir, "21", "Temurin", "linux", "x64")),
    "native-temurin-21-linux-x64.tar.gz"
  )
  expect_null(find_cached_native_distrib(dest_dir, "17", "Temurin", "linux", "x64"))
  expect_equal(
    basename(find_cached_native_distrib(dest_dir, "17", "Zulu", "macos", "aarch64")),
    "native-zulu-17-macos-aarch64.tar.gz"
  )
  expect_equal(
    basename(find_cached_native_distrib(dest_dir, "11", "Corretto", "linux", "x64")),
    "amazon-corretto-11-x64-linux-jdk.tar.gz"
  )
  expect_null(find_cached_native_distrib(dest_dir, "21", "Corretto", "linux", "x64"))
})

test_that("java_download falls back to a cached archive when metadata cannot be resolved", {
  cache_path <- withr::local_tempdir()
  dir.create(file.path(cache_path, "distrib"))
  archive <- file.path(cache_path, "distrib", "native-amazon-corretto-21.0.13.0.10-linux-x64.tar.gz")
  file.create(archive)

  local_mocked_bindings(resolve_java_metadata = offline_metadata)
  local_mocked_bindings(
    curl_download = function(...) stop("network used"),
    .package = "curl"
  )

  result <- java_download(21, cache_path = cache_path, platform = "linux", arch = "x64", quiet = TRUE)
  expect_equal(as.character(result), archive)
  expect_equal(attr(result, "distribution"), "Corretto")
  expect_equal(attr(result, "backend"), "native")

  expect_message(
    java_download(21, cache_path = cache_path, platform = "linux", arch = "x64", quiet = FALSE),
    "Using cached archive"
  )

  # Nothing cached for this request, or a forced re-download: keep the original error
  expect_error(
    java_download(17, cache_path = cache_path, platform = "linux", arch = "x64", quiet = TRUE),
    "Could not resolve host"
  )
  expect_error(
    java_download(21, cache_path = cache_path, platform = "linux", arch = "x64", quiet = TRUE, force = TRUE),
    "Could not resolve host"
  )
})

test_that("use_java skips online version validation when the archive is cached", {
  cache_path <- withr::local_tempdir()
  dir.create(file.path(cache_path, "distrib"))
  file.create(file.path(cache_path, "distrib", "native-temurin-21-linux-x64.tar.gz"))

  unpacked <- NULL
  local_mocked_bindings(
    java_valid_versions = function(...) stop("network used"),
    resolve_java_metadata = offline_metadata,
    java_unpack = function(java_distrib_path, ...) {
      unpacked <<- java_distrib_path
      "java-home"
    },
    ._java_env_set_impl = function(...) invisible(NULL)
  )

  expect_true(use_java(
    21,
    distribution = "Temurin",
    cache_path = cache_path,
    platform = "linux",
    arch = "x64"
  ))
  expect_equal(basename(unpacked), "native-temurin-21-linux-x64.tar.gz")
})

test_that("find_cached_native_distrib never matches an unsupported distribution", {
  dest_dir <- withr::local_tempdir()
  file.create(file.path(dest_dir, "native-amazon-corretto-21.0.13.0.10-linux-x64.tar.gz"))

  expect_null(find_cached_native_distrib(dest_dir, "21", "InvalidDistro", "linux", "x64"))
})
