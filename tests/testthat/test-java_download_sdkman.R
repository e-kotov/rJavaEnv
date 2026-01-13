test_that("SDKMAN backend warns about missing checksum", {
  # Create a mock SDKMAN build with no checksum
  mock_build <- java_build(
    vendor = "Corretto",
    version = "21",
    major = 21,
    platform = "linux",
    arch = "x64",
    download_url = "https://example.com/mock-java.tar.gz",
    filename = "mock-java.tar.gz",
    checksum = NULL,
    checksum_type = NULL,
    backend = "sdkman"
  )

  # Create a temp file to simulate download
  temp_file <- tempfile(fileext = ".tar.gz")
  on.exit(unlink(temp_file), add = TRUE)

  # Mock curl::curl_download to just create an empty file
  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      writeLines("mock content", destfile)
      invisible(destfile)
    },
    .package = "curl"
  )

  # Test that download_java_with_checksum emits warning for SDKMAN
  expect_message(
    download_java_with_checksum(
      mock_build,
      temp_file,
      quiet = FALSE,
      force = TRUE
    ),
    "Skipping checksum"
  )
})

test_that("SDKMAN build object has correct structure", {
  mock_build <- java_build(
    vendor = "Temurin",
    version = "17",
    major = 17,
    platform = "macos",
    arch = "aarch64",
    download_url = "https://example.com/temurin.tar.gz",
    filename = "temurin-17.tar.gz",
    checksum = NULL,
    checksum_type = NULL,
    backend = "sdkman"
  )

  expect_equal(mock_build$backend, "sdkman")
  expect_null(mock_build$checksum)
  expect_null(mock_build$checksum_type)
  expect_equal(mock_build$vendor, "Temurin")
})
