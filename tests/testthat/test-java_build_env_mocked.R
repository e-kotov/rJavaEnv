# Additional coverage tests for java_build_env.R
# These tests cover OS-specific warnings and additional code paths

# Test java_build_env_set with session mode outputs messages
test_that("java_build_env_set session mode outputs success message", {
  local_mocked_bindings(
    set_java_build_env_vars = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Windows"),
    .package = "base"
  )

  expect_message(
    suppressWarnings(java_build_env_set(
      java_home = "/mock/java",
      where = "session",
      quiet = FALSE
    )),
    "Build environment variables set"
  )
})

# Test java_build_env_set warns about Linux dependencies
test_that("java_build_env_set warns about Linux dependencies", {
  local_mocked_bindings(
    set_java_build_env_vars = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Linux"),
    .package = "base"
  )

  expect_warning(
    java_build_env_set(
      java_home = "/mock/java",
      where = "session",
      quiet = FALSE
    ),
    "System dependencies required"
  )
})

# Test java_build_env_set warns about Windows Rtools
test_that("java_build_env_set warns about Windows Rtools", {
  local_mocked_bindings(
    set_java_build_env_vars = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Windows"),
    .package = "base"
  )

  expect_warning(
    java_build_env_set(
      java_home = "/mock/java",
      where = "session",
      quiet = FALSE
    ),
    "Rtools is required"
  )
})

# Test java_build_env_set warns about macOS Xcode
test_that("java_build_env_set warns about macOS Xcode", {
  local_mocked_bindings(
    set_java_build_env_vars = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Darwin"),
    .package = "base"
  )

  expect_warning(
    java_build_env_set(
      java_home = "/mock/java",
      where = "session",
      quiet = FALSE
    ),
    "Xcode Command Line Tools"
  )
})

# Test java_build_env_set project mode outputs message
test_that("java_build_env_set project mode outputs success message", {
  proj_dir <- withr::local_tempdir()

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    set_java_build_env_vars = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Darwin"),
    .package = "base"
  )

  expect_message(
    java_build_env_set(
      java_home = "/mock/java",
      where = "project",
      project_path = proj_dir,
      quiet = FALSE
    ),
    "Build environment set in .Rprofile"
  )
})

# Test java_build_env_unset outputs message on success
test_that("java_build_env_unset outputs message when removing entries", {
  proj_dir <- withr::local_tempdir()
  rprof <- file.path(proj_dir, ".Rprofile")

  writeLines(
    c(
      "# Other config",
      "# rJavaEnvBuild begin",
      "some build config # rJavaEnvBuild",
      "# rJavaEnvBuild end"
    ),
    rprof
  )

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  expect_message(
    java_build_env_unset(project_path = proj_dir, quiet = FALSE),
    "Removed Java build environment settings"
  )
})

# Test java_build_env_set_rprofile creates new file
test_that("java_build_env_set_rprofile creates new .Rprofile if not exists", {
  proj_dir <- withr::local_tempdir()
  rprof <- file.path(proj_dir, ".Rprofile")

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  # Call the internal function directly
  rJavaEnv:::java_build_env_set_rprofile("/mock/java", proj_dir)

  expect_true(file.exists(rprof))
  content <- readLines(rprof)
  expect_true(any(grepl("rJavaEnvBuild begin", content)))
  expect_true(any(grepl("/mock/java", content)))
})

# Test java_build_env_set_rprofile appends to existing file
test_that("java_build_env_set_rprofile appends to existing .Rprofile", {
  proj_dir <- withr::local_tempdir()
  rprof <- file.path(proj_dir, ".Rprofile")

  writeLines("# Existing user config", rprof)

  local_mocked_bindings(
    rje_consent_check = function() TRUE,
    .package = "rJavaEnv"
  )

  rJavaEnv:::java_build_env_set_rprofile("/new/java", proj_dir)

  content <- readLines(rprof)
  expect_true(any(grepl("Existing user config", content)))
  expect_true(any(grepl("rJavaEnvBuild begin", content)))
  expect_true(any(grepl("/new/java", content)))
})

# Test set_java_build_env_vars warns when libjvm not found on Darwin
test_that("set_java_build_env_vars warns when libjvm not found on Darwin", {
  java_home <- "/mock/java/home"

  local_mocked_bindings(
    java_env_set_session = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Darwin"),
    .package = "base"
  )

  local_mocked_bindings(
    get_libjvm_path = function(...) NULL,
    .package = "rJavaEnv"
  )

  expect_warning(
    set_java_build_env_vars(java_home, quiet = FALSE),
    "Could not find libjvm"
  )
})

# Test set_java_build_env_vars warns when libjvm not found on Linux
test_that("set_java_build_env_vars warns when libjvm not found on Linux", {
  java_home <- "/mock/java/home"

  local_mocked_bindings(
    java_env_set_session = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Linux"),
    .package = "base"
  )

  local_mocked_bindings(
    get_libjvm_path = function(...) NULL,
    .package = "rJavaEnv"
  )

  expect_warning(
    set_java_build_env_vars(java_home, quiet = FALSE),
    "Could not find libjvm"
  )
})

# Test set_java_build_env_vars sets Darwin-specific vars when libjvm found
test_that("set_java_build_env_vars sets Darwin JAVA_CPPFLAGS", {
  java_home <- withr::local_tempdir()
  libjvm_path <- file.path(java_home, "lib", "server", "libjvm.dylib")

  # Create directory structure
  dir.create(dirname(libjvm_path), recursive = TRUE)
  file.create(libjvm_path)

  local_mocked_bindings(
    java_env_set_session = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Darwin"),
    .package = "base"
  )

  local_mocked_bindings(
    get_libjvm_path = function(...) libjvm_path,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    dyn.load = function(...) invisible(NULL),
    .package = "base"
  )

  withr::local_envvar(DYLD_LIBRARY_PATH = "")

  set_java_build_env_vars(java_home, quiet = TRUE)

  # Check Darwin-specific env vars
  expect_true(grepl("include", Sys.getenv("JAVA_CPPFLAGS")))
  expect_true(grepl("darwin", Sys.getenv("JAVA_CPPFLAGS")))
})

# Test set_java_build_env_vars handles dyn.load error on Darwin
test_that("set_java_build_env_vars warns on dyn.load failure Darwin", {
  java_home <- withr::local_tempdir()
  libjvm_path <- file.path(java_home, "lib", "server", "libjvm.dylib")

  dir.create(dirname(libjvm_path), recursive = TRUE)
  file.create(libjvm_path)

  local_mocked_bindings(
    java_env_set_session = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Darwin"),
    .package = "base"
  )

  local_mocked_bindings(
    get_libjvm_path = function(...) libjvm_path,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    dyn.load = function(...) stop("Mock dyn.load error"),
    .package = "base"
  )

  withr::local_envvar(DYLD_LIBRARY_PATH = "")

  expect_warning(
    set_java_build_env_vars(java_home, quiet = FALSE),
    "failed to load"
  )
})

# Test set_java_build_env_vars sets Linux-specific vars
test_that("set_java_build_env_vars sets Linux LD_LIBRARY_PATH", {
  java_home <- withr::local_tempdir()
  libjvm_path <- file.path(java_home, "lib", "server", "libjvm.so")

  dir.create(dirname(libjvm_path), recursive = TRUE)
  file.create(libjvm_path)

  local_mocked_bindings(
    java_env_set_session = function(...) invisible(NULL),
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    Sys.info = function() c(sysname = "Linux"),
    .package = "base"
  )

  local_mocked_bindings(
    get_libjvm_path = function(...) libjvm_path,
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    dyn.load = function(...) invisible(NULL),
    .package = "base"
  )

  withr::local_envvar(LD_LIBRARY_PATH = "")

  set_java_build_env_vars(java_home, quiet = TRUE)

  # Check Linux-specific env vars
  expect_true(grepl(dirname(libjvm_path), Sys.getenv("LD_LIBRARY_PATH")))
  expect_true(grepl("linux", Sys.getenv("JAVA_CPPFLAGS")))
})
