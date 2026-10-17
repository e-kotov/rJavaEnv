test_that("managed-only resolution ignores an active system JDK", {
  local_mocked_bindings(
    java_check_version_cmd = function(...) "21",
    java_find_system = function(...) stop("must not scan system Java"),
    java_list_installed = function(...) character(),
    .package = "rJavaEnv"
  )
  withr::local_envvar(c(JAVA_HOME = "/system/java"))
  expect_error(java_resolve(21, accept_system_java = FALSE, install = FALSE),
    "Required Java version not found")
})

test_that("resolution checks the requested home instead of PATH", {
  withr::local_envvar(c(JAVA_HOME = "/selected/java"))
  local_mocked_bindings(
    java_check_version_cmd = function(java_home, ...) {
      expect_identical(java_home, "/selected/java")
      "21"
    },
    .package = "rJavaEnv"
  )
  expect_identical(java_resolve(21, install = FALSE), "/selected/java")
})

test_that("cached candidates are ordered as versions and filtered by architecture", {
  withr::local_envvar(c(JAVA_HOME = NA))
  local_mocked_bindings(
    java_list_installed = function(...) data.frame(
      version = c("9", "21", "99"), path = c("/java9", "/java21", "/wrong-arch"),
      distribution = "Corretto", backend = "native", platform = "linux",
      arch = c("x64", "x64", "aarch64")
    ),
    .package = "rJavaEnv"
  )
  expect_identical(java_resolve(8, type = "min", accept_system_java = FALSE,
    install = FALSE, platform = "linux", arch = "x64"), "/java21")
})

test_that("java_resolve installs if not found (mocking java_download)", {
  # We need to see if java_download mock works.
  # We will assert that java_download is called.

  local_mocked_bindings(
    java_check_version_cmd = function(...) FALSE,
    java_find_system = function(...) data.frame(),
    rje_consent_check = function() TRUE,
    java_download = function(...) stop("MockCalled"),
    .package = "rJavaEnv"
  )

  tmp_cache <- withr::local_tempdir()

  expect_error(
    java_resolve(
      version = "17",
      install = TRUE,
      quiet = TRUE,
      cache_path = tmp_cache
    ),
    "MockCalled"
  )
})
