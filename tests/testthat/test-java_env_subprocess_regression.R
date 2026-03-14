test_that("._java_version_check_rjava_impl_original prefers callr", {
  skip_if_not_installed("callr")
  state <- new.env(parent = emptyenv())
  state$captured_env <- NULL
  state$captured_libpath <- NULL

  local_mocked_bindings(
    r = function(func, args = list(), libpath, env, show) {
      state$captured_env <- env
      state$captured_libpath <- libpath
      list(
        java_version = "21.0.8",
        output = paste0(
          "rJava and other rJava/Java-based packages will use ",
          "Java version: \"21.0.8\""
        )
      )
    },
    .package = "callr"
  )

  local_mocked_bindings(
    java_subprocess_env = function(java_home, rjava = FALSE) {
      c(JAVA_HOME = java_home, PATH = paste(java_home, "bin", sep = "/"))
    },
    .package = "rJavaEnv"
  )

  result <- rJavaEnv:::._java_version_check_rjava_impl_original(
    java_home = "/mock/java"
  )

  expect_equal(result$major_version, "21")
  expect_equal(state$captured_env[["JAVA_HOME"]], "/mock/java")
  expect_equal(state$captured_libpath, .libPaths())
})

test_that("._java_version_check_rjava_impl_original falls back to Rscript", {
  mock_paths <- c(
    "/usr/lib/R/library",
    "/usr/local/lib/R/site-library",
    "/home/user/R/x86_64-pc-linux-gnu-library/4.5"
  )

  state <- new.env(parent = emptyenv())
  state$captured_script <- NULL
  state$captured_env <- NULL

  local_mocked_bindings(
    requireNamespace = function(pkg, quietly = TRUE) FALSE,
    .package = "base"
  )

  local_mocked_bindings(
    java_subprocess_env = function(java_home, rjava = FALSE) {
      state$captured_env <- c(
        JAVA_HOME = java_home,
        PATH = paste0(java_home, "/bin")
      )
      state$captured_env
    },
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    .libPaths = function(...) mock_paths,
    system2 = function(command, args, stdout, stderr, timeout, env) {
      state$captured_env <- env
      if (file.exists(args[1])) {
        state$captured_script <- readLines(args[1])
      }
      c(
        "rJava and other rJava/Java-based packages will use Java version: \"21\""
      )
    },
    .package = "base"
  )

  result <- rJavaEnv:::._java_version_check_rjava_impl_original(
    java_home = "/mock/java"
  )

  expect_equal(result$major_version, "21")
  expect_equal(state$captured_env[["JAVA_HOME"]], "/mock/java")
  expect_equal(
    sum(grepl("java_version_check <- function", state$captured_script)),
    1
  )

  script_text <- paste(state$captured_script, collapse = "\n")
  expect_true(grepl("\\.libPaths\\(c\\(", script_text))
  expect_true(grepl("/home/user/R/x86_64-pc-linux-gnu-library/4.5", script_text))
  expect_false(any(grepl("get_libjvm_path <- function", state$captured_script)))
})
