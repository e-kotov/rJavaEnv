test_that("full runtime versions are read from the selected home", {
  output <- NULL
  local_mocked_bindings(
    ._java_version_check_impl_original = function(java_home) output,
    .package = "rJavaEnv"
  )
  output <- list(
    java_version_output = c(
      "Picked up JAVA_TOOL_OPTIONS: -Xmx1g",
      'openjdk version "21.0.9" 2025-10-21 LTS'
    )
  )
  expect_identical(java_version_at_home("/jdk"), "21.0.9")
  output <- list(java_version_output = 'java version "1.8.0_452"')
  expect_identical(java_version_at_home("/jdk"), "1.8.0_452")
  output <- list(java_version_output = "no version here")
  expect_identical(java_version_at_home("/jdk"), "")
  output <- FALSE
  expect_identical(java_version_at_home("/jdk"), "")
})

test_that("major requirements reject versions without a major component", {
  expect_false(java_version_satisfies("not-a-version", "21", "exact"))
  expect_false(java_version_satisfies("not-a-version", "21", "min"))
})

test_that("patch requests compare system candidates by full version", {
  withr::local_envvar(c(JAVA_HOME = NA))
  full <- c("/jdk-a" = "21.0.8", "/jdk-b" = "21.0.10", "/jdk-c" = "17.0.2")
  local_mocked_bindings(
    java_find_system = function(...) {
      data.frame(
        java_home = names(full),
        version = c("21", "21", "17")
      )
    },
    java_version_at_home = function(java_home) full[[java_home]],
    java_list_installed = function(...) stop("must not reach the cache"),
    .package = "rJavaEnv"
  )
  expect_message(
    selected <- java_resolve("21.0.8", install = FALSE, quiet = FALSE),
    "Found valid system Java"
  )
  expect_identical(selected, "/jdk-a")
  # Numeric ordering selects 21.0.10 over 21.0.8 for a minimum requirement.
  expect_identical(
    java_resolve("21.0.8", type = "min", install = FALSE, quiet = TRUE),
    "/jdk-b"
  )
})

test_that("patch requests use cached full versions when system search fails", {
  withr::local_envvar(c(JAVA_HOME = NA))
  full <- c("/cache-a" = "21.0.7", "/cache-b" = "21.0.8")
  local_mocked_bindings(
    java_find_system = function(...) stop("scan failed"),
    java_list_installed = function(...) {
      data.frame(
        version = "21",
        path = names(full),
        distribution = "Corretto",
        backend = "native",
        platform = "linux",
        arch = "x64"
      )
    },
    java_version_at_home = function(java_home) full[[java_home]],
    .package = "rJavaEnv"
  )
  expect_message(
    selected <- java_resolve(
      "21.0.8",
      install = FALSE,
      quiet = FALSE,
      platform = "linux",
      arch = "x64"
    ),
    "System Java search failed"
  )
  expect_identical(selected, "/cache-b")
})

test_that("SDKMAN identifiers select the SDKMAN backend and its distribution", {
  withr::local_envvar(c(JAVA_HOME = NA))
  distribution <- sdkman_vendor_to_distribution("tem")
  local_mocked_bindings(
    java_find_system = function(...) stop("must not scan system Java"),
    java_list_installed = function(...) {
      data.frame(
        version = c("21.0.8-tem", "21.0.8-tem", "21.0.8"),
        path = c("/native", "/sdkman", "/plain"),
        distribution = distribution,
        backend = c("native", "sdkman", "sdkman"),
        platform = "linux",
        arch = "x64"
      )
    },
    .package = "rJavaEnv"
  )
  expect_identical(
    java_resolve(
      "21.0.8-tem",
      backend = "native",
      install = FALSE,
      quiet = TRUE,
      platform = "linux",
      arch = "x64"
    ),
    "/sdkman"
  )
})

test_that("command checks report an undeterminable version when not quiet", {
  withr::local_envvar(c(JAVA_HOME = NA))
  expect_message(
    expect_false(java_check_version_cmd(java_home = tempfile(), quiet = FALSE)),
    "Could not determine the Java version"
  )
})
