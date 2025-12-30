# tests/testthat/test-java_manage_distrib_cache_unit.R

test_that("java_list_distrib_cache returns empty when no distrib folder exists", {
  local_cache <- withr::local_tempdir()
  withr::local_options(rJavaEnv.cache_path = local_cache)

  # No "distrib" folder created
  result <- java_list_distrib_cache(cache_path = local_cache)

  expect_equal(result, character(0))
})

test_that("java_list_distrib_cache returns data.frame with files", {
  local_cache <- withr::local_tempdir()
  dist_dir <- file.path(local_cache, "distrib")
  dir.create(dist_dir, recursive = TRUE)

  # Create fake distribution files
  f1 <- file.path(dist_dir, "amazon-corretto-21-x64-linux.tar.gz")
  f2 <- file.path(dist_dir, "amazon-corretto-17-x64-linux.tar.gz")
  f1_md5 <- paste0(f1, ".md5")
  file.create(f1, f2, f1_md5)

  result <- java_list_distrib_cache(
    cache_path = local_cache,
    output = "data.frame"
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2) # Excludes .md5 files
})

test_that("java_list_distrib_cache returns vector when requested", {
  local_cache <- withr::local_tempdir()
  dist_dir <- file.path(local_cache, "distrib")
  dir.create(dist_dir, recursive = TRUE)

  f1 <- file.path(dist_dir, "java.tar.gz")
  file.create(f1)

  result <- java_list_distrib_cache(cache_path = local_cache, output = "vector")

  expect_type(result, "character")
  expect_length(result, 1)
})
