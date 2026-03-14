test_that("java_valid_major_versions_temurin returns package-validated versions", {
  skip_on_cran()
  skip_if_offline()

  versions <- java_valid_major_versions_temurin()

  expect_type(versions, "character")
  expect_true(length(versions) > 0)
  expect_true(any(c("11", "17", "21", "25") %in% versions))
})

test_that("java_valid_versions supports Temurin distribution", {
  skip_on_cran()
  skip_if_offline()

  versions <- java_valid_versions(distribution = "Temurin", force = TRUE)
  expect_type(versions, "character")
  expect_true(length(versions) > 0)
  expect_true(any(c("11", "17", "21", "25") %in% versions))
})
