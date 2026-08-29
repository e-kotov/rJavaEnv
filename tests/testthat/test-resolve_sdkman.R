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


test_that("resolve_sdkman_metadata resolves version from CSV /versions/all endpoint", {
  skip_on_cran()

  mock_csv <- "11.0.9-amzn,11.0.32-amzn,21.0.12-amzn,21.0.11.crac-zulu,21.0.12+1.1-zulu"

  local_mocked_bindings(
    java_config = function(...) {
      list(
        platform_map = list(),
        arch_map = list(),
        vendor_map = list(Corretto = "amzn", Zulu = "zulu", Temurin = "tem"),
        vendor_reverse_map = list(amzn = "Corretto", zulu = "Zulu", tem = "Temurin")
      )
    },
    rje_read_lines = function(url, ...) {
      if (grepl("/versions/all", url)) {
        return(mock_csv)
      }
      character(0)
    },
    rje_curl_fetch_memory = function(...) {
      list(url = "https://d.com/file.tar.gz")
    }
  )

  # 1. Major version 21 resolves correctly
  res_21 <- resolve_sdkman_metadata("21", "Corretto", "linux", "x64")
  expect_equal(res_21$semver, "21.0.12-amzn")

  # 2. Integer component sorting: 11.0.32 must beat 11.0.9
  res_11 <- resolve_sdkman_metadata("11", "Corretto", "linux", "x64")
  expect_equal(res_11$semver, "11.0.32-amzn")

  # 3. Specialised build (.crac) excluded for generic major version request
  res_zulu <- resolve_sdkman_metadata("21", "Zulu", "linux", "x64")
  expect_equal(res_zulu$semver, "21.0.12+1.1-zulu")

  # 4. Specialised build included when explicitly requested
  res_crac <- resolve_sdkman_metadata("21.0.11.crac", "Zulu", "linux", "x64")
  expect_equal(res_crac$semver, "21.0.11.crac-zulu")
})

test_that("resolve_sdkman_metadata falls back to 4-column ASCII table when /versions/all is empty", {
  skip_on_cran()

  mock_4col_table <- c(
    "================================================================================",
    " Available Java Versions for Linux 64bit                                        ",
    "================================================================================",
    " Vendor         | Use | Version            | Identifier                         ",
    "--------------------------------------------------------------------------------",
    " Corretto       |     | 21.0.12            | 21.0.12-amzn                       ",
    "                |     | 17.0.20            | 17.0.20-amzn                       ",
    "================================================================================"
  )

  local_mocked_bindings(
    java_config = function(...) {
      list(
        platform_map = list(),
        arch_map = list(),
        vendor_map = list(Corretto = "amzn"),
        vendor_reverse_map = list(amzn = "Corretto")
      )
    },
    rje_read_lines = function(url, ...) {
      if (grepl("/versions/all", url)) {
        return("") # Empty HTTP 200 response
      }
      if (grepl("/versions/list", url)) {
        return(mock_4col_table)
      }
      character(0)
    },
    rje_curl_fetch_memory = function(...) {
      list(url = "https://d.com/file.tar.gz")
    }
  )

  res <- resolve_sdkman_metadata("21", "Corretto", "linux", "x64")
  expect_equal(res$semver, "21.0.12-amzn")
})

test_that("resolve_sdkman_metadata handles missing mapping", {
  skip_on_cran()
  local_mocked_bindings(
    java_config = function(...) list(vendor_map = list(), vendor_reverse_map = list())
  )

  expect_error(
    resolve_sdkman_metadata("21", "UnknownDist", "linux", "x64"),
    "No SDKMAN mapping"
  )
})

test_that("resolve_sdkman_metadata handles not found version with classed error", {
  skip_on_cran()
  local_mocked_bindings(
    java_config = function(...) {
      list(
        platform_map = list(),
        arch_map = list(),
        vendor_map = list(Temurin = "tem"),
        vendor_reverse_map = list(tem = "Temurin")
      )
    },
    rje_read_lines = function(...) character(0) # Empty output
  )

  expect_error(
    resolve_sdkman_metadata("99", "Temurin", "linux", "x64"),
    class = "rJavaEnv_sdkman_unavailable"
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
