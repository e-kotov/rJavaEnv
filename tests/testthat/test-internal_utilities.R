# Tests for platform_detect() and rje_consent()

test_that("platform_detect returns correct structure", {
  res <- platform_detect(quiet = TRUE)

  expect_type(res, "list")
  expect_named(res, c("os", "arch"))
  expect_true(res$os %in% c("linux", "windows", "macos"))
  expect_true(res$arch %in% c("x64", "x86", "aarch64"))
})

test_that("platform_detect returns correct OS for current platform", {
  res <- platform_detect(quiet = TRUE)
  sys_info <- Sys.info()

  expected_os <- switch(
    tolower(sys_info["sysname"]),
    "windows" = "windows",
    "linux" = "linux",
    "darwin" = "macos"
  )

  expect_equal(res$os, expected_os)
})

test_that("platform_detect respects R_ARCH for Windows architecture", {
  skip_on_os("mac")
  skip_on_os("linux")

  # Test x64 architecture via R_ARCH
  withr::local_envvar(R_ARCH = "/x64")
  res <- platform_detect(quiet = TRUE)
  expect_equal(res$arch, "x64")

  # Test x86 architecture via R_ARCH
  withr::local_envvar(R_ARCH = "/i386")
  res <- platform_detect(quiet = TRUE)
  expect_equal(res$arch, "x86")
})

test_that("platform_detect prints messages when not quiet", {
  expect_message(
    platform_detect(quiet = FALSE),
    "Detected platform"
  )
})

test_that("rje_consent returns TRUE when option is already set", {
  withr::local_options(list(rJavaEnv.consent = TRUE))

  expect_message(
    result <- rje_consent(),
    "already been provided"
  )
  expect_true(result)
})

test_that("rje_consent returns TRUE when cache directory exists", {
  cache_dir <- withr::local_tempdir()
  withr::local_options(list(
    rJavaEnv.consent = FALSE,
    rJavaEnv.cache_path = cache_dir
  ))

  expect_message(
    result <- rje_consent(),
    "already been provided"
  )
  expect_true(result)
})

test_that("rje_consent handles user typing 'yes'", {
  cache_dir <- file.path(withr::local_tempdir(), "nonexistent")
  withr::local_options(list(
    rJavaEnv.consent = FALSE,
    rJavaEnv.cache_path = cache_dir
  ))

  # Mock readline wrapper
  local_mocked_bindings(
    rje_readline = function(prompt = "") "yes",
    .package = "rJavaEnv"
  )

  expect_message(
    result <- rje_consent(),
    "Consent has been granted"
  )
  expect_true(getOption("rJavaEnv.consent"))
})

test_that("rje_consent handles user typing 'no'", {
  cache_dir <- file.path(withr::local_tempdir(), "nonexistent")
  withr::local_options(list(
    rJavaEnv.consent = FALSE,
    rJavaEnv.cache_path = cache_dir
  ))

  # Mock readline wrapper
  local_mocked_bindings(
    rje_readline = function(prompt = "") "no",
    .package = "rJavaEnv"
  )

  expect_error(
    rje_consent(),
    "Consent was not provided"
  )
})

test_that("rje_consent accepts 'provided = TRUE' argument", {
  cache_dir <- file.path(withr::local_tempdir(), "nonexistent")
  withr::local_options(list(
    rJavaEnv.consent = FALSE,
    rJavaEnv.cache_path = cache_dir
  ))

  expect_message(
    result <- rje_consent(provided = TRUE),
    "Consent has been granted"
  )
  expect_true(getOption("rJavaEnv.consent"))
})

test_that("rje_consent_check returns TRUE when consent option is set", {
  withr::local_options(list(rJavaEnv.consent = TRUE))

  expect_true(rje_consent_check())
})

test_that("rje_consent_check returns TRUE when cache directory exists", {
  cache_dir <- withr::local_tempdir()
  withr::local_options(list(
    rJavaEnv.consent = FALSE,
    rJavaEnv.cache_path = cache_dir
  ))

  expect_true(rje_consent_check())
})

test_that("rje_consent_check grants implicit consent in CI environments", {
  cache_dir <- file.path(withr::local_tempdir(), "nonexistent")
  withr::local_options(list(
    rJavaEnv.consent = FALSE,
    rJavaEnv.cache_path = cache_dir
  ))
  withr::local_envvar(CI = "true")

  expect_true(rje_consent_check())
  expect_true(getOption("rJavaEnv.consent"))
})

test_that("rje_consent_check grants implicit consent in GitHub Actions", {
  cache_dir <- file.path(withr::local_tempdir(), "nonexistent")
  withr::local_options(list(
    rJavaEnv.consent = FALSE,
    rJavaEnv.cache_path = cache_dir
  ))
  withr::local_envvar(GITHUB_ACTION = "test-action")

  expect_true(rje_consent_check())
  expect_true(getOption("rJavaEnv.consent"))
})

test_that("rje_envvar_exists correctly detects environment variables", {
  withr::local_envvar(TEST_VAR_EXISTS = "value")

  expect_true(rje_envvar_exists("TEST_VAR_EXISTS"))
  expect_false(rje_envvar_exists("TEST_VAR_DOES_NOT_EXIST_12345"))
})

test_that("java_urls_load returns correct structure", {
  urls <- java_urls_load()

  expect_type(urls, "list")
  expect_true("Corretto" %in% names(urls))
})

test_that("platform_detect handles common architectures", {
  # This test verifies the current platform returns one of the known architectures
  res <- platform_detect(quiet = TRUE)

  # The function should not error on the current machine

  expect_true(length(res$arch) == 1)
  expect_true(nchar(res$arch) > 0)
})
