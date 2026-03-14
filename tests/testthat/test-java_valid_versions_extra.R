# Additional coverage tests for java_valid_versions.R

# Test java_valid_versions_fast session cache hit
test_that("java_valid_versions_fast returns session cache when available", {
  withr::local_options(
    rJavaEnv.valid_versions_cache = c("8", "11", "17", "21", "99")
  )

  result <- java_valid_versions_fast()

  expect_equal(result, c("8", "11", "17", "21", "99"))
})

# Test java_valid_versions_fast file cache hit
test_that("java_valid_versions_fast uses file cache when session cache absent", {
  cache_path <- withr::local_tempdir()
  cache_file <- file.path(cache_path, "valid_versions.json")

  withr::local_options(
    rJavaEnv.valid_versions_cache = NULL,
    rJavaEnv.cache_path = cache_path
  )

  # Write a valid cache file
  writeLines('["8", "11", "17", "21", "42"]', cache_file)

  result <- java_valid_versions_fast()

  expect_true("42" %in% result)
})

# Test java_valid_versions_fast fallback when file cache is corrupt
test_that("java_valid_versions_fast fallback on corrupt cache file", {
  cache_path <- withr::local_tempdir()
  cache_file <- file.path(cache_path, "valid_versions.json")

  withr::local_options(
    rJavaEnv.valid_versions_cache = NULL,
    rJavaEnv.cache_path = cache_path
  )

  # Write a corrupt cache file
  writeLines("not valid json {{{", cache_file)

  result <- java_valid_versions_fast()

  # Should return fallback
  expect_type(result, "character")
  expect_true(length(result) > 0)
})

# Test java_valid_versions_fast fallback when file cache is stale
test_that("java_valid_versions_fast fallback on stale cache file", {
  cache_path <- withr::local_tempdir()
  cache_file <- file.path(cache_path, "valid_versions.json")

  withr::local_options(
    rJavaEnv.valid_versions_cache = NULL,
    rJavaEnv.cache_path = cache_path
  )

  # Write a cache file and make it old
  writeLines('["8", "11", "17", "21", "old"]', cache_file)
  Sys.setFileTime(cache_file, Sys.time() - 25 * 60 * 60) # 25 hours ago

  result <- java_valid_versions_fast()

  # Should return fallback, not the cached "old" value
  expect_false("old" %in% result)
})

# Test java_valid_versions session cache hit
# Test java_valid_versions session cache hit
test_that("java_valid_versions returns session cache when fresh", {
  cache_key <- "Corretto_linux_x64"
  val_list <- list()
  val_list[[cache_key]] <- c("8", "11", "17", "21", "session_cached")

  ts_list <- list()
  ts_list[[cache_key]] <- Sys.time()

  withr::local_options(
    rJavaEnv.valid_versions_cache_list = val_list,
    rJavaEnv.valid_versions_timestamp_list = ts_list
  )

  result <- java_valid_versions(
    distribution = "Corretto",
    platform = "linux",
    arch = "x64",
    force = FALSE
  )

  expect_true("session_cached" %in% result)
})

# Test java_valid_versions file cache hit
# Test java_valid_versions file cache hit
test_that("java_valid_versions uses file cache when session cache expired", {
  cache_path <- withr::local_tempdir()
  cache_key <- "Corretto_linux_x64"
  cache_filename <- sprintf("valid_versions_%s.json", cache_key)
  cache_file <- file.path(cache_path, cache_filename)

  withr::local_options(
    rJavaEnv.valid_versions_cache_list = list(),
    rJavaEnv.valid_versions_timestamp_list = list(),
    rJavaEnv.cache_path = cache_path
  )

  # Write a valid cache file
  writeLines('["8", "11", "17", "21", "file_cached"]', cache_file)

  result <- java_valid_versions(
    distribution = "Corretto",
    platform = "linux",
    arch = "x64",
    force = FALSE
  )

  expect_true("file_cached" %in% result)
})

# Test java_valid_versions file cache corrupt handling
test_that("java_valid_versions handles corrupt file cache", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  cache_path <- withr::local_tempdir()
  cache_file <- file.path(cache_path, "valid_versions.json")

  withr::local_options(
    rJavaEnv.valid_versions_cache = NULL,
    rJavaEnv.valid_versions_timestamp = NULL,
    rJavaEnv.cache_path = cache_path
  )

  # Write a corrupt cache file
  writeLines("not valid json {{{", cache_file)

  # Should fetch from network and return valid versions
  result <- java_valid_versions(force = FALSE)

  expect_type(result, "character")
  expect_true(length(result) > 0)
})

# Test java_valid_versions file cache stale
test_that("java_valid_versions fetches from network when file cache expired", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  cache_path <- withr::local_tempdir()
  cache_file <- file.path(cache_path, "valid_versions.json")

  withr::local_options(
    rJavaEnv.valid_versions_cache = NULL,
    rJavaEnv.valid_versions_timestamp = NULL,
    rJavaEnv.cache_path = cache_path
  )

  # Write a cache file and make it old
  writeLines('["8", "11", "17", "21", "stale"]', cache_file)
  Sys.setFileTime(cache_file, Sys.time() - 25 * 60 * 60) # 25 hours ago

  result <- java_valid_versions(force = FALSE)

  # Should contain real versions from network
  expect_true("8" %in% result)
  expect_true("21" %in% result)
})

# Test java_valid_versions saves to caches
test_that("java_valid_versions saves results to session and file cache", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  cache_path <- withr::local_tempdir()

  withr::local_options(
    rJavaEnv.valid_versions_cache_list = NULL,
    rJavaEnv.valid_versions_timestamp_list = NULL,
    rJavaEnv.cache_path = cache_path
  )

  # Use fixed params via defaults or explicit if needed, but here defaults are fine
  # provided we know what key they generate.
  # By default: distribution="Corretto", platform=platform_detect()$os, arch=platform_detect()$arch

  result <- java_valid_versions(force = TRUE)

  plat <- platform_detect(quiet = TRUE)$os
  arch <- platform_detect(quiet = TRUE)$arch
  cache_key <- sprintf("Corretto_%s_%s", plat, arch)

  # Session cache check
  cache_list <- getOption("rJavaEnv.valid_versions_cache_list")
  ts_list <- getOption("rJavaEnv.valid_versions_timestamp_list")

  expect_false(is.null(cache_list[[cache_key]]))
  expect_equal(cache_list[[cache_key]], result)
  expect_false(is.null(ts_list[[cache_key]]))

  # File cache check
  expected_file <- file.path(
    cache_path,
    sprintf("valid_versions_%s.json", cache_key)
  )
  expect_true(file.exists(expected_file))
})

test_that("java_valid_major_versions_temurin filters summary versions by assets", {
  local_mocked_bindings(
    read_json_url = function(url, max_simplify_lvl = "data_frame") {
      if (grepl("info/available_releases", url)) {
        return(list(available_releases = c(8, 11, 21)))
      }
      if (grepl("assets/latest/8/", url)) {
        return(list(list(
          binary = list(package = list(link = "https://example.com/8.tar.gz")),
          version_data = list(semver = "8.0.452+9", openjdk_version = "8.0.452")
        )))
      }
      if (grepl("assets/latest/11/", url)) {
        return(list())
      }
      if (grepl("assets/latest/21/", url)) {
        return(list(list(
          binary = list(package = list(link = "https://example.com/21.tar.gz")),
          version_data = list(semver = "21.0.8+9", openjdk_version = "21.0.8")
        )))
      }
      stop("Unexpected URL")
    },
    .package = "rJavaEnv"
  )

  versions <- java_valid_major_versions_temurin(platform = "linux", arch = "x64")

  expect_equal(versions, c("8", "21"))
})

test_that("java_valid_major_versions_temurin falls back from empty summary", {
  local_mocked_bindings(
    read_json_url = function(url, max_simplify_lvl = "data_frame") {
      if (grepl("info/available_releases", url)) {
        return(list(available_releases = integer(0)))
      }
      if (grepl("assets/latest/17/", url)) {
        return(list(list(
          binary = list(package = list(link = "https://example.com/17.tar.gz")),
          version_data = list(semver = "17.0.16+8", openjdk_version = "17.0.16")
        )))
      }
      if (grepl("assets/latest/21/", url)) {
        return(list(list(
          binary = list(package = list(link = "https://example.com/21.tar.gz")),
          version_data = list(semver = "21.0.8+9", openjdk_version = "21.0.8")
        )))
      }
      list()
    },
    .package = "rJavaEnv"
  )

  expect_message(
    versions <- java_valid_major_versions_temurin(platform = "linux", arch = "x64"),
    "summary endpoint returned no usable major versions"
  )

  expect_equal(versions, c("17", "21"))
})

test_that("java_valid_major_versions_temurin handles malformed summary payload", {
  local_mocked_bindings(
    read_json_url = function(url, max_simplify_lvl = "data_frame") {
      if (grepl("info/available_releases", url)) {
        return(list(tip_version = 27))
      }
      if (grepl("assets/latest/25/", url)) {
        return(list(list(
          binary = list(package = list(link = "https://example.com/25.tar.gz")),
          version_data = list(semver = "25.0.2+10", openjdk_version = "25.0.2")
        )))
      }
      list()
    },
    .package = "rJavaEnv"
  )

  expect_message(
    versions <- java_valid_major_versions_temurin(platform = "linux", arch = "x64"),
    "summary endpoint returned no usable major versions"
  )

  expect_equal(versions, "25")
})

test_that("java_valid_major_versions_temurin uses shipped fallback when probes fail", {
  local_mocked_bindings(
    read_json_url = function(...) stop("Network down"),
    .package = "rJavaEnv"
  )

  fallback <- temurin_candidate_versions("linux", "x64")

  expect_warning(
    versions <- suppressMessages(
      java_valid_major_versions_temurin(platform = "linux", arch = "x64")
    ),
    "Returning shipped fallback versions"
  )

  expect_equal(versions, fallback)
})

# Test java_valid_major_versions_corretto with explicit platform/arch
test_that("java_valid_major_versions_corretto works with explicit parameters", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  result <- java_valid_major_versions_corretto(
    platform = "linux",
    arch = "x64"
  )

  expect_type(result, "character")
  expect_true("8" %in% result)
  expect_true("21" %in% result)
})
