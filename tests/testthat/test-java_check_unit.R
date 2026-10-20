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

test_that("compatibility checks do not load rJava to discover a JVM", {
  local_mocked_bindings(
    java_check_current_rjava_version = function() NULL,
    .package = "rJavaEnv"
  )
  local_mocked_bindings(
    requireNamespace = function(...) stop("must not load a namespace"),
    .package = "base"
  )
  expect_false(java_check_compatibility(21, action = "none"))
})

test_that("compatibility reports an unverified JVM without initializing it", {
  local_mocked_bindings(
    java_check_current_rjava_version = function() NULL,
    .package = "rJavaEnv"
  )
  expect_warning(
    result <- java_check_compatibility(21, action = "warn"),
    "No running rJava JVM"
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
    "No running rJava JVM"
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
