# tests/testthat/test-java_env_version_impl.R

test_that("._java_version_check_impl_original parses java -version output", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  # Create mock Java installation
  temp_java <- withr::local_tempdir()
  bin_dir <- file.path(temp_java, "bin")
  dir.create(bin_dir, recursive = TRUE)

  # Mock system2 to return known version string
  local_mocked_bindings(
    system2 = function(command, args, ...) {
      if (any(grepl("-version", args))) {
        return(
          "openjdk version \"21.0.1\" 2023-10-17\nOpenJDK Runtime Environment"
        )
      }
      character(0)
    },
    .package = "base"
  )

  result <- rJavaEnv:::._java_version_check_impl_original(temp_java)

  expect_type(result, "list")
  expect_equal(result$major_version, "21")
})

test_that("._java_version_check_impl handles command-line java version check", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  temp_java <- withr::local_tempdir()

  local_mocked_bindings(
    ._java_version_check_impl_original = function(...) {
      list(major_version = "17", java_home = "/mock")
    },
    .package = "rJavaEnv"
  )

  result <- rJavaEnv:::._java_version_check_impl(temp_java)
  expect_equal(result$major_version, "17")
})

test_that("._java_version_check_rjava_impl handles rJava-based version check", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  temp_java <- withr::local_tempdir()

  local_mocked_bindings(
    ._java_version_check_rjava_impl_original = function(...) {
      list(major_version = "11", output = "mock")
    },
    .package = "rJavaEnv"
  )

  result <- rJavaEnv:::._java_version_check_rjava_impl(temp_java)
  expect_equal(result$major_version, "11")
})
