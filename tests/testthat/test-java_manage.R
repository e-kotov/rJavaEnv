# Tests for java_list() and java_clear()

test_that("java_list dispatches correctly", {
  # Mock the specific list functions
  local_mocked_bindings(
    java_list_distrib_cache = function(...) "listed_distrib",
    java_list_installed_cache = function(...) "listed_installed",
    java_list_in_project = function(...) "listed_project",
    .package = "rJavaEnv"
  )

  expect_equal(java_list("distrib"), "listed_distrib")
  expect_equal(java_list("installed"), "listed_installed")
  expect_equal(java_list("project"), "listed_project")
})

test_that("java_clear (project) handles user input correctly", {
  op <- options(rJavaEnv.interactive = TRUE)
  on.exit(options(op), add = TRUE)
  # Setup fake project structure with proper depth
  proj_dir <- withr::local_tempdir()
  rjava_dir <- file.path(proj_dir, "rjavaenv", "linux", "x64", "17")
  dir.create(rjava_dir, recursive = TRUE)
  file.create(file.path(rjava_dir, "dummy_file"))

  # Mock consent
  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  # Case 1: User says "no"
  local_mocked_bindings(
    rje_readline = function(prompt = "") "no",
    .package = "rJavaEnv"
  )
  expect_message(
    java_clear("project", target_dir = proj_dir, check = FALSE),
    "No Java symlinks were cleared"
  )
  # The directory should still exist
  expect_true(dir.exists(rjava_dir))

  # Case 2: User says "yes"
  local_mocked_bindings(
    rje_readline = function(prompt = "") "yes",
    .package = "rJavaEnv"
  )
  expect_message(
    java_clear("project", target_dir = proj_dir, check = FALSE),
    "cleared"
  )
  # Contents should be cleared
  rjava_base <- file.path(proj_dir, "rjavaenv")
  expect_length(list.files(rjava_base, recursive = TRUE), 0)
})

test_that("java_clear (distrib) deletes specific files via menu", {
  withr::local_options(rJavaEnv.interactive = TRUE)
  cache_dir <- withr::local_tempdir()
  dist_dir <- file.path(cache_dir, "distrib")
  dir.create(dist_dir, recursive = TRUE)

  f1 <- file.path(dist_dir, "java1.tar.gz")
  f2 <- file.path(dist_dir, "java2.tar.gz")
  file.create(f1)
  file.create(f2)

  # Mock consent
  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  # User selects item "1" (check=TRUE triggers numbered menu)
  # We must mock java_list_distrib_cache to return vector so the index works
  local_mocked_bindings(
    java_list_distrib_cache = function(...) c(f1, f2),
    rje_readline = function(prompt = "") "1",
    .package = "rJavaEnv"
  )

  java_clear("distrib", target_dir = cache_dir, check = TRUE)

  expect_false(file.exists(f1))
  expect_true(file.exists(f2))
})

test_that("java_clear deletes all when requested", {
  cache_dir <- withr::local_tempdir()
  inst_dir <- file.path(cache_dir, "installed")
  dir.create(inst_dir, recursive = TRUE)
  file.create(file.path(inst_dir, "folder1"))

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  java_clear("installed", target_dir = cache_dir, delete_all = TRUE)
  expect_length(list.files(inst_dir), 0)
})

test_that("java_clear (installed) handles numbered selection", {
  withr::local_options(rJavaEnv.interactive = TRUE)
  cache_dir <- withr::local_tempdir()
  inst_dir <- file.path(cache_dir, "installed", "linux", "x64", "17")
  dir.create(inst_dir, recursive = TRUE)
  inst_dir2 <- file.path(cache_dir, "installed", "linux", "x64", "21")
  dir.create(inst_dir2, recursive = TRUE)

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  # User selects item "1"
  # Mock java_list_installed_cache to return expected paths
  local_mocked_bindings(
    java_list_installed_cache = function(...) c(inst_dir, inst_dir2),
    rje_readline = function(prompt = "") "1",
    .package = "rJavaEnv"
  )

  java_clear("installed", target_dir = cache_dir, check = TRUE)

  expect_false(dir.exists(inst_dir))
  expect_true(dir.exists(inst_dir2))
})

test_that("java_clear (project) handles 'all' option", {
  withr::local_options(rJavaEnv.interactive = TRUE)
  proj_dir <- withr::local_tempdir()
  rjava_dir1 <- file.path(proj_dir, "rjavaenv", "linux", "x64", "17")
  rjava_dir2 <- file.path(proj_dir, "rjavaenv", "linux", "x64", "21")
  dir.create(rjava_dir1, recursive = TRUE)
  dir.create(rjava_dir2, recursive = TRUE)

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  # User types "all"
  local_mocked_bindings(
    rje_readline = function(prompt = "") "all",
    .package = "rJavaEnv"
  )

  java_clear("project", target_dir = proj_dir, check = TRUE)

  # All should be cleared
  rjava_base <- file.path(proj_dir, "rjavaenv")
  expect_length(list.files(rjava_base, recursive = TRUE), 0)
})

test_that("java_clear cancels on invalid input", {
  withr::local_options(rJavaEnv.interactive = TRUE)
  cache_dir <- withr::local_tempdir()
  dist_dir <- file.path(cache_dir, "distrib")
  dir.create(dist_dir, recursive = TRUE)

  f1 <- file.path(dist_dir, "java1.tar.gz")
  file.create(f1)

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  # User enters "0" to cancel
  local_mocked_bindings(
    java_list_distrib_cache = function(...) c(f1),
    rje_readline = function(prompt = "") "0",
    .package = "rJavaEnv"
  )

  expect_message(
    java_clear("distrib", target_dir = cache_dir, check = TRUE),
    "No distributions were cleared"
  )

  # File should still exist
  expect_true(file.exists(f1))
})
