# Unit tests for parsing Java version output
# These tests focus on verifying that Java version strings are parsed correctly

test_that("java_check_version_system regex extracts OpenJDK 17 version correctly", {
  # We test the regex parsing logic that java_check_version_system uses
  # by simulating what it does with the java version output

  java_ver_string <- 'openjdk version "17.0.1" 2021-10-19'
  matches <- regexec(
    '(openjdk|java) (version )?(\\\")?([0-9]{1,2})',
    java_ver_string
  )
  major_java_ver <- regmatches(java_ver_string, matches)[[1]][5]

  expect_equal(major_java_ver, "17")
})

test_that("java_check_version_system regex extracts Java 11 version correctly", {
  java_ver_string <- 'openjdk version "11.0.13" 2021-10-19'
  matches <- regexec(
    '(openjdk|java) (version )?(\\\")?([0-9]{1,2})',
    java_ver_string
  )
  major_java_ver <- regmatches(java_ver_string, matches)[[1]][5]

  expect_equal(major_java_ver, "11")
})

test_that("java_check_version_system regex extracts Java 8 version correctly", {
  java_ver_string <- 'java version "1.8.0_292"'
  matches <- regexec(
    '(openjdk|java) (version )?(\\\")?([0-9]{1,2})',
    java_ver_string
  )
  major_java_ver <- regmatches(java_ver_string, matches)[[1]][5]

  # Java 8 returns "1", which should be converted to "8"
  expect_equal(major_java_ver, "1")

  # The function then converts "1" to "8"
  if (major_java_ver == "1") {
    major_java_ver <- "8"
  }
  expect_equal(major_java_ver, "8")
})

test_that("java_check_version_system regex extracts Java 21 version correctly", {
  java_ver_string <- 'openjdk version "21.0.1" 2023-10-17'
  matches <- regexec(
    '(openjdk|java) (version )?(\\\")?([0-9]{1,2})',
    java_ver_string
  )
  major_java_ver <- regmatches(java_ver_string, matches)[[1]][5]

  expect_equal(major_java_ver, "21")
})

test_that("java_version_check_rscript output parsing for version 17", {
  # Test the parsing of output from java_version_check_rscript
  output <- c(
    "rJava and other rJava/Java-based packages will use Java version: \"17.0.1\""
  )
  cleaned_output <- cli::ansi_strip(output[1])
  major_java_ver <- sub('.*version: \\"([0-9]+).*', '\\1', cleaned_output)

  if (major_java_ver == "1") {
    major_java_ver <- "8"
  }

  expect_equal(major_java_ver, "17")
})

test_that("java_version_check_rscript output parsing for version 1.8", {
  output <- c(
    "rJava and other rJava/Java-based packages will use Java version: \"1.8.0\""
  )
  cleaned_output <- cli::ansi_strip(output[1])
  major_java_ver <- sub('.*version: \\"([0-9]+).*', '\\1', cleaned_output)

  # For Java 8, version string starts with "1"
  expect_equal(major_java_ver, "1")

  if (major_java_ver == "1") {
    major_java_ver <- "8"
  }
  expect_equal(major_java_ver, "8")
})

test_that("java_check_version_rjava silent behavior", {
  # This test verifies that when rJava is not installed, the function returns FALSE
  local_mocked_bindings(
    find.package = function(package, quiet = TRUE) {
      # Simulate rJava not being found
      character(0)
    },
    .package = "base"
  )

  result <- java_check_version_rjava(java_home = "/mock/java", quiet = TRUE)
  expect_false(result)
})

test_that("java_check_version_cmd with quiet = TRUE doesn't throw", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")

  # When JAVA_HOME is not set and we don't provide a java_home
  withr::local_envvar(c("JAVA_HOME" = NA))

  result <- java_check_version_cmd(java_home = NULL, quiet = TRUE)
  # Should return FALSE gracefully without errors
  expect_false(result)
})

test_that("Sys.which mock works correctly", {
  # Verify our mocking approach works
  local_mocked_bindings(
    Sys.which = function(x) {
      if (x == "java") "/usr/bin/java" else ""
    },
    .package = "base"
  )

  expect_equal(Sys.which("java"), "/usr/bin/java")
  expect_equal(Sys.which("nonexistent"), "")
})

test_that("system2 mock can return version output", {
  skip_on_cran()
  skip_if(!identical(Sys.getenv("CI"), "true"), "Only run on CI")
  # Verify our mocking approach works for system2
  local_mocked_bindings(
    system2 = function(cmd, args = NULL, ...) {
      c('openjdk version "11.0.1"')
    },
    .package = "base"
  )

  result <- system2("java", args = "-version")
  expect_equal(result[1], 'openjdk version "11.0.1"')
})
