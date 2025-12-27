test_that("java_env_set_session function exists and handles basic cases", {
  # Mocking base functions like file.exists or list.files interferes with R's package
  # loading system and testthat's operations. Instead, we test the non-Linux path which
  # doesn't require complex mocks.

  # Mock installed.packages to avoid rJava checks
  local_mocked_bindings(
    installed.packages = function(...) matrix(character(0), nrow=0, ncol=2),
    .package = "utils"
  )

  # On non-Linux platforms, the function just sets environment variables
  # This should work without triggering libjvm.so loading
  skip_on_os("linux")  # Skip on actual Linux to avoid system-specific issues

  expect_no_error(
    rJavaEnv:::java_env_set_session(java_home = "/mock/java")
  )
})

test_that("java_env_set_session warns if rJava is already loaded", {
  # Mock installed.packages to say rJava is installed
  local_mocked_bindings(
    installed.packages = function() matrix(c("rJava"), dimnames=list(NULL, "Package")),
    .package = "utils"
  )

  # Mock loadedNamespaces to say rJava is loaded
  local_mocked_bindings(
    loadedNamespaces = function() c("base", "rJava"),
    .package = "base"
  )

  # Expect the warning message (using regex to match cli-formatted message)
  expect_message(
    rJavaEnv:::java_env_set_session(java_home = "/mock/java"),
    "You have.*rJava.*loaded"
  )
})
