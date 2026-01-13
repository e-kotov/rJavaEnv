# Additional coverage tests for java_manage_project.R

# Test java_list_project with vector output
test_that("java_list_project returns vector output", {
  proj_dir <- withr::local_tempdir()

  # Create fake Java symlink structure (new: platform/arch/distribution/backend/version with bin/)
  java_symlink_dir <- file.path(
    proj_dir,
    "rjavaenv",
    "macos",
    "aarch64",
    "Corretto",
    "native",
    "21"
  )
  dir.create(file.path(java_symlink_dir, "bin"), recursive = TRUE)

  result <- java_list_project(
    project_path = proj_dir,
    output = "vector",
    quiet = TRUE
  )

  expect_type(result, "character")
  expect_true(any(grepl("21", result)))
})

# Test java_list_project with data.frame output
test_that("java_list_project returns data.frame output", {
  proj_dir <- withr::local_tempdir()

  # Create fake Java symlink structure (new structure with bin/)
  java_symlink_dir <- file.path(
    proj_dir,
    "rjavaenv",
    "linux",
    "x64",
    "Temurin",
    "sdkman",
    "17"
  )
  dir.create(file.path(java_symlink_dir, "bin"), recursive = TRUE)

  result <- java_list_project(
    project_path = proj_dir,
    output = "data.frame",
    quiet = TRUE
  )

  expect_s3_class(result, "data.frame")
  expect_true("version" %in% names(result))
  expect_true("platform" %in% names(result))
  expect_true("arch" %in% names(result))
  expect_true("distribution" %in% names(result))
  expect_true("backend" %in% names(result))
})

# Test java_list_project with quiet = FALSE
test_that("java_list_project outputs message when quiet = FALSE", {
  proj_dir <- withr::local_tempdir()

  # Create fake Java symlink structure (new structure with bin/)
  java_symlink_dir <- file.path(
    proj_dir,
    "rjavaenv",
    "macos",
    "aarch64",
    "Corretto",
    "native",
    "21"
  )
  dir.create(file.path(java_symlink_dir, "bin"), recursive = TRUE)

  expect_message(
    java_list_project(
      project_path = proj_dir,
      output = "vector",
      quiet = FALSE
    ),
    "Contents of the Java symlinks"
  )
})

# Test java_list_project when no Java installed
test_that("java_list_project handles no Java installed", {
  proj_dir <- withr::local_tempdir()

  result <- java_list_project(
    project_path = proj_dir,
    output = "vector",
    quiet = TRUE
  )

  expect_null(result)
})

# Test java_list_project with empty symlink dir
test_that("java_list_project handles empty rjavaenv dir", {
  proj_dir <- withr::local_tempdir()

  # Create empty rjavaenv directory
  dir.create(file.path(proj_dir, "rjavaenv"))

  result <- java_list_project(
    project_path = proj_dir,
    output = "vector",
    quiet = TRUE
  )

  expect_null(result)
})

# Test java_clear_project with delete_all = TRUE
test_that("java_clear_project with delete_all = TRUE clears all", {
  proj_dir <- withr::local_tempdir()

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  # Create fake Java symlink structure (new structure with bin/)
  java_symlink_dir <- file.path(
    proj_dir,
    "rjavaenv",
    "macos",
    "aarch64",
    "Corretto",
    "native",
    "21"
  )
  dir.create(file.path(java_symlink_dir, "bin"), recursive = TRUE)

  java_clear_project(
    project_path = proj_dir,
    delete_all = TRUE
  )

  expect_false(dir.exists(file.path(proj_dir, "rjavaenv")))
})

# Test java_clear_project interactive - user enters "all"
test_that("java_clear_project interactive clears all when user enters 'all'", {
  proj_dir <- withr::local_tempdir()

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    rje_readline = function(...) "all",
    .package = "rJavaEnv"
  )

  # Create fake Java symlink structure (new structure with bin/)
  java_symlink_dir <- file.path(
    proj_dir,
    "rjavaenv",
    "macos",
    "aarch64",
    "Corretto",
    "native",
    "21"
  )
  dir.create(file.path(java_symlink_dir, "bin"), recursive = TRUE)

  withr::local_options(rJavaEnv.interactive = TRUE)

  java_clear_project(
    project_path = proj_dir,
    check = TRUE
  )

  # Files should be cleared but rjavaenv dir may remain
  files_remaining <- list.files(
    file.path(proj_dir, "rjavaenv"),
    recursive = TRUE
  )
  expect_equal(length(files_remaining), 0)
})

# Test java_clear_project interactive - user enters specific number
test_that("java_clear_project interactive clears specific symlink", {
  proj_dir <- withr::local_tempdir()

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    rje_readline = function(...) "1",
    .package = "rJavaEnv"
  )

  # Create fake Java symlink structure (new structure with bin/)
  java_symlink_dir <- file.path(
    proj_dir,
    "rjavaenv",
    "macos",
    "aarch64",
    "Corretto",
    "native",
    "21"
  )
  dir.create(file.path(java_symlink_dir, "bin"), recursive = TRUE)

  withr::local_options(rJavaEnv.interactive = TRUE)

  java_clear_project(
    project_path = proj_dir,
    check = TRUE
  )

  expect_false(dir.exists(java_symlink_dir))
})

# Test java_clear_project interactive - user cancels
test_that("java_clear_project interactive cancels on invalid input", {
  proj_dir <- withr::local_tempdir()

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    rje_readline = function(...) "0",
    .package = "rJavaEnv"
  )

  # Create fake Java symlink structure (new structure with bin/)
  java_symlink_dir <- file.path(
    proj_dir,
    "rjavaenv",
    "macos",
    "aarch64",
    "Corretto",
    "native",
    "21"
  )
  dir.create(file.path(java_symlink_dir, "bin"), recursive = TRUE)

  withr::local_options(rJavaEnv.interactive = TRUE)

  java_clear_project(
    project_path = proj_dir,
    check = TRUE
  )

  # Nothing should be deleted
  expect_true(dir.exists(java_symlink_dir))
})

# Test java_clear_project with check = FALSE
test_that("java_clear_project check=FALSE asks for confirmation", {
  proj_dir <- withr::local_tempdir()

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    rje_readline = function(...) "yes",
    .package = "rJavaEnv"
  )

  # Create fake Java symlink structure (new structure with bin/)
  java_symlink_dir <- file.path(
    proj_dir,
    "rjavaenv",
    "macos",
    "aarch64",
    "Corretto",
    "native",
    "21"
  )
  dir.create(file.path(java_symlink_dir, "bin"), recursive = TRUE)

  withr::local_options(rJavaEnv.interactive = TRUE)

  java_clear_project(
    project_path = proj_dir,
    check = FALSE
  )

  # Files should be cleared
  files_remaining <- list.files(
    file.path(proj_dir, "rjavaenv"),
    recursive = TRUE
  )
  expect_equal(length(files_remaining), 0)
})

# Test java_clear_project with check = FALSE, user says no
test_that("java_clear_project check=FALSE keeps files when user says no", {
  proj_dir <- withr::local_tempdir()

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    rje_readline = function(...) "no",
    .package = "rJavaEnv"
  )

  # Create fake Java symlink structure (new structure with bin/)
  java_symlink_dir <- file.path(
    proj_dir,
    "rjavaenv",
    "macos",
    "aarch64",
    "Corretto",
    "native",
    "21"
  )
  dir.create(file.path(java_symlink_dir, "bin"), recursive = TRUE)

  withr::local_options(rJavaEnv.interactive = TRUE)

  java_clear_project(
    project_path = proj_dir,
    check = FALSE
  )

  # Nothing should be deleted
  expect_true(dir.exists(java_symlink_dir))
})

# Test java_list_project handles legacy structure with backwards compatibility
test_that("java_list_project handles legacy structure with backwards compatibility", {
  proj_dir <- withr::local_tempdir()

  # Create legacy structure: rjavaenv/platform/arch/version with bin/
  java_symlink_dir <- file.path(proj_dir, "rjavaenv", "linux", "x64", "17")
  dir.create(file.path(java_symlink_dir, "bin"), recursive = TRUE)

  result <- java_list_project(
    project_path = proj_dir,
    output = "data.frame",
    quiet = TRUE
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$version[1], "17")
  expect_equal(result$distribution[1], "unknown")
  expect_equal(result$backend[1], "unknown")
})
