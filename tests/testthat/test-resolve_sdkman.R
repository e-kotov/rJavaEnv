test_that("resolve_sdkman_metadata uses identifier fast-path", {
  skip_on_cran()

  local_mocked_bindings(
    # Mock config
    java_config = function(...) {
      list(
        platform_map = list(),
        arch_map = list(),
        vendor_map = list(Temurin = "tem")
      )
    },
    # Mock curl to return the final URL
    rje_curl_fetch_memory = function(url, ...) {
      list(
        url = "https://example.com/download.tar.gz",
        content = charToRaw("") # Body ignored if url present
      )
    },
    # Ensure regular lookup is NOT called by making it error if called
    rje_read_lines = function(...) stop("Should not be called in fast path"),
    .package = "rJavaEnv"
  )

  # 1. Identifier provided directly
  res <- resolve_sdkman_metadata("21.0.2-tem", "Temurin", "linux", "x64")

  expect_equal(res$semver, "21.0.2-tem")
  expect_equal(res$download_url, "https://example.com/download.tar.gz")
  expect_null(res$checksum)
})


test_that("resolve_sdkman_metadata resolves version from list", {
  skip_on_cran()

  mock_lines <- c(
    " Vendor        | Use | Version      | Dist    | Status | Identifier             ",
    "--------------------------------------------------------------------------------",
    " Temurin       |     | 21.0.2       | tem     |        | 21.0.2-tem             "
  )

  local_mocked_bindings(
    java_config = function(...) {
      list(
        platform_map = list(),
        arch_map = list(),
        vendor_map = list(Temurin = "tem")
      )
    },
    rje_read_lines = function(...) mock_lines,
    rje_curl_fetch_memory = function(...) {
      list(url = "https://d.com/file.tar.gz")
    }
  )

  # Lookup by version number (not identifier)
  res <- resolve_sdkman_metadata("21.0.2", "Temurin", "linux", "x64")

  expect_equal(res$semver, "21.0.2-tem")
  expect_equal(res$version, "21.0.2")
})

test_that("resolve_sdkman_metadata handles missing mapping", {
  skip_on_cran()
  local_mocked_bindings(
    java_config = function(...) list(vendor_map = list())
  )

  expect_error(
    resolve_sdkman_metadata("21", "UnknownDist", "linux", "x64"),
    "No SDKMAN mapping"
  )
})

test_that("resolve_sdkman_metadata handles not found version", {
  skip_on_cran()
  local_mocked_bindings(
    java_config = function(...) list(vendor_map = list(Temurin = "tem")),
    rje_read_lines = function(...) character(0) # Empty output
  )

  expect_error(
    resolve_sdkman_metadata("99", "Temurin", "linux", "x64"),
    "No SDKMAN identifier"
  )
})

test_that("resolve_sdkman_metadata handles broker redirect via body", {
  skip_on_cran()

  local_mocked_bindings(
    java_config = function(...) list(vendor_map = list(Temurin = "tem")),
    # simulate direct identifier usage to skip list lookup
    # Need to export is_sdkman_identifier or use package internal access?
    # It is internal, so we rely on mocking is_sdkman_identifier if needed,
    # but here we just pass an identifier "21-tem" which is_sdkman_identifier should match
    rje_curl_fetch_memory = function(...) {
      list(
        url = NULL, # No Location header
        content = charToRaw("https://body-redirect.com/file.zip")
      )
    }
  )

  res <- resolve_sdkman_metadata("21.0.2-tem", "Temurin", "linux", "x64")
  expect_equal(res$download_url, "https://body-redirect.com/file.zip")
})
