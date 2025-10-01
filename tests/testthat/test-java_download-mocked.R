# Mocked unit tests for java_download()
test_that("java_download handles successful download and checksum", {
  local_cache_path <- withr::local_tempdir()

  # MOCK THE SLOW NETWORK CALL
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

  expect_silent(
    result_path <- java_download(
      version = "21",
      cache_path = local_cache_path,
      quiet = TRUE
    )
  )
  expect_true(file.exists(result_path))
})

test_that("java_download aborts on MD5 checksum mismatch", {
  local_cache_path <- withr::local_tempdir()

  # MOCK THE SLOW NETWORK CALL
  local_mocked_bindings(
    java_valid_versions = function(...) c("8", "11", "17", "21")
  )

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      if (grepl("\\.md5$", destfile)) {
        writeLines("expected_checksum", destfile)
      } else {
        writeLines("some content", destfile)
      }
    },
    .package = "curl"
  )

  local_mocked_bindings(
    md5sum = function(files) setNames("actual_checksum_mismatch", files),
    .package = "tools"
  )

  expect_error(
    java_download(version = "21", cache_path = local_cache_path, quiet = TRUE),
    "MD5 checksum mismatch"
  )
})

test_that("java_download skips download if file exists and force is FALSE", {
  local_cache_path <- withr::local_tempdir()
  dest_dir <- file.path(local_cache_path, "distrib")
  dir.create(dest_dir, recursive = TRUE)

  # MOCK THE SLOW NETWORK CALL
  local_mocked_bindings(
    java_valid_versions = function(...) c("8", "11", "17", "21")
  )

  platform <- platform_detect()$os
  arch <- platform_detect()$arch
  java_urls <- java_urls_load()
  url_template <- java_urls[["Corretto"]][[platform]][[arch]]
  url <- gsub("\\{version\\}", "21", url_template)
  expected_file_path <- file.path(dest_dir, basename(url))
  file.create(expected_file_path)

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

  # MOCK THE SLOW NETWORK CALL
  local_mocked_bindings(
    java_valid_versions = function(...) c("8", "11", "17", "21")
  )

  platform <- platform_detect()$os
  arch <- platform_detect()$arch
  java_urls <- java_urls_load()
  url_template <- java_urls[["Corretto"]][[platform]][[arch]]
  url <- gsub("\\{version\\}", "21", url_template)
  expected_file_path <- file.path(dest_dir, basename(url))
  writeLines("old content", expected_file_path)

  curl_call_count <- 0
  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      curl_call_count <<- curl_call_count + 1
      if (grepl("\\.md5$", destfile)) {
        writeLines("new_checksum", destfile)
      } else {
        writeLines("new content", destfile)
      }
    },
    .package = "curl"
  )

  local_mocked_bindings(
    md5sum = function(files) setNames("new_checksum", files),
    .package = "tools"
  )

  java_download(
    version = "21",
    cache_path = local_cache_path,
    platform = platform,
    arch = arch,
    quiet = TRUE,
    force = TRUE
  )

  expect_equal(curl_call_count, 2)
  expect_equal(readLines(expected_file_path), "new content")
})
