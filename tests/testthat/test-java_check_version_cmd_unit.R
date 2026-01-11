# Unit tests for java_check_version_cmd and internal helpers

test_that("._java_version_check_impl_original handles macOS DYLD_LIBRARY_PATH logic", {
  skip_on_cran()

  # Mock Sys.info to return Darwin
  local_mocked_bindings(
    Sys.info = function() c(sysname = "Darwin"),
    .package = "base"
  )

  # Mock get_libjvm_path
  local_mocked_bindings(
    get_libjvm_path = function(home) {
      file.path(home, "lib", "server", "libjvm.dylib")
    },
    .package = "rJavaEnv"
  )

  # Mock java_env_set_session to prevent side effects
  local_mocked_bindings(
    java_env_set_session = function(...) TRUE,
    .package = "rJavaEnv"
  )

  # Mock system2
  local_mocked_bindings(
    system2 = function(command, args, ...) {
      # Check environment within the "subprocess"
      dyld <- Sys.getenv("DYLD_LIBRARY_PATH")
      java_home <- Sys.getenv("JAVA_HOME")

      # For verification purposes, return these values in the output
      return(c(
        paste0("DYLD_LIBRARY_PATH=", dyld),
        paste0("JAVA_HOME=", java_home),
        'openjdk version "21.0.1" 2023-10-17'
      ))
    },
    .package = "base"
  )

  # Mock file.exists logic
  local_mocked_bindings(
    file.exists = function(path) {
      # Always return true for this test
      return(TRUE)
    },
    .package = "base"
  )

  java_home_mock <- "/mock/java/home"

  result <- rJavaEnv:::._java_version_check_impl_original(
    java_home = java_home_mock
  )

  output_text <- paste(result$java_version_output, collapse = "\n")

  # Use regular expressions to match output
  expect_match(output_text, "/mock/java/home/lib/server")
  expect_match(output_text, "/mock/java/home")
  expect_match(result$major_version, "^21$")
})

test_that("._java_version_check_impl_original returns FALSE when java binary not found", {
  java_home_mock <- "/mock/java/home"

  local_mocked_bindings(
    java_env_set_session = function(...) TRUE,
    .package = "rJavaEnv"
  )

  # Mock file.exists to return FALSE for the java binary check
  local_mocked_bindings(
    file.exists = function(paths) {
      if (grepl("bin/java", paths)) {
        return(FALSE)
      }
      TRUE
    },
    .package = "base"
  )

  expect_false(rJavaEnv:::._java_version_check_impl_original(
    java_home = java_home_mock
  ))
})

test_that("._java_version_check_impl_original handles timeout (status 124)", {
  java_home_mock <- "/mock/java/home"

  local_mocked_bindings(
    java_env_set_session = function(...) TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    file.exists = function(...) TRUE,
    .package = "base"
  )

  local_mocked_bindings(
    system2 = function(...) {
      res <- character(0)
      attr(res, "status") <- 124
      res
    },
    .package = "base"
  )

  expect_false(rJavaEnv:::._java_version_check_impl_original(
    java_home = java_home_mock
  ))
})


test_that("._java_version_check_impl_original handles garbage output", {
  java_home_mock <- "/mock/java/home"

  local_mocked_bindings(
    java_env_set_session = function(...) TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    file.exists = function(...) TRUE,
    .package = "base"
  )

  local_mocked_bindings(
    system2 = function(...) {
      c("Some random error", "No version here")
    },
    .package = "base"
  )

  expect_false(rJavaEnv:::._java_version_check_impl_original(
    java_home = java_home_mock
  ))
})
