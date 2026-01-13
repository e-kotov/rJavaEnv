# tests/testthat/test-java_manage_installed_cache_unit.R

test_that("java_list_installed returns empty when no installed folder", {
  local_cache <- withr::local_tempdir()

  result <- java_list_installed(cache_path = local_cache)

  expect_equal(result, character(0))
})

test_that("java_list_installed returns data.frame with correct structure", {
  local_cache <- withr::local_tempdir()

  # Create proper nested structure (new): installed/platform/arch/distribution/backend/version
  # Need bin/ directory for leaf detection
  inst_path <- file.path(
    local_cache,
    "installed",
    "linux",
    "x64",
    "Corretto",
    "native",
    "21"
  )
  dir.create(file.path(inst_path, "bin"), recursive = TRUE)

  result <- java_list_installed(
    cache_path = local_cache,
    output = "data.frame"
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_true("platform" %in% names(result))
  expect_true("arch" %in% names(result))
  expect_true("distribution" %in% names(result))
  expect_true("backend" %in% names(result))
  expect_true("version" %in% names(result))
  expect_equal(result$version[1], "21")
  expect_equal(result$distribution[1], "Corretto")
  expect_equal(result$backend[1], "native")
})

test_that("java_list_installed handles multiple installations", {
  local_cache <- withr::local_tempdir()

  # Create two installations with new structure (need bin/ for detection)
  inst1 <- file.path(
    local_cache,
    "installed",
    "linux",
    "x64",
    "Corretto",
    "native",
    "17"
  )
  dir.create(file.path(inst1, "bin"), recursive = TRUE)
  inst2 <- file.path(
    local_cache,
    "installed",
    "macos",
    "aarch64",
    "Temurin",
    "sdkman",
    "21"
  )
  dir.create(file.path(inst2, "bin"), recursive = TRUE)

  result <- java_list_installed(
    cache_path = local_cache,
    output = "vector"
  )

  expect_length(result, 2)
})

test_that("java_list_installed handles legacy structure with backwards compatibility", {
  local_cache <- withr::local_tempdir()

  # Create legacy structure: installed/platform/arch/version with bin/
  inst_path <- file.path(local_cache, "installed", "linux", "x64", "17")
  dir.create(file.path(inst_path, "bin"), recursive = TRUE)

  result <- java_list_installed(
    cache_path = local_cache,
    output = "data.frame"
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$version[1], "17")
  expect_equal(result$distribution[1], "unknown")
  expect_equal(result$backend[1], "unknown")
})
