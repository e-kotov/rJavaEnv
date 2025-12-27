# Tests for java_find_system()

# Helper function to create mock Java installation structure
create_mock_java_home <- function(base_path, os = "linux") {
  bin_dir <- file.path(base_path, "bin")
  dir.create(bin_dir, recursive = TRUE, showWarnings = FALSE)
  java_exe <- if (os == "windows") "java.exe" else "java"
  java_path <- file.path(bin_dir, java_exe)
  file.create(java_path)
  return(normalizePath(base_path, winslash = "/"))
}

test_that("java_find_system detects JAVA_HOME environment variable", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  temp_java <- withr::local_tempdir()
  java_home <- create_mock_java_home(temp_java)

  withr::local_envvar(JAVA_HOME = java_home)

  # Mock the internal implementation to avoid calling real java -version
  local_mocked_bindings(
    ._java_version_check_impl_original = function(java_home) {
      list(
        major_version = "17",
        java_home = java_home,
        java_path = "mock",
        java_version_output = "mock"
      )
    },
    .package = "rJavaEnv"
  )

  result <- java_find_system(quiet = TRUE)

  expect_s3_class(result, "data.frame")
  expect_true(java_home %in% result$java_home)
  expect_true(all(c("java_home", "version", "is_default") %in% names(result)))
})

test_that("java_find_system validates JAVA_HOME has bin/java", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  temp_dir <- withr::local_tempdir()
  invalid_java <- file.path(temp_dir, "not-java")
  dir.create(invalid_java, recursive = TRUE)
  # Don't create bin/java - this is an invalid JAVA_HOME

  withr::local_envvar(JAVA_HOME = invalid_java)

  result <- java_find_system(quiet = TRUE)

  # Invalid JAVA_HOME should be filtered out
  invalid_normalized <- normalizePath(invalid_java, winslash = "/")
  expect_s3_class(result, "data.frame")
  expect_false(invalid_normalized %in% result$java_home)
})

test_that("java_find_system returns data frame", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  withr::local_envvar(JAVA_HOME = "")

  result <- java_find_system(quiet = TRUE)

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) >= 0)
})

test_that("java_find_system returns unique paths", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  temp_java <- withr::local_tempdir()
  java_home <- create_mock_java_home(temp_java)

  # Set JAVA_HOME to ensure at least one path is found
  withr::local_envvar(JAVA_HOME = java_home)

  result <- java_find_system(quiet = TRUE)

  # No duplicates in java_home column
  expect_equal(nrow(result), length(unique(result$java_home)))
})

test_that("java_find_system normalizes paths", {
  skip_on_os("windows") # Path separator handling differs
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  temp_java <- withr::local_tempdir()
  java_home <- create_mock_java_home(temp_java)

  # Use path with redundant separators
  messy_path <- paste0(java_home, "///")
  withr::local_envvar(JAVA_HOME = messy_path)

  result <- java_find_system(quiet = TRUE)

  # Result should be normalized (no trailing slashes for files)
  expect_false(any(grepl("//", result$java_home)))
  expect_true(java_home %in% result$java_home)
})

test_that("java_find_system handles empty JAVA_HOME gracefully", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  withr::local_envvar(JAVA_HOME = "")

  # Should not error
  expect_silent(result <- java_find_system(quiet = TRUE))
  expect_s3_class(result, "data.frame")
})

test_that("java_find_system handles non-existent JAVA_HOME gracefully", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  withr::local_envvar(JAVA_HOME = "/path/that/does/not/exist/java-99")

  # Should not error and should filter out the invalid path
  expect_silent(result <- java_find_system(quiet = TRUE))
  expect_s3_class(result, "data.frame")
  expect_false("/path/that/does/not/exist/java-99" %in% result$java_home)
})

test_that("java_find_system detects multiple Java installations", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  temp_dir <- withr::local_tempdir()

  java_17 <- file.path(temp_dir, "jdk-17")
  java_11 <- file.path(temp_dir, "jdk-11")

  create_mock_java_home(java_17)
  create_mock_java_home(java_11)

  # Set JAVA_HOME to one of them
  withr::local_envvar(JAVA_HOME = java_17)

  # Mock the internal implementation
  local_mocked_bindings(
    ._java_version_check_impl_original = function(java_home) {
      list(
        major_version = "17",
        java_home = java_home,
        java_path = "mock",
        java_version_output = "mock"
      )
    },
    .package = "rJavaEnv"
  )

  result <- java_find_system(quiet = TRUE)

  # Should at least find the one in JAVA_HOME
  expect_s3_class(result, "data.frame")
  expect_true(normalizePath(java_17, winslash = "/") %in% result$java_home)
})

test_that("java_find_system respects quiet parameter", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  withr::local_envvar(JAVA_HOME = "")

  # Should pass quiet to platform_detect
  # When quiet = TRUE, should not produce messages
  expect_silent(java_find_system(quiet = TRUE))

  # When quiet = FALSE, may produce messages from platform_detect
  # Just verify it doesn't error
  expect_s3_class(java_find_system(quiet = FALSE), "data.frame")
})

test_that("java_find_system validates bin/java executable exists", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  temp_dir <- withr::local_tempdir()

  # Create structure without java executable
  no_java <- file.path(temp_dir, "fake-jdk")
  dir.create(file.path(no_java, "bin"), recursive = TRUE)
  # Don't create the java file

  withr::local_envvar(JAVA_HOME = no_java)

  result <- java_find_system(quiet = TRUE)

  # Should be filtered out
  expect_s3_class(result, "data.frame")
  expect_false(normalizePath(no_java, winslash = "/") %in% result$java_home)
})

test_that("java_find_system handles Windows-style paths on Windows", {
  skip_on_os(c("mac", "linux"))

  temp_dir <- withr::local_tempdir()
  java_home <- create_mock_java_home(temp_dir, os = "windows")

  withr::local_envvar(JAVA_HOME = java_home)

  # Mock java_check_version_cmd
  local_mocked_bindings(
    java_check_version_cmd = function(java_home, quiet = TRUE) "17",
    .package = "rJavaEnv"
  )

  result <- java_find_system(quiet = TRUE)

  # Should normalize to forward slashes
  expect_s3_class(result, "data.frame")
  expect_false(any(grepl("\\\\", result$java_home)))
  expect_true(any(grepl(basename(temp_dir), result$java_home)))
})

test_that("java_find_system uses correct executable name for OS", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  # Create temp Java installation
  temp_java <- withr::local_tempdir()

  # Get current OS
  os_info <- platform_detect(quiet = TRUE)$os

  # Create appropriate structure
  bin_dir <- file.path(temp_java, "bin")
  dir.create(bin_dir, recursive = TRUE)

  if (os_info == "windows") {
    # Windows needs java.exe
    file.create(file.path(bin_dir, "java.exe"))
  } else {
    # Unix-like systems need java
    file.create(file.path(bin_dir, "java"))
  }

  withr::local_envvar(JAVA_HOME = temp_java)

  # Mock java_check_version_cmd
  local_mocked_bindings(
    java_check_version_cmd = function(java_home, quiet = TRUE) "17",
    .package = "rJavaEnv"
  )

  result <- java_find_system(quiet = TRUE)

  expect_s3_class(result, "data.frame")
  expect_true(normalizePath(temp_java, winslash = "/") %in% result$java_home)
})

test_that("java_find_system excludes paths missing java executable", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  temp_dir <- withr::local_tempdir()

  # Create a directory that looks like Java but has no executable
  fake_java <- file.path(temp_dir, "jdk-fake")
  dir.create(file.path(fake_java, "bin"), recursive = TRUE)
  # Create some other file, but not java
  file.create(file.path(fake_java, "bin", "javac"))

  withr::local_envvar(JAVA_HOME = fake_java)

  result <- java_find_system(quiet = TRUE)

  # Should be filtered out because bin/java doesn't exist
  expect_s3_class(result, "data.frame")
  expect_false(normalizePath(fake_java, winslash = "/") %in% result$java_home)
})

test_that("java_find_system handles special characters in paths", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  skip_on_os("windows") # Windows has stricter path rules

  temp_base <- withr::local_tempdir()
  # Create path with space
  java_with_space <- file.path(temp_base, "java with space")
  create_mock_java_home(java_with_space)

  withr::local_envvar(JAVA_HOME = java_with_space)

  # Mock java_check_version_cmd
  local_mocked_bindings(
    java_check_version_cmd = function(java_home, quiet = TRUE) "17",
    .package = "rJavaEnv"
  )

  result <- java_find_system(quiet = TRUE)

  expect_s3_class(result, "data.frame")
  expect_true(
    normalizePath(java_with_space, winslash = "/") %in% result$java_home
  )
})

# Integration tests for OS-specific behavior
test_that("java_find_system calls platform_detect", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  withr::local_envvar(JAVA_HOME = "")

  # Mock platform_detect to track if it's called
  called <- FALSE

  local_mocked_bindings(
    platform_detect = function(quiet) {
      called <<- TRUE
      list(os = "linux", arch = "x64")
    },
    java_check_version_cmd = function(java_home, quiet = TRUE) "17",
    .package = "rJavaEnv"
  )

  result <- java_find_system(quiet = TRUE)

  expect_true(called)
  expect_s3_class(result, "data.frame")
})

test_that("java_find_system passes quiet=TRUE to platform_detect", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  withr::local_envvar(JAVA_HOME = "")

  quiet_passed <- NULL

  local_mocked_bindings(
    platform_detect = function(quiet) {
      quiet_passed <<- quiet
      list(os = "linux", arch = "x64")
    },
    java_check_version_cmd = function(java_home, quiet = TRUE) "17",
    .package = "rJavaEnv"
  )

  java_find_system(quiet = TRUE)
  expect_true(quiet_passed)
})

test_that("java_find_system passes quiet=FALSE to platform_detect", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  withr::local_envvar(JAVA_HOME = "")

  quiet_passed <- NULL

  local_mocked_bindings(
    platform_detect = function(quiet) {
      quiet_passed <<- quiet
      list(os = "linux", arch = "x64")
    },
    java_check_version_cmd = function(java_home, quiet = TRUE) "17",
    .package = "rJavaEnv"
  )

  java_find_system(quiet = FALSE)
  expect_false(quiet_passed)
})

test_that("java_find_system handles platform_detect returning different OS values", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  withr::local_envvar(JAVA_HOME = "")

  for (os in c("linux", "macos", "windows")) {
    local_mocked_bindings(
      platform_detect = function(quiet) list(os = os, arch = "x64"),
      java_check_version_cmd = function(java_home, quiet = TRUE) "17",
      .package = "rJavaEnv"
    )

    # Should not error for any supported OS
    expect_silent(result <- java_find_system(quiet = TRUE))
    expect_s3_class(result, "data.frame")
  }
})

# Edge cases
test_that("java_find_system handles symlinks to Java installation", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  skip_on_os("windows") # Symlink handling differs on Windows

  temp_dir <- withr::local_tempdir()

  # Create real Java home
  real_java <- file.path(temp_dir, "jdk-17.0.1")
  create_mock_java_home(real_java)

  # Create symlink
  link_java <- file.path(temp_dir, "java-current")
  file.symlink(real_java, link_java)

  withr::local_envvar(JAVA_HOME = link_java)

  # Mock java_check_version_cmd to return a version for the mock installation
  local_mocked_bindings(
    java_check_version_cmd = function(java_home, quiet = TRUE) "17",
    .package = "rJavaEnv"
  )

  result <- java_find_system(quiet = TRUE, .use_cache = FALSE)

  # Should resolve symlink and find valid Java home
  # Result should contain either the link or the resolved path
  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) > 0)
})

test_that("java_find_system returns empty data frame when no Java found", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  withr::local_envvar(
    JAVA_HOME = "",
    PATH = ""
  )

  local_mocked_bindings(
    platform_detect = function(quiet) list(os = "linux", arch = "x64"),
    .package = "rJavaEnv"
  )

  result <- java_find_system(quiet = TRUE)

  expect_s3_class(result, "data.frame")
  # May be empty or may find system Java - both are valid
  expect_true(nrow(result) >= 0)
})

# Tests for cache filtering
test_that("java_find_system excludes rJavaEnv cache paths from JAVA_HOME", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  temp_cache <- withr::local_tempdir()

  withr::with_options(
    list("rJavaEnv.cache_path" = temp_cache),
    {
      cache_java_path <- file.path(
        temp_cache,
        "installed",
        "macos",
        "aarch64",
        "21"
      )
      create_mock_java_home(cache_java_path)

      withr::local_envvar(JAVA_HOME = cache_java_path)

      result <- java_find_system(quiet = TRUE)

      expect_s3_class(result, "data.frame")
      expect_false(
        normalizePath(cache_java_path, winslash = "/") %in% result$java_home
      )
    }
  )
})

test_that("java_find_system excludes rJavaEnv cache paths from PATH", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  skip_on_os("windows")

  temp_cache <- withr::local_tempdir()

  withr::with_options(
    list("rJavaEnv.cache_path" = temp_cache),
    {
      cache_java_path <- file.path(
        temp_cache,
        "installed",
        "linux",
        "x64",
        "17"
      )
      create_mock_java_home(cache_java_path)

      cache_bin <- file.path(cache_java_path, "bin")
      withr::local_envvar(
        JAVA_HOME = "",
        PATH = paste(cache_bin, Sys.getenv("PATH"), sep = .Platform$path.sep)
      )

      result <- java_find_system(quiet = TRUE)

      expect_s3_class(result, "data.frame")
      expect_false(
        normalizePath(cache_java_path, winslash = "/") %in% result$java_home
      )
    }
  )
})

test_that("java_find_system includes real system Java even when cache exists", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  temp_cache <- withr::local_tempdir()
  temp_system <- withr::local_tempdir()

  withr::with_options(
    list("rJavaEnv.cache_path" = temp_cache),
    {
      cache_java <- file.path(temp_cache, "installed", "macos", "aarch64", "21")
      system_java <- file.path(temp_system, "jdk-17")

      create_mock_java_home(cache_java)
      create_mock_java_home(system_java)

      withr::local_envvar(JAVA_HOME = system_java)

      # Mock the internal implementation
      local_mocked_bindings(
        ._java_version_check_impl_original = function(java_home) {
          list(
            major_version = "17",
            java_home = java_home,
            java_path = "mock",
            java_version_output = "mock"
          )
        },
        .package = "rJavaEnv"
      )

      result <- java_find_system(quiet = TRUE, .use_cache = FALSE)

      expect_s3_class(result, "data.frame")
      expect_true(
        normalizePath(system_java, winslash = "/") %in% result$java_home
      )
      expect_false(
        normalizePath(cache_java, winslash = "/") %in% result$java_home
      )
    }
  )
})

test_that("java_find_system handles symlinks to cache correctly", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  skip_on_os("windows")

  temp_cache <- withr::local_tempdir()
  temp_dir <- withr::local_tempdir()

  withr::with_options(
    list("rJavaEnv.cache_path" = temp_cache),
    {
      cache_java <- file.path(temp_cache, "installed", "linux", "x64", "11")
      create_mock_java_home(cache_java)

      symlink_path <- file.path(temp_dir, "java-link")
      file.symlink(cache_java, symlink_path)

      withr::local_envvar(JAVA_HOME = symlink_path)

      # Mock java_check_version_cmd
      local_mocked_bindings(
        java_check_version_cmd = function(java_home, quiet = TRUE) "11",
        .package = "rJavaEnv"
      )

      result <- java_find_system(quiet = TRUE, .use_cache = FALSE)

      # Symlink to cache should be filtered out (normalizePath resolves symlinks)
      expect_s3_class(result, "data.frame")
      expect_false(
        normalizePath(symlink_path, winslash = "/") %in% result$java_home
      )
      expect_false(
        normalizePath(cache_java, winslash = "/") %in% result$java_home
      )
    }
  )
})

test_that("is_rjavaenv_cache_path correctly identifies actual cache paths", {
  # Test with the actual cache path from the package option
  cache_path <- getOption("rJavaEnv.cache_path")

  if (!is.null(cache_path) && nzchar(cache_path)) {
    # The actual cache path should be identified as a cache path
    actual_cache <- file.path(cache_path, "installed", "linux", "x64", "21")
    expect_true(rJavaEnv:::is_rjavaenv_cache_path(actual_cache))

    # A path outside the cache should NOT be identified as a cache path
    system_java <- "/usr/lib/jvm/java-17"
    expect_false(rJavaEnv:::is_rjavaenv_cache_path(system_java))
  }
})
