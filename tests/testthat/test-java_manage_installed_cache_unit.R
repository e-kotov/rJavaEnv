# tests/testthat/test-java_manage_installed_cache_unit.R

test_that("java_list_installed_cache returns empty when no installed folder", {
  local_cache <- withr::local_tempdir()

  result <- java_list_installed_cache(cache_path = local_cache)

  expect_equal(result, character(0))
})

test_that("java_list_installed_cache returns data.frame with correct structure", {
  local_cache <- withr::local_tempdir()

  # Create proper nested structure: installed/platform/arch/version
  inst_path <- file.path(local_cache, "installed", "linux", "x64", "21")
  dir.create(inst_path, recursive = TRUE)

  result <- java_list_installed_cache(
    cache_path = local_cache,
    output = "data.frame"
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_true("platform" %in% names(result))
  expect_true("arch" %in% names(result))
  expect_true("version" %in% names(result))
  expect_equal(result$version[1], "21")
})

test_that("java_list_installed_cache handles multiple installations", {
  local_cache <- withr::local_tempdir()

  dir.create(
    file.path(local_cache, "installed", "linux", "x64", "17"),
    recursive = TRUE
  )
  dir.create(
    file.path(local_cache, "installed", "macos", "aarch64", "21"),
    recursive = TRUE
  )

  result <- java_list_installed_cache(
    cache_path = local_cache,
    output = "vector"
  )

  expect_length(result, 2)
})
