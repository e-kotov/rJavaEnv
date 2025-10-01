# This file is run automatically by testthat before tests are run.
# It's a good place for mocks that are used across multiple test files.

# Mock the slow network call to java_valid_versions()
local_mocked_bindings(
  java_valid_versions = function(...) c("8", "11", "17", "21")
)

# Mock common dependencies for java_install() tests
local_mocked_bindings(
  # Assume user consent is always given in tests
  rje_consent_check = function() TRUE,
  # Assume java_unpack always succeeds and returns a predictable path.
  # We are not testing java_unpack here.
  # CORRECTED: This mock is now self-contained and does not depend on global options.
  java_unpack = function(java_distrib_path, ...) {
    filename <- basename(java_distrib_path)
    parts <- strsplit(gsub("\\.tar\\.gz|\\.zip", "", filename), "-")[[1]]
    version <- parts[parts %in% c("8", "11", "17", "21")][1]
    arch <- parts[parts %in% c("x64", "aarch64")][1]
    platform <- parts[parts %in% c("linux", "windows", "macos")][1]

    # Use a generic, hardcoded root path instead of calling getOption().
    # This makes the mock independent of the state being tested.
    file.path(
      "/mock/cache/path",
      "installed",
      platform,
      arch,
      version
    )
  }
)
