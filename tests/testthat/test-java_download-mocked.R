# Mocked unit tests for java_download()
# Updated for metadata-first architecture

test_that("java_download handles successful download and checksum", {
  local_cache_path <- withr::local_tempdir()

  # Mock resolve_java_metadata to return a known build
  local_mocked_bindings(
    resolve_java_metadata = function(
      version,
      distribution,
      platform,
      arch,
      backend
    ) {
      java_build(
        vendor = "Corretto",
        version = as.character(version),
        major = as.integer(version),
        platform = platform,
        arch = arch,
        download_url = "https://example.com/corretto-21.tar.gz",
        filename = "corretto-21-test.tar.gz",
        checksum = "dummychecksum",
        checksum_type = "sha256",
        backend = "native"
      )
    }
  )

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      writeLines("dummy content", destfile)
    },
    .package = "curl"
  )

  local_mocked_bindings(
    digest = function(file, algo, ...) "dummychecksum",
    .package = "digest"
  )

  expect_silent(
    result_path <- java_download(
      version = "21",
      cache_path = local_cache_path,
      quiet = TRUE
    )
  )
  expect_true(file.exists(result_path))
})

test_that("java_download aborts on SHA256 checksum mismatch", {
  local_cache_path <- withr::local_tempdir()

  # Mock resolve_java_metadata to return a known build
  local_mocked_bindings(
    resolve_java_metadata = function(
      version,
      distribution,
      platform,
      arch,
      backend
    ) {
      java_build(
        vendor = "Corretto",
        version = as.character(version),
        major = as.integer(version),
        platform = platform,
        arch = arch,
        download_url = "https://example.com/corretto-21.tar.gz",
        filename = "corretto-21-test.tar.gz",
        checksum = "expected_checksum",
        checksum_type = "sha256",
        backend = "native"
      )
    }
  )

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      writeLines("some content", destfile)
    },
    .package = "curl"
  )

  local_mocked_bindings(
    digest = function(file, algo, ...) "actual_checksum_mismatch",
    .package = "digest"
  )

  expect_error(
    java_download(version = "21", cache_path = local_cache_path, quiet = TRUE),
    "checksum mismatch"
  )
})

test_that("java_download skips download if file exists and force is FALSE", {
  local_cache_path <- withr::local_tempdir()
  dest_dir <- file.path(local_cache_path, "distrib")
  dir.create(dest_dir, recursive = TRUE)

  platform <- platform_detect()$os
  arch <- platform_detect()$arch
  expected_filename <- "corretto-21-test.tar.gz"
  expected_file_path <- file.path(dest_dir, expected_filename)
  file.create(expected_file_path)

  # Mock resolve_java_metadata to return a known build
  local_mocked_bindings(
    resolve_java_metadata = function(version, distribution, plat, ar, backend) {
      java_build(
        vendor = "Corretto",
        version = as.character(version),
        major = as.integer(version),
        platform = plat,
        arch = ar,
        download_url = "https://example.com/corretto-21.tar.gz",
        filename = expected_filename,
        checksum = "somechecksum",
        checksum_type = "sha256",
        backend = "native"
      )
    }
  )

  local_mocked_bindings(
    curl_download = function(...) {
      stop("curl_download should not have been called!")
    },
    .package = "curl"
  )

  result <- java_download(
    version = "21",
    cache_path = local_cache_path,
    platform = platform,
    arch = arch,
    quiet = TRUE,
    force = FALSE
  )

  expect_equal(normalizePath(result), normalizePath(expected_file_path))
})


test_that("java_download overwrites if file exists and force is TRUE", {
  local_cache_path <- withr::local_tempdir()
  dest_dir <- file.path(local_cache_path, "distrib")
  dir.create(dest_dir, recursive = TRUE)

  platform <- platform_detect()$os
  arch <- platform_detect()$arch
  expected_filename <- "corretto-21-test.tar.gz"
  expected_file_path <- file.path(dest_dir, expected_filename)
  writeLines("old content", expected_file_path)

  # Mock resolve_java_metadata to return a known build
  local_mocked_bindings(
    resolve_java_metadata = function(version, distribution, plat, ar, backend) {
      java_build(
        vendor = "Corretto",
        version = as.character(version),
        major = as.integer(version),
        platform = plat,
        arch = ar,
        download_url = "https://example.com/corretto-21.tar.gz",
        filename = expected_filename,
        checksum = "new_checksum",
        checksum_type = "sha256",
        backend = "native"
      )
    }
  )

  curl_call_count <- 0
  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      curl_call_count <<- curl_call_count + 1
      writeLines("new content", destfile)
    },
    .package = "curl"
  )

  local_mocked_bindings(
    digest = function(file, algo, ...) "new_checksum",
    .package = "digest"
  )

  java_download(
    version = "21",
    cache_path = local_cache_path,
    platform = platform,
    arch = arch,
    quiet = TRUE,
    force = TRUE
  )

  expect_equal(curl_call_count, 1)
  expect_equal(readLines(expected_file_path), "new content")
})
