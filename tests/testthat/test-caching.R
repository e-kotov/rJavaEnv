test_that("java_check_version_cmd caching works", {
  skip_on_cran()

  # Mock the environment to simulate Java presence
  withr::local_envvar(JAVA_HOME = "/mock/java")

  # Mock the internal implementation to return a fixed result
  local_mocked_bindings(
    ._java_version_check_impl_original = function(...) {
      list(
        major_version = "17",
        java_home = "/mock/java",
        java_path = "/mock/java/bin/java",
        java_version_output = "openjdk 17.0.1 2021-10-19"
      )
    },
    .package = "rJavaEnv"
  )

  v1 <- java_check_version_cmd(quiet = TRUE)
  expect_type(v1, "character")
  expect_equal(v1, "17")

  # Second call should return same cached result (functionally identical)
  v2 <- java_check_version_cmd(quiet = TRUE)
  expect_identical(v1, v2)
})

test_that("java_find_system caching works", {
  skip_on_cran()

  # Mock java_find_system implementation
  local_mocked_bindings(
    java_find_system = function(...) {
      data.frame(
        version = c("17.0.1", "11.0.2"),
        path = c("/usr/lib/jvm/java-17", "/usr/lib/jvm/java-11"),
        stringsAsFactors = FALSE
      )
    },
    .package = "rJavaEnv"
  )

  r1 <- java_find_system(quiet = TRUE)
  r2 <- java_find_system(quiet = TRUE)

  # Multiple calls return identical results
  expect_identical(r1, r2)
  expect_s3_class(r1, "data.frame")
})

test_that("quiet parameter doesn't affect cache", {
  skip_on_cran()

  # Mock the environment to simulate Java presence
  withr::local_envvar(JAVA_HOME = "/mock/java")

  # Mock the internal implementation to return a fixed result
  local_mocked_bindings(
    ._java_version_check_impl_original = function(...) {
      list(
        major_version = "17",
        java_home = "/mock/java",
        java_path = "/mock/java/bin/java",
        java_version_output = "openjdk 17.0.1 2021-10-19"
      )
    },
    .package = "rJavaEnv"
  )

  v1 <- java_check_version_cmd(quiet = TRUE)
  v2 <- suppressMessages(java_check_version_cmd(quiet = FALSE))

  expect_identical(v1, v2)
})

test_that("java_check_version_rjava caching works", {
  skip_on_cran()

  local_mocked_bindings(
    # Mocking check for rJava install
    find.package = function(...) "path/to/rJava",
    .package = "base"
  )

  # Spy on calls
  call_count <- 0

  local_mocked_bindings(
    ._java_version_check_rjava_impl_original = function(...) {
      call_count <<- call_count + 1
      list(major_version = "17", output = "version 17")
    },
    .package = "rJavaEnv"
  )

  # Reset cache
  memoise::forget(rJavaEnv:::._java_version_check_rjava_impl)

  withr::with_envvar(c("JAVA_HOME" = "/mock/java"), {
    # First call with .use_cache = TRUE
    java_check_version_rjava(.use_cache = TRUE)
    expect_equal(call_count, 1)

    # Second call with .use_cache = TRUE should use cache
    java_check_version_rjava(.use_cache = TRUE)
    expect_equal(call_count, 1) # Should not increment

    # Call with .use_cache = FALSE should bypass cache
    java_check_version_rjava(.use_cache = FALSE)
    expect_equal(call_count, 2)
  })
})

test_that("java_check_version_rjava uses different cache for different java_home", {
  skip_on_cran()
  local_mocked_bindings(
    find.package = function(...) "path/to/rJava",
    .package = "base"
  )

  call_count <- 0
  local_mocked_bindings(
    ._java_version_check_rjava_impl_original = function(java_home) {
      call_count <<- call_count + 1
      list(major_version = "17", output = paste("version 17 at", java_home))
    },
    .package = "rJavaEnv"
  )

  memoise::forget(rJavaEnv:::._java_version_check_rjava_impl)

  java_check_version_rjava("path1", .use_cache = TRUE)
  expect_equal(call_count, 1)

  java_check_version_rjava("path2", .use_cache = TRUE)
  expect_equal(call_count, 2)

  java_check_version_rjava("path1", .use_cache = TRUE)
  expect_equal(call_count, 2) # used cache
})
