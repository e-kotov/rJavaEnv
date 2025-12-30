# This file is run automatically by testthat before tests are run.
# It's a good place for mocks that are used across multiple test files.

# NOTE: Mocks defined here with local_mocked_bindings() will NOT persist
# into the test files because the scope ends when this file finishes sourcing.
# Instead, we use helper-mocks.R which defines functions to apply mocks
# within the test scopes.

# Grant consent globally for all tests to prevent readline() hangs in R CMD check
# This is necessary because some tests call rje_consent() which would prompt for
# user input in non-interactive mode
options(rJavaEnv.consent = TRUE)

# In non-interactive mode (R CMD check), force non-interactive behavior for
# cache management functions to prevent readline() hangs.
# Tests that need to test interactive behavior will override this with
# withr::local_options() and provide the `input` parameter.
if (!interactive()) {
  options(rJavaEnv.interactive = FALSE)
}

# Clear memoise caches before tests to ensure clean test state
# This is important because the internal impl functions are memoised (cached),
# and tests may mock their dependencies
suppressWarnings({
  if (exists("._java_version_check_impl", mode = "function")) {
    memoise::forget(rJavaEnv:::._java_version_check_impl)
  }
  if (exists("._java_version_check_rjava_impl", mode = "function")) {
    memoise::forget(rJavaEnv:::._java_version_check_rjava_impl)
  }
  if (exists("._java_find_system_cached", mode = "function")) {
    memoise::forget(rJavaEnv:::._java_find_system_cached)
  }
})
