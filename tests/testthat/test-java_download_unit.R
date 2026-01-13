# Additional coverage tests for java_download.R
# Updated for metadata-first architecture

# Test temp_dir = TRUE path
test_that("java_download with temp_dir = TRUE uses temporary directory", {
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

  # Mock curl to create files
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

  # Capture the working directory before and after
  original_wd <- getwd()
  withr::defer(setwd(original_wd))

  result_path <- java_download(
    version = "21",
    temp_dir = TRUE,
    quiet = TRUE
  )

  expect_true(file.exists(result_path))
  expect_true(grepl("rJavaEnv_cache", result_path))
})

# Test unsupported distribution error
test_that("java_download errors on unsupported distribution", {
  local_cache_path <- withr::local_tempdir()

  expect_error(
    java_download(
      version = "21",
      distribution = "InvalidDistro",
      cache_path = local_cache_path,
      quiet = TRUE
    ),
    "InvalidDistro"
  )
})

# Test quiet = FALSE outputs messages
test_that("java_download outputs messages when quiet = FALSE", {
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

  expect_message(
    java_download(
      version = "21",
      cache_path = local_cache_path,
      quiet = FALSE
    ),
    "Detected platform"
  )
})
