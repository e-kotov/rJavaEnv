#' Test that java_check_version_rjava() correctly constructs the subprocess script
#' without duplication issues when .libPaths() contains multiple paths.

test_that("._java_version_check_rjava_impl_original handles multi-line .libPaths correctly", {
  # Mock a scenario where .libPaths() has multiple long paths
  # This previously caused duplication in paste0() because deparse() returned a vector.
  mock_paths <- c(
    "/usr/lib/R/library",
    "/usr/local/lib/R/site-library",
    "/home/user/R/x86_64-pc-linux-gnu-library/4.5"
  )

  captured_script <- NULL

  # Mock get_libjvm_path to return a simple known string
  local_mocked_bindings(
    get_libjvm_path = function(...) "/mock/libjvm.so",
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    .libPaths = function(...) mock_paths,
    system2 = function(command, args, ...) {
      # The first argument in args is the script file path
      if (file.exists(args[1])) {
        captured_script <<- readLines(args[1])
      }
      # Return valid dummy output
      return(c(
        "rJava and other rJava/Java-based packages will use Java version: \"21\""
      ))
    },
    .package = "base"
  )

  # Call the internal function
  result <- rJavaEnv:::._java_version_check_rjava_impl_original(
    java_home = "/mock/java"
  )

  # Assertions on the captured script
  # Avoid expect_* functions that might trigger 'waldo' dependency issues.
  # Using simple R logic that throws an error on failure, which testthat will catch.
  if (is.null(captured_script)) {
    stop("Captured script is NULL")
  }

  # 1. Check for duplication of function definitions
  def_count <- sum(grepl("java_version_check <- function", captured_script))
  if (!identical(as.numeric(def_count), 1)) {
    stop(sprintf(
      "The function definition should appear exactly once, but found %d",
      def_count
    ))
  }

  # 2. Check that .libPaths() contains all paths in a valid call
  script_text <- paste(captured_script, collapse = "\n")
  if (!grepl("\\.libPaths\\(c\\(", script_text)) {
    stop("Should use c() for multiple library paths.")
  }
  if (!grepl("/home/user/R/x86_64-pc-linux-gnu-library/4.5", script_text)) {
    stop("Last path should be present.")
  }

  # 3. Check for syntax errors (no stray commas at line ends from bad paste)
  if (grepl(", \\)", script_text)) {
    stop("Malformed closing parenthesis found.")
  }

  # Final verification: if we reached here, the test passed.
  expect_silent(NULL)
})
