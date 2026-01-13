# Additional coverage tests for java_manage_installed_cache.R

# Test java_clear_installed with delete_all = TRUE
test_that("java_clear_installed with delete_all = TRUE clears all", {
  cache_path <- withr::local_tempdir()
  inst_path <- file.path(cache_path, "installed")
  dir.create(inst_path, recursive = TRUE)

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  # Create fake installation structure
  # installed/platform/arch/distribution/backend/version
  inst1 <- file.path(inst_path, "linux", "x64", "Corretto", "native", "21")
  dir.create(file.path(inst1, "bin"), recursive = TRUE)
  inst2 <- file.path(inst_path, "linux", "x64", "Temurin", "native", "17")
  dir.create(file.path(inst2, "bin"), recursive = TRUE)

  java_clear_installed(
    cache_path = cache_path,
    delete_all = TRUE
  )

  expect_equal(length(list.files(inst_path, recursive = TRUE)), 0)
})

# Test java_clear_installed interactive - user enters "all"
test_that("java_clear_installed interactive clears all when user enters 'all'", {
  cache_path <- withr::local_tempdir()
  inst_path <- file.path(cache_path, "installed")
  dir.create(inst_path, recursive = TRUE)

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    rje_readline = function(...) "all",
    .package = "rJavaEnv"
  )

  # Create fake installation structure
  inst1 <- file.path(inst_path, "linux", "x64", "Corretto", "native", "21")
  dir.create(file.path(inst1, "bin"), recursive = TRUE)

  withr::local_options(rJavaEnv.interactive = TRUE)

  java_clear_installed(
    cache_path = cache_path,
    check = TRUE
  )

  # Should be empty (parent dirs might remain depending on implementation,
  # but checking for the leaf version dir is safest)
  expect_false(dir.exists(inst1))
})

# Test java_clear_installed interactive - user enters specific number
test_that("java_clear_installed interactive clears specific installation", {
  cache_path <- withr::local_tempdir()
  inst_path <- file.path(cache_path, "installed")
  dir.create(inst_path, recursive = TRUE)

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    rje_readline = function(...) "1",
    .package = "rJavaEnv"
  )

  # Create fake installation structure
  inst1 <- file.path(inst_path, "linux", "x64", "Corretto", "native", "21")
  dir.create(file.path(inst1, "bin"), recursive = TRUE)

  # java_list_installed needs to find it.
  # To make the test robust, we can mock java_list_installed OR ensure filesystem is perfect.
  # Let's mock java_list_installed to return the path, to test the clearing logic specifically.

  local_mocked_bindings(
    java_list_installed = function(...) c(inst1),
    .package = "rJavaEnv"
  )

  withr::local_options(rJavaEnv.interactive = TRUE)

  java_clear_installed(
    cache_path = cache_path,
    check = TRUE
  )

  expect_false(dir.exists(inst1))
})

# Test java_clear_installed interactive - user cancels
test_that("java_clear_installed interactive cancels on invalid input", {
  cache_path <- withr::local_tempdir()
  inst_path <- file.path(cache_path, "installed")
  dir.create(inst_path, recursive = TRUE)

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    rje_readline = function(...) "0",
    .package = "rJavaEnv"
  )

  # Create fake installation
  inst1 <- file.path(inst_path, "linux", "x64", "Corretto", "native", "21")
  dir.create(file.path(inst1, "bin"), recursive = TRUE)

  local_mocked_bindings(
    java_list_installed = function(...) c(inst1),
    .package = "rJavaEnv"
  )

  withr::local_options(rJavaEnv.interactive = TRUE)

  java_clear_installed(
    cache_path = cache_path,
    check = TRUE
  )

  expect_true(dir.exists(inst1))
})

# Test java_clear_installed check=FALSE with yes response
test_that("java_clear_installed check=FALSE clears when user confirms", {
  cache_path <- withr::local_tempdir()
  inst_path <- file.path(cache_path, "installed")
  dir.create(inst_path, recursive = TRUE)

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    rje_readline = function(...) "yes",
    .package = "rJavaEnv"
  )

  inst1 <- file.path(inst_path, "linux", "x64", "Corretto", "native", "21")
  dir.create(file.path(inst1, "bin"), recursive = TRUE)

  withr::local_options(rJavaEnv.interactive = TRUE)

  java_clear_installed(
    cache_path = cache_path,
    check = FALSE
  )

  expect_false(dir.exists(inst1))
})

# Test java_clear_installed check=FALSE with no response
test_that("java_clear_installed check=FALSE keeps files when user says no", {
  cache_path <- withr::local_tempdir()
  inst_path <- file.path(cache_path, "installed")
  dir.create(inst_path, recursive = TRUE)

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    rje_readline = function(...) "no",
    .package = "rJavaEnv"
  )

  inst1 <- file.path(inst_path, "linux", "x64", "Corretto", "native", "21")
  dir.create(file.path(inst1, "bin"), recursive = TRUE)

  withr::local_options(rJavaEnv.interactive = TRUE)

  java_clear_installed(
    cache_path = cache_path,
    check = FALSE
  )

  expect_true(dir.exists(inst1))
})
