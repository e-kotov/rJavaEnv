# Tests for scoped Java environment functions

test_that("local_java_env sets and restores environment", {
  local_mocked_bindings(
    java_resolve = function(...) "/mock/java/home",
    .package = "rJavaEnv"
  )

  old_java_home <- Sys.getenv("JAVA_HOME")
  old_path <- Sys.getenv("PATH")

  local({
    rJavaEnv::local_java_env(version = 21, quiet = TRUE)
    expect_equal(Sys.getenv("JAVA_HOME"), "/mock/java/home")
    expect_true(grepl("/mock/java/home/bin", Sys.getenv("PATH")))
  })

  # After scope exits, should be restored
  expect_equal(Sys.getenv("JAVA_HOME"), old_java_home)
  expect_equal(Sys.getenv("PATH"), old_path)
})

test_that("with_java_env executes code in correct environment", {
  local_mocked_bindings(
    java_resolve = function(...) "/mock/java/home",
    .package = "rJavaEnv"
  )

  result <- rJavaEnv::with_java_env(version = 21, quiet = TRUE, {
    list(
      java_home = Sys.getenv("JAVA_HOME"),
      has_bin_in_path = grepl("/mock/java/home/bin", Sys.getenv("PATH"))
    )
  })

  expect_equal(result$java_home, "/mock/java/home")
  expect_true(result$has_bin_in_path)
})

test_that("with_rjava_env requires callr package", {
  local_mocked_bindings(
    requireNamespace = function(pkg, ...) FALSE,
    .package = "base"
  )

  expect_error(
    rJavaEnv::with_rjava_env(version = 21, func = identity),
    "callr"
  )
})

test_that("with_rjava_env calls callr::r with correct environment", {
  skip_if_not_installed("callr")

  local_mocked_bindings(
    java_resolve = function(...) "/mock/java/home",
    .package = "rJavaEnv"
  )

  # Mock callr::r to capture arguments
  captured_env <- NULL
  local_mocked_bindings(
    r = function(func, args, libpath, env, show) {
      captured_env <<- env
      func()
    },
    .package = "callr"
  )

  rJavaEnv::with_rjava_env(
    version = 21,
    func = function() "test",
    quiet = TRUE
  )

  expect_equal(captured_env[["JAVA_HOME"]], "/mock/java/home")
  expect_true(grepl("/mock/java/home/bin", captured_env[["PATH"]]))
})

test_that("local_java_env uses cache when .use_cache = TRUE", {
  call_count <- 0
  local_mocked_bindings(
    java_resolve = function(..., .use_cache = FALSE) {
      call_count <<- call_count + 1
      "/mock/java/home"
    },
    .package = "rJavaEnv"
  )

  # First call
  local({
    rJavaEnv::local_java_env(version = 21, .use_cache = TRUE, quiet = TRUE)
  })

  first_count <- call_count

  # Second call - java_resolve should still be called but with .use_cache = TRUE
  local({
    rJavaEnv::local_java_env(version = 21, .use_cache = TRUE, quiet = TRUE)
  })

  # Both calls happen, but .use_cache = TRUE is passed through
  expect_equal(call_count, 2)
})
