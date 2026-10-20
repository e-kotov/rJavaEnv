test_that("locked JVM requirements compare major and full versions safely", {
  loaded <- function(...) TRUE
  current <- function() "21.0.8"
  expect_true(java_ensure(21, quiet = TRUE,
    .check_rjava_fun = loaded, .rjava_ver_fun = current))
  expect_true(java_ensure("21.0.8", quiet = TRUE,
    .check_rjava_fun = loaded, .rjava_ver_fun = current))
  expect_true(java_ensure("21.0.7", type = "min", quiet = TRUE,
    .check_rjava_fun = loaded, .rjava_ver_fun = current))
  for (requested in c("21.0.9", "21.0.7")) {
    expect_error(java_ensure(requested, quiet = TRUE,
      .check_rjava_fun = loaded, .rjava_ver_fun = current), "already loaded")
  }
  expect_true(java_ensure("8.0.452", quiet = TRUE,
    .check_rjava_fun = loaded, .rjava_ver_fun = function() "1.8.0_452"))
  expect_error(java_ensure("21.0.8-tem", quiet = TRUE,
    .check_rjava_fun = loaded, .rjava_ver_fun = current), "already loaded")
})

test_that("an unverified loaded rJava cannot cause setup side effects", {
  local_mocked_bindings(
    java_resolve = function(...) stop("must not resolve or install"),
    ._java_env_set_impl = function(...) stop("must not set environment"),
    .package = "rJavaEnv"
  )
  expect_error(java_ensure(21, quiet = TRUE,
    .check_rjava_fun = function(...) TRUE, .rjava_ver_fun = function() NULL),
    "cannot be verified")
})

test_that("patch resolution queries complete versions in the active JDK", {
  withr::local_envvar(c(JAVA_HOME = "/selected/java"))
  local_mocked_bindings(
    java_version_at_home = function(home) "21.0.8",
    java_find_system = function(...) data.frame(),
    java_list_installed = function(...) character(),
    .package = "rJavaEnv"
  )
  expect_identical(java_resolve("21.0.8", install = FALSE), "/selected/java")
  expect_error(java_resolve("21.0.9", install = FALSE), "not found")
  expect_identical(java_resolve("21.0.7", type = "min", install = FALSE), "/selected/java")
})

test_that("version requirements reject ambiguous or malformed inputs", {
  for (version in list(NA, character(), c(17, 21), "bad", TRUE)) {
    expect_error(java_resolve(version, install = FALSE))
  }
  expect_error(java_resolve("21.0.8-tem", type = "min", install = FALSE),
    "identifiers require")
  expect_error(java_check_compatibility("21.0.8"), "major Java version")
})

test_that("command checks do not change the environment when the executable is missing", {
  withr::local_envvar(c(JAVA_HOME = NA, DYLD_LIBRARY_PATH = NA))
  before <- Sys.getenv(c("JAVA_HOME", "PATH", "DYLD_LIBRARY_PATH"), unset = NA)
  expect_false(java_check_version_cmd(java_home = tempfile(), quiet = TRUE))
  expect_identical(Sys.getenv(names(before), unset = NA), before)
})


test_that("a backend cannot satisfy a patch request with the wrong installed runtime", {
  withr::local_envvar(c(JAVA_HOME = NA))
  local_mocked_bindings(
    java_list_installed = function(...) character(),
    rje_consent_check = function() TRUE,
    java_download = function(...) "/archive",
    java_unpack = function(...) "/installed",
    java_version_at_home = function(...) "21.0.9",
    .package = "rJavaEnv"
  )
  expect_error(java_resolve("21.0.8", accept_system_java = FALSE),
    "installed Java runtime does not satisfy")
  expect_identical(java_resolve("21.0.8", type = "min", accept_system_java = FALSE),
    "/installed")
})
