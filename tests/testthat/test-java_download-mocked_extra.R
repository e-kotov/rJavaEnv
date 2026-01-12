# Mocked download tests for Temurin and Zulu
test_that("java_download (Temurin) handles successful download and checksum", {
  local_cache_path <- withr::local_tempdir()

  # Mock curl fetch for Temurin metadata
  local_mocked_bindings(
    curl_fetch_memory = function(url, ...) {
      if (grepl("adoptium", url)) {
        json_content <- '[{
          "binary": {
            "package": {
              "link": "https://example.com/temurin.tar.gz",
              "checksum": "mocked_sha256"
            }
          },
          "release_name": "jdk-21.0.0+35",
          "version_data": {
            "semver": "21.0.0+35"
          }
        }]'
        return(list(content = charToRaw(json_content), status_code = 200))
      }
      stop(paste("Unexpected URL:", url))
    },
    .package = "curl"
  )

  # Mock curl download for the actual file
  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      writeLines("dummy content", destfile)
    },
    .package = "curl"
  )

  # Mock digest for SHA256
  local_mocked_bindings(
    digest = function(...) "mocked_sha256",
    .package = "digest"
  )

  expect_silent(
    result_path <- java_download(
      version = "21",
      distribution = "Temurin",
      cache_path = local_cache_path,
      platform = "linux",
      arch = "x64",
      quiet = TRUE
    )
  )

  expect_true(file.exists(result_path))
  expect_true(grepl("temurin-21-linux-x64.tar.gz", basename(result_path)))
})

test_that("java_download (Zulu) handles successful download and checksum", {
  local_cache_path <- withr::local_tempdir()

  # Mock curl fetch for Zulu metadata
  local_mocked_bindings(
    curl_fetch_memory = function(url, ...) {
      if (grepl("azul", url)) {
        json_content <- '[{
          "download_url": "https://cdn.azul.com/zulu.tar.gz",
          "sha256_hash": "mocked_sha256",
          "java_version": [21, 0, 0]
        }]'
        return(list(content = charToRaw(json_content), status_code = 200))
      }
      stop(paste("Unexpected URL:", url))
    },
    .package = "curl"
  )

  # Mock curl download for the actual file
  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      writeLines("dummy content", destfile)
    },
    .package = "curl"
  )

  # Mock digest for SHA256
  local_mocked_bindings(
    digest = function(...) "mocked_sha256",
    .package = "digest"
  )

  expect_silent(
    result_path <- java_download(
      version = "21",
      distribution = "Zulu",
      cache_path = local_cache_path,
      platform = "linux",
      arch = "x64",
      quiet = TRUE
    )
  )

  expect_true(file.exists(result_path))
  expect_true(grepl("zulu-21-linux-x64.tar.gz", basename(result_path)))
})
