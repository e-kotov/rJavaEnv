sdkman_contract_skip <- function() {
  testthat::skip_on_cran()
  testthat::skip_if_offline()
  testthat::skip_if_not(
    Sys.getenv("RUN_SDKMAN_CONTRACT_TESTS") == "TRUE",
    "Set RUN_SDKMAN_CONTRACT_TESTS='TRUE' to probe the live SDKMAN API."
  )
}

test_that("sdkman_fetch_identifiers() returns usable ids from the live API", {
  sdkman_contract_skip()

  ids <- sdkman_fetch_identifiers("linuxx64")
  expect_gt(length(ids), 20L)

  parsed <- sdkman_parse_identifiers(ids, "linux", "x64")
  expect_s3_class(parsed, "data.frame")
  expect_named(
    parsed,
    c(
      "backend",
      "vendor",
      "major",
      "version",
      "platform",
      "arch",
      "identifier",
      "checksum_available"
    )
  )
  expect_false(any(is.na(parsed$major)))
  expect_true(any(grepl("-amzn$", parsed$identifier)))
})

test_that("the /versions/list fallback resolves Corretto 21 end to end", {
  sdkman_contract_skip()

  # Force the fallback by stubbing /versions/all to ""
  local_mocked_bindings(
    rje_read_lines = function(url, ...) {
      if (grepl("/versions/all", url)) {
        return("") # Empty HTTP 200 simulation
      }
      # Let real rje_read_lines execute for other URLs (e.g. /versions/list)
      readLines(url, warn = FALSE)
    }
  )

  build <- resolve_sdkman_metadata("21", "Corretto", "linux", "x64")
  expect_s3_class(build, "java_build")
  expect_equal(build$backend, "sdkman")
  expect_equal(build$vendor, "Corretto")
  expect_match(build$semver, "^21\\..*-amzn$")
  expect_match(build$download_url, "^https?://")
})
