test_that("java_urls_load loads JSON correctly", {
  # Real test of the JSON file included in the package
  urls <- rJavaEnv:::java_urls_load()
  expect_type(urls, "list")
  expect_true("Corretto" %in% names(urls))
})

test_that("urls_test_all checks URLs without network", {
  # Mock internal loader to return small subset
  local_mocked_bindings(
    java_urls_load = function() {
      list(
        TestDist = list(
          linux = list(x64 = "http://example.com/jdk-{version}.tar.gz")
        )
      )
    },
    .package = "rJavaEnv"
  )

  # Mock curl to avoid network
  local_mocked_bindings(
    curl_fetch_memory = function(...) list(status_code = 200),
    .package = "curl"
  )

  res <- rJavaEnv:::urls_test_all()
  expect_type(res, "list")
  expect_equal(res[["TestDist-linux-x64"]]$status, 200)
})

test_that("java_version_check_rscript function exists", {
  # We cannot safely test this function without loading rJava, which crashes when
  # Java is not configured. Testing the error path is also unsafe because mocking
  # base functions like Sys.setenv or list.files interferes with testthat's own operations.
  # Instead, we just verify the function exists and has correct structure.

  expect_true(exists(
    "java_version_check_rscript",
    where = asNamespace("rJavaEnv")
  ))
  expect_type(rJavaEnv:::java_version_check_rscript, "closure")
})

test_that("rje_readline passes prompt to base::readline", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  # This test verifies the wrapper exists and is mockable
  # We mock base::readline to capture the call
  captured_prompt <- NULL
  local_mocked_bindings(
    readline = function(prompt = "") {
      captured_prompt <<- prompt
      "mocked_response"
    },
    .package = "base"
  )

  result <- rJavaEnv:::rje_readline(prompt = "Enter value: ")

  expect_equal(captured_prompt, "Enter value: ")
  expect_equal(result, "mocked_response")
})
