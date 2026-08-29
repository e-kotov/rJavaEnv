test_that("list_temurin_versions_impl handles valid data", {
  skip_on_cran()

  local_mocked_bindings(
    java_valid_major_versions_temurin = function(...) c(17, 21),
    read_json_url = function(url, ...) {
      if (grepl("assets/latest/17/", url)) {
        return(list(
          list(
            binary = list(package = list(link = "https://example.com/17.0.9.tar.gz")),
            version_data = list(
              semver = "17.0.9+9",
              openjdk_version = "17.0.9+9"
            )
          ),
          list(
            binary = list(package = list(link = "https://example.com/17.0.10.tar.gz")),
            version_data = list(
              semver = "17.0.10+1",
              openjdk_version = "17.0.10+1"
            )
          )
        ))
      }
      if (grepl("assets/latest/21/", url)) {
        return(list(
          list(
            binary = list(package = list(link = "https://example.com/21.0.8.tar.gz")),
            version_data = list(
              semver = "21.0.8+9",
              openjdk_version = "21.0.8+9"
            )
          )
        ))
      }
      stop("Unexpected URL")
    },
    .package = "rJavaEnv"
  )

  res <- list_temurin_versions_impl(platform = "linux", arch = "x64")

  expect_s3_class(res, "data.frame")
  expect_true(nrow(res) >= 3)
  expect_equal(res$vendor[1], "Temurin")
  expect_equal(res$backend[1], "native")
})

test_that("list_temurin_versions_impl handles empty major versions", {
  skip_on_cran()
  local_mocked_bindings(
    java_valid_major_versions_temurin = function(...) NULL,
    .package = "rJavaEnv"
  )
  res <- list_temurin_versions_impl("linux", "x64")
  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 0)
})

test_that("list_temurin_versions_impl handles API error gracefully", {
  skip_on_cran()
  local_mocked_bindings(
    java_valid_major_versions_temurin = function(...) c(21),
    read_json_url = function(...) stop("API Error"),
    .package = "rJavaEnv"
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

test_that("list_sdkman_versions_impl parses CSV and resolves vendor display names", {
  skip_on_cran()

  mock_csv <- "11.0.29-ms,17.0.17-librca,21.0.30-sapmchn,21.0.12-amzn"

  local_mocked_bindings(
    java_config = function(...) {
      list(
        platform_map = list(),
        arch_map = list(),
        vendor_reverse_map = list(
          ms = "Microsoft",
          librca = "Liberica",
          sapmchn = "SAP Machine",
          amzn = "Corretto"
        )
      )
    },
    rje_read_lines = function(url, ...) {
      if (grepl("/versions/all", url)) {
        return(mock_csv)
      }
      character(0)
    }
  )

  res <- list_sdkman_versions_impl("linux", "x64")

  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 4)
  expect_equal(ncol(res), 8)
  expect_true("Microsoft" %in% res$vendor)
  expect_true("Liberica" %in% res$vendor)
  expect_true("SAP Machine" %in% res$vendor)
  expect_true("Corretto" %in% res$vendor)
  expect_true("21.0.12-amzn" %in% res$identifier)
})

test_that("list_sdkman_versions_impl parses 4-column table fallback", {
  skip_on_cran()

  mock_4col_table <- c(
    "================================================================================",
    " Available Java Versions for Linux 64bit                                        ",
    "================================================================================",
    " Vendor         | Use | Version            | Identifier                         ",
    "--------------------------------------------------------------------------------",
    " Temurin        |     | 21.0.2             | 21.0.2-tem                         ",
    " Amazon         |  +  | 17.0.10            | 17.0.10-amzn                       ",
    "================================================================================"
  )

  local_mocked_bindings(
    java_config = function(...) {
      list(
        platform_map = list(),
        arch_map = list(),
        vendor_reverse_map = list(tem = "Temurin", amzn = "Corretto")
      )
    },
    rje_read_lines = function(url, ...) {
      if (grepl("/versions/all", url)) {
        return("") # Empty HTTP 200
      }
      if (grepl("/versions/list", url)) {
        return(mock_4col_table)
      }
      character(0)
    }
  )

  res <- list_sdkman_versions_impl("linux", "x64")

  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 2)
  expect_true("Temurin" %in% res$vendor)
  expect_true("Corretto" %in% res$vendor)
  expect_true("21.0.2-tem" %in% res$identifier)
})

test_that("list_sdkman_versions_impl handles empty config/error by returning 8-col 0-row df", {
  skip_on_cran()
  local_mocked_bindings(
    java_config = function(...) NULL
  )
  res <- list_sdkman_versions_impl("linux", "x64")
  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 0)
  expect_equal(ncol(res), 8)
  expect_equal(
    names(res),
    c("backend", "vendor", "major", "version", "platform", "arch", "identifier", "checksum_available")
  )

  # Also test when sdkman_fetch_identifiers errors
  local_mocked_bindings(
    java_config = function(...) {
      list(platform_map = list(), arch_map = list(), vendor_reverse_map = list())
    },
    sdkman_fetch_identifiers = function(...) stop("Network failure")
  )
  res_err <- list_sdkman_versions_impl("linux", "x64")
  expect_s3_class(res_err, "data.frame")
  expect_equal(nrow(res_err), 0)
  expect_equal(ncol(res_err), 8)
})
