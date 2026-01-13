test_that("java_build constructor creates valid object", {
  build <- java_build(
    vendor = "Temurin",
    version = "21.0.2+13",
    major = 21,
    semver = "21.0.2+13",
    platform = "linux",
    arch = "x64",
    download_url = "https://example.com/temurin-21.tar.gz",
    filename = "temurin-21-linux-x64.tar.gz",
    checksum = "abc123",
    checksum_type = "sha256",
    backend = "native"
  )

  expect_s3_class(build, "java_build")
  expect_equal(build$vendor, "Temurin")
  expect_equal(build$major, 21L)
  expect_equal(build$platform, "linux")
  expect_equal(build$checksum_type, "sha256")
})

test_that("java_build handles NULL checksum for SDKMAN", {
  build <- java_build(
    vendor = "Corretto",
    version = "17",
    major = 17,
    platform = "macos",
    arch = "aarch64",
    download_url = "https://example.com/corretto-17.tar.gz",
    filename = "corretto-17-macos-aarch64.tar.gz",
    checksum = NULL,
    checksum_type = NULL,
    backend = "sdkman"
  )

  expect_s3_class(build, "java_build")
  expect_null(build$checksum)
  expect_null(build$checksum_type)
  expect_equal(build$backend, "sdkman")
})

test_that("resolve_java_metadata dispatches to native resolvers", {
  skip_if_offline()
  skip_on_cran()

  # Test Corretto resolver
  build_corretto <- resolve_java_metadata(
    version = 21,
    distribution = "Corretto",
    platform = "linux",
    arch = "x64",
    backend = "native"
  )

  expect_s3_class(build_corretto, "java_build")
  expect_equal(build_corretto$vendor, "Corretto")
  expect_equal(build_corretto$major, 21L)
  expect_equal(build_corretto$backend, "native")
  expect_false(is.null(build_corretto$checksum))
  expect_equal(build_corretto$checksum_type, "sha256")
})

test_that("resolve_java_metadata dispatches to Temurin", {
  skip_if_offline()
  skip_on_cran()

  build_temurin <- resolve_java_metadata(
    version = 17,
    distribution = "Temurin",
    platform = "linux",
    arch = "x64",
    backend = "native"
  )

  expect_s3_class(build_temurin, "java_build")
  expect_equal(build_temurin$vendor, "Temurin")
  expect_equal(build_temurin$major, 17L)
  expect_false(is.null(build_temurin$checksum))
})

test_that("resolve_java_metadata dispatches to Zulu", {
  skip_if_offline()
  skip_on_cran()

  build_zulu <- resolve_java_metadata(
    version = 11,
    distribution = "Zulu",
    platform = "linux",
    arch = "x64",
    backend = "native"
  )

  expect_s3_class(build_zulu, "java_build")
  expect_equal(build_zulu$vendor, "Zulu")
  expect_equal(build_zulu$major, 11L)
  expect_false(is.null(build_zulu$checksum))
})

test_that("resolve_java_metadata errors on unknown distribution", {
  expect_error(
    resolve_java_metadata(
      version = 21,
      distribution = "Unknown",
      platform = "linux",
      arch = "x64"
    ),
    "Unknown distribution"
  )
})
