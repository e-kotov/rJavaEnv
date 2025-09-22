# This file is run automatically by testthat before tests are run.
# It's a good place for mocks that are used across multiple test files.

# Mock the slow network call to java_valid_versions() for all tests
# that don't need to test this function's specific behavior.
# The mock will be active for the entire test run because of this file's
# special 'setup-*' name.
local_mocked_bindings(
  java_valid_versions = function(...) c("8", "11", "17", "21")
)
