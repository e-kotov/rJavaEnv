test_that("resolve_java_metadata handles specific Temurin versions", {
  skip_if_offline()
  skip_on_cran()

  # 1. Success case for specific version
  # Use a stable older version that won't disappear
  ver_ok <- "11.0.21+9"
  build_ok <- resolve_java_metadata(
    version = ver_ok,
    distribution = "Temurin",
    platform = "macos", # Temurin API uses "mac" internally
    arch = "aarch64",
    backend = "native"
  )
  expect_equal(build_ok$version, ver_ok)
  expect_equal(build_ok$vendor, "Temurin")
  expect_match(build_ok$download_url, "11\\.0\\.21.*9") # encoded + is %2B

  # 2. Fallback case (.0.LTS -> -LTS)
  # This version initially fails but should succeed with fallback logic
  ver_lts <- "21.0.8+9.0.LTS"
  # Note: The result version in the object will match request "21.0.8+9.0.LTS"
  # because we pass `version` to java_build, even if we used alt_version for lookup.
  build_lts <- resolve_java_metadata(
    version = ver_lts,
    distribution = "Temurin",
    platform = "macos",
    arch = "aarch64",
    backend = "native"
  )
  expect_equal(build_lts$version, ver_lts)
  expect_equal(build_lts$vendor, "Temurin")

  # 3. Invalid version (Expect "Version not found" or "no JSON")
  ver_bad <- "99.99.99+99"
  expect_error(
    resolve_java_metadata(
      version = ver_bad,
      distribution = "Temurin",
      platform = "macos",
      arch = "aarch64",
      backend = "native"
    ),
    "not found" # We look for "not found" in the error message
  )
})

test_that("resolve_java_metadata handles specific Zulu versions", {
  skip_if_offline()
  skip_on_cran()

  # 1. Success case
  ver_ok <- "11.0.15"
  build_ok <- resolve_java_metadata(
    version = ver_ok,
    distribution = "Zulu",
    platform = "macos",
    arch = "aarch64",
    backend = "native"
  )
  expect_equal(build_ok$version, ver_ok)
  expect_equal(build_ok$vendor, "Zulu")

  # 2. Mismatch/Invalid version that triggers fallback
  # The API might fall back to latest Java 25, which we now catch.
  ver_bad <- "21.0.8+9.0.LT"
  expect_error(
    resolve_java_metadata(
      version = ver_bad,
      distribution = "Zulu",
      platform = "macos",
      arch = "aarch64",
      backend = "native"
    ),
    "Zulu API returned Java .* when .* was requested"
  )
})

test_that("resolve_java_metadata handles specific Corretto versions", {
  skip_if_offline()
  skip_on_cran()

  # 1. Success case (must match latest available for Major to pass native backend check)
  # This is tricky because "latest" changes. verify logic:
  # We can't easily test "success" for a specific old version on Native backend
  # because it only supports "latest".
  # But we can test failure for a made-up version.

  ver_bad <- "11.99.99.99"
  expect_error(
    resolve_java_metadata(
      version = ver_bad,
      distribution = "Corretto",
      platform = "macos", # Corretto uses "macos"
      arch = "aarch64",
      backend = "native"
    ),
    # It might fail with "not found" or "Found latest: ..., please use sdkman"
    "not available via Corretto native backend"
  )
})
