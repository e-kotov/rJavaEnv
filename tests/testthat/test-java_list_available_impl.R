test_that("list_temurin_versions_impl handles valid data", {
  skip_on_cran()

  # Mock list of major versions
  local_mocked_bindings(
    java_valid_major_versions_temurin = function() c(17, 21),
    read_json_url = function(url, ...) {
      # Return simplified structure as list of lists
      list(
        list(
          version_data = list(
            semver = "17.0.9+9",
            openjdk_version = "17.0.9+9"
          )
        ),
        list(
          version_data = list(
            semver = "17.0.10+1",
            openjdk_version = "17.0.10+1"
          )
        )
      )
    },
    list_temurin_versions_impl = list_temurin_versions_impl
  )

  # Run
  res <- list_temurin_versions_impl(platform = "linux", arch = "x64")

  expect_s3_class(res, "data.frame")
  expect_true(nrow(res) >= 2) # 2 versions for 17, plus whatever mocked for 21 if loop runs
  expect_equal(res$vendor[1], "Temurin")
  expect_equal(res$backend[1], "native")
})

test_that("list_temurin_versions_impl handles empty major versions", {
  skip_on_cran()
  local_mocked_bindings(
    java_valid_major_versions_temurin = function() NULL
  )
  res <- list_temurin_versions_impl("linux", "x64")
  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 0)
})

test_that("list_temurin_versions_impl handles API error gracefully", {
  skip_on_cran()
  local_mocked_bindings(
    java_valid_major_versions_temurin = function() c(21),
    read_json_url = function(...) stop("API Error")
  )
  res <- list_temurin_versions_impl("linux", "x64")
  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 0)
})

test_that("list_corretto_versions_impl handles valid data", {
  skip_on_cran()

  mock_index <- list(
    linux = list(
      x64 = list(
        jdk = list(
          "21" = list(
            "tar.gz" = list(
              resource = "downloads/21.0.1.12.1/amazon-corretto-21.0.1.12.1-linux-x64.tar.gz"
            )
          )
        )
      )
    )
  )

  local_mocked_bindings(
    java_config = function(...) {
      list(index_url = "dummy")
    },
    read_json_url = function(...) mock_index
  )

  res <- list_corretto_versions_impl("linux", "x64")
  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 1)
  expect_equal(res$vendor, "Corretto")
  expect_equal(res$version, "21.0.1.12.1")
})

test_that("list_corretto_versions_impl handles unmapped platform", {
  # platform "unknown" -> returns empty
  res <- list_corretto_versions_impl("unknown_os", "x64")
  expect_equal(nrow(res), 0)
})

test_that("list_zulu_versions_impl handles valid data", {
  skip_on_cran()
  mock_data <- list(
    list(
      java_version = list(21, 0, 1),
      package_uuid = "uuid-123"
    )
  )

  local_mocked_bindings(
    read_json_url = function(...) mock_data
  )

  res <- list_zulu_versions_impl("linux", "x64")
  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 1)
  expect_equal(res$vendor, "Zulu")
  expect_equal(res$version, "21.0.1")
})

test_that("list_sdkman_versions_impl parses SDKMAN output", {
  skip_on_cran()

  # Sample output from SDKMAN list
  # |   | 21.0.2      | tem     |     | 21.0.2-tem          |
  # | + | 17.0.10     | amzn    |     | 17.0.10-amzn        |
  mock_lines <- c(
    "================================================================================",
    " Available Java Versions for Linux 64bit                                        ",
    "================================================================================",
    " Vendor        | Use | Version      | Dist    | Status | Identifier             ",
    "--------------------------------------------------------------------------------",
    " Temurin       |     | 21.0.2       | tem     |        | 21.0.2-tem             ",
    " Amazon        |  +  | 17.0.10      | amzn    |        | 17.0.10-amzn           ",
    "================================================================================"
  )

  local_mocked_bindings(
    java_config = function(...) {
      list(
        platform_map = list(),
        arch_map = list(),
        vendor_map = list(Temurin = "tem", Corretto = "amzn")
      )
    },
    rje_read_lines = function(...) mock_lines
  )

  res <- list_sdkman_versions_impl("linux", "x64")

  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 2)
  expect_true("Temurin" %in% res$vendor)
  expect_true("Corretto" %in% res$vendor) # Mapped from amzn

  # check identifier extraction
  expect_true("21.0.2-tem" %in% res$identifier)
})

test_that("list_sdkman_versions_impl handles empty config/error", {
  skip_on_cran()
  local_mocked_bindings(
    java_config = function(...) NULL
  )
  res <- list_sdkman_versions_impl("linux", "x64")
  expect_equal(nrow(res), 0)
})
