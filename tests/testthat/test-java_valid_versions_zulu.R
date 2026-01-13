test_that("java_valid_major_versions_zulu returns versions", {
  skip_on_cran()
  skip_if_offline()

  # This tests the live API
  versions <- java_valid_major_versions_zulu()

  expect_type(versions, "character")
  expect_true(length(versions) > 0)
  # Basic checks for known LTS versions
  expect_true(any(c("8", "11", "17", "21") %in% versions))
})

test_that("java_valid_versions supports Zulu distribution", {
  skip_on_cran()
  skip_if_offline()

  versions <- java_valid_versions(distribution = "Zulu", force = TRUE)
  expect_type(versions, "character")
  expect_true(length(versions) > 0)
})
