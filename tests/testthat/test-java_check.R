# Tests for java_check_compatibility

test_that("java_check_compatibility returns TRUE when version matches", {
  local_mocked_bindings(
    java_check_current_rjava_version = function() "21",
    .package = "rJavaEnv"
  )

  # Mock rJava as loaded
  local_mocked_bindings(
    loadedNamespaces = function() c("rJava", "base"),
    .package = "base"
  )

  result <- rJavaEnv::java_check_compatibility(
    version = 21,
    type = "exact",
    action = "none"
  )

  expect_true(result)
})
test_that("java_check_compatibility returns FALSE on mismatch with action=none", {
  local_mocked_bindings(
    java_check_current_rjava_version = function() "11",
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    loadedNamespaces = function() c("rJava", "base"),
    .package = "base"
  )

  result <- rJavaEnv::java_check_compatibility(
    version = 21,
    type = "exact",
    action = "none"
  )

  expect_false(result)
})

test_that("java_check_compatibility warns on mismatch with action=warn", {
  local_mocked_bindings(
    java_check_current_rjava_version = function() "8",
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    loadedNamespaces = function() c("rJava", "base"),
    .package = "base"
  )

  expect_warning(
    rJavaEnv::java_check_compatibility(version = 21, action = "warn"),
    "Java version mismatch"
  )
})

test_that("java_check_compatibility respects type=min", {
  local_mocked_bindings(
    java_check_current_rjava_version = function() "21",
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    loadedNamespaces = function() c("rJava", "base"),
    .package = "base"
  )

  # 21 >= 17, should pass
  result <- rJavaEnv::java_check_compatibility(
    version = 17,
    type = "min",
    action = "none"
  )

  expect_true(result)
})
