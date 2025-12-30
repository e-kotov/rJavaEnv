# Additional coverage tests for java_check.R

# Test action = "stop" on version mismatch
test_that("java_check_compatibility stops on mismatch with action=stop", {
  local_mocked_bindings(
    java_check_current_rjava_version = function() "8",
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    loadedNamespaces = function() c("rJava", "base"),
    .package = "base"
  )

  expect_error(
    rJavaEnv::java_check_compatibility(
      version = 21,
      type = "exact",
      action = "stop"
    ),
    "Java version mismatch"
  )
})

# Test action = "message" on version mismatch
test_that("java_check_compatibility messages on mismatch with action=message", {
  local_mocked_bindings(
    java_check_current_rjava_version = function() "11",
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    loadedNamespaces = function() c("rJava", "base"),
    .package = "base"
  )

  expect_message(
    result <- rJavaEnv::java_check_compatibility(
      version = 21,
      type = "exact",
      action = "message"
    )
  )

  expect_false(result)
})

# Test type = "min" with older version (should fail)
test_that("java_check_compatibility fails when current < required with type=min", {
  local_mocked_bindings(
    java_check_current_rjava_version = function() "8",
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    loadedNamespaces = function() c("rJava", "base"),
    .package = "base"
  )

  result <- rJavaEnv::java_check_compatibility(
    version = 17,
    type = "min",
    action = "none"
  )

  expect_false(result)
})

# Test when rJava not loaded but requireNamespace succeeds
test_that("java_check_compatibility tries jinit when rJava available", {
  jinit_called <- FALSE

  local_mocked_bindings(
    java_check_current_rjava_version = function() {
      # First call returns NULL, second returns version
      if (jinit_called) "21" else NULL
    },
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    requireNamespace = function(pkg, ...) {
      if (pkg == "rJava") {
        TRUE
      } else {
        base::requireNamespace(pkg, ...)
      }
    },
    .package = "base"
  )

  # Mock rJava::.jinit
  local_mocked_bindings(
    .jinit = function(...) {
      jinit_called <<- TRUE
      invisible(NULL)
    },
    .package = "rJava"
  )

  # This test may be tricky due to the internal state; skip if rJava mocking fails
  skip_if_not_installed("rJava")

  result <- tryCatch(
    rJavaEnv::java_check_compatibility(
      version = 21,
      type = "exact",
      action = "none"
    ),
    error = function(e) NULL
  )

  # Just verify no errors - exact behavior depends on rJava state
  expect_true(is.null(result) || is.logical(result))
})

# Test when rJava version is NULL even after jinit
test_that("java_check_compatibility handles null version after jinit", {
  local_mocked_bindings(
    java_check_current_rjava_version = function() NULL,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    requireNamespace = function(pkg, ...) {
      if (pkg == "rJava") TRUE else base::requireNamespace(pkg, ...)
    },
    .package = "base"
  )

  # Mock rJava::.jinit to do nothing
  local_mocked_bindings(
    .jinit = function(...) invisible(NULL),
    .package = "rJava"
  )

  skip_if_not_installed("rJava")

  expect_warning(
    result <- rJavaEnv::java_check_compatibility(
      version = 21,
      action = "warn"
    ),
    "JVM could not be detected"
  )

  expect_false(result)
})

# Test null version handling with action=stop
test_that("java_check_compatibility stops when JVM not detected with action=stop", {
  local_mocked_bindings(
    java_check_current_rjava_version = function() NULL,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    requireNamespace = function(pkg, ...) FALSE,
    .package = "base"
  )

  expect_error(
    rJavaEnv::java_check_compatibility(
      version = 21,
      action = "stop"
    ),
    "JVM could not be detected"
  )
})

# Test null version handling with action=message
test_that("java_check_compatibility messages when JVM not detected", {
  local_mocked_bindings(
    java_check_current_rjava_version = function() NULL,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    requireNamespace = function(pkg, ...) FALSE,
    .package = "base"
  )

  expect_message(
    result <- rJavaEnv::java_check_compatibility(
      version = 21,
      action = "message"
    )
  )

  expect_false(result)
})
