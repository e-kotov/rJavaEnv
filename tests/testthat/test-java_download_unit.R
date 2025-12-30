# Additional coverage tests for java_download.R

# Test temp_dir = TRUE path
test_that("java_download with temp_dir = TRUE uses temporary directory", {
  # MOCK THE SLOW NETWORK CALL
  local_mocked_bindings(
    java_valid_versions = function(...) c("8", "11", "17", "21")
  )

  # Mock curl to create files
  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      if (grepl("\\.md5$", destfile)) {
        writeLines("dummymd5checksum", destfile)
      } else {
        writeLines("dummy content", destfile)
      }
    },
    .package = "curl"
  )

  local_mocked_bindings(
    md5sum = function(files) setNames("dummymd5checksum", files),
    .package = "tools"
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

  local_mocked_bindings(
    java_valid_versions = function(...) c("8", "11", "17", "21")
  )

  expect_error(
    java_download(
      version = "21",
      distribution = "InvalidDistro",
      cache_path = local_cache_path,
      quiet = TRUE
    ),
    "Corretto"
  )
})

# Test unsupported platform error
test_that("java_download errors on unsupported platform", {
  local_cache_path <- withr::local_tempdir()

  local_mocked_bindings(
    java_valid_versions = function(...) c("8", "11", "17", "21")
  )

  expect_error(
    java_download(
      version = "21",
      platform = "freebsd",
      cache_path = local_cache_path,
      quiet = TRUE
    ),
    "freebsd"
  )
})

# Test unsupported architecture error
test_that("java_download errors on unsupported architecture", {
  local_cache_path <- withr::local_tempdir()

  local_mocked_bindings(
    java_valid_versions = function(...) c("8", "11", "17", "21")
  )

  expect_error(
    java_download(
      version = "21",
      platform = "linux",
      arch = "mips",
      cache_path = local_cache_path,
      quiet = TRUE
    ),
    "mips"
  )
})

# Test quiet = FALSE outputs messages
test_that("java_download outputs messages when quiet = FALSE", {
  local_cache_path <- withr::local_tempdir()

  local_mocked_bindings(
    java_valid_versions = function(...) c("8", "11", "17", "21")
  )

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      if (grepl("\\.md5$", destfile)) {
        writeLines("dummymd5checksum", destfile)
      } else {
        writeLines("dummy content", destfile)
      }
    },
    .package = "curl"
  )

  local_mocked_bindings(
    md5sum = function(files) setNames("dummymd5checksum", files),
    .package = "tools"
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
