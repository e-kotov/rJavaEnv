# Tests for scoped Java environment functions

test_that("local_java_env sets and restores environment", {
  local_mocked_bindings(
    java_resolve = function(...) "/mock/java/home",
    .package = "rJavaEnv"
  )

  old_java_home <- Sys.getenv("JAVA_HOME")
  old_path <- Sys.getenv("PATH")

  local({
    rJavaEnv::local_java_env(version = 21, quiet = TRUE)
    expect_equal(Sys.getenv("JAVA_HOME"), "/mock/java/home")
    expect_true(grepl("/mock/java/home/bin", Sys.getenv("PATH")))
  })

  # After scope exits, should be restored
  expect_equal(Sys.getenv("JAVA_HOME"), old_java_home)
  expect_equal(Sys.getenv("PATH"), old_path)
})

test_that("with_java_env executes code in correct environment", {
  local_mocked_bindings(
    java_resolve = function(...) "/mock/java/home",
    .package = "rJavaEnv"
  )

  result <- rJavaEnv::with_java_env(version = 21, quiet = TRUE, {
    list(
      java_home = Sys.getenv("JAVA_HOME"),
      has_bin_in_path = grepl("/mock/java/home/bin", Sys.getenv("PATH"))
    )
  })

  expect_equal(result$java_home, "/mock/java/home")
  expect_true(result$has_bin_in_path)
})

test_that("with_rjava_env requires callr package", {
  local_mocked_bindings(
    requireNamespace = function(pkg, ...) FALSE,
    .package = "base"
  )

  expect_error(
    rJavaEnv::with_rjava_env(version = 21, func = identity),
    "callr"
  )
})

test_that("with_rjava_env calls callr::r with correct environment", {
  skip_if_not_installed("callr")
  state <- new.env(parent = emptyenv())
  state$captured_env <- NULL

  local_mocked_bindings(
    java_resolve = function(...) "/mock/java/home",
    .package = "rJavaEnv"
  )

  local_mocked_bindings(
    r = function(func, args, libpath, env, show) {
      state$captured_env <- env
      func()
    },
    .package = "callr"
  )

  rJavaEnv::with_rjava_env(
    version = 21,
    func = function() "test",
    quiet = TRUE
  )

  expect_equal(state$captured_env[["JAVA_HOME"]], "/mock/java/home")
  expect_true(grepl("/mock/java/home/bin", state$captured_env[["PATH"]]))
})

test_that("java_subprocess_env configures Linux rJava loader variables", {
  local_mocked_bindings(
    Sys.info = function() c(sysname = "Linux"),
    .package = "base"
  )

  local_mocked_bindings(
    get_libjvm_path = function(...) "/mock/java/home/lib/server/libjvm.so",
    .package = "rJavaEnv"
  )

  withr::with_envvar(c(PATH = "/usr/bin", LD_LIBRARY_PATH = "/usr/lib"), {
    env_vars <- rJavaEnv:::java_subprocess_env("/mock/java/home", rjava = TRUE)

    expect_equal(env_vars[["JAVA_HOME"]], "/mock/java/home")
    expect_true(grepl("/mock/java/home/bin", env_vars[["PATH"]]))
    expect_equal(
      env_vars[["JAVA_LD_LIBRARY_PATH"]],
      "/mock/java/home/lib/server"
    )
    expect_true(grepl("/mock/java/home/lib/server", env_vars[["LD_LIBRARY_PATH"]]))
  })
})

test_that("java_subprocess_env only updates JAVA_HOME and PATH when rjava is FALSE", {
  withr::with_envvar(c(
    PATH = "/usr/bin",
    LD_LIBRARY_PATH = "sentinel",
    JAVA_LD_LIBRARY_PATH = "sentinel-java-ld"
  ), {
    env_vars <- rJavaEnv:::java_subprocess_env("/mock/java/home", rjava = FALSE)

    expect_equal(env_vars[["JAVA_HOME"]], "/mock/java/home")
    expect_true(grepl("/mock/java/home/bin", env_vars[["PATH"]]))
    expect_equal(env_vars[["LD_LIBRARY_PATH"]], "sentinel")
    expect_equal(env_vars[["JAVA_LD_LIBRARY_PATH"]], "sentinel-java-ld")
  })
})

test_that("java_subprocess_env returns base env when libjvm cannot be resolved", {
  local_mocked_bindings(
    Sys.info = function() c(sysname = "Linux"),
    .package = "base"
  )

  local_mocked_bindings(
    get_libjvm_path = function(...) NULL,
    .package = "rJavaEnv"
  )

  withr::with_envvar(c(
    PATH = "/usr/bin",
    LD_LIBRARY_PATH = NA,
    JAVA_LD_LIBRARY_PATH = "sentinel-java-ld"
  ), {
    env_vars <- rJavaEnv:::java_subprocess_env("/mock/java/home", rjava = TRUE)

    expect_equal(env_vars[["JAVA_HOME"]], "/mock/java/home")
    expect_true(grepl("/mock/java/home/bin", env_vars[["PATH"]]))
    expect_equal(env_vars[["JAVA_LD_LIBRARY_PATH"]], "sentinel-java-ld")
    expect_false("LD_LIBRARY_PATH" %in% names(env_vars))
  })
})

test_that("java_subprocess_env configures macOS DYLD_LIBRARY_PATH for rJava", {
  local_mocked_bindings(
    Sys.info = function() c(sysname = "Darwin"),
    .package = "base"
  )

  local_mocked_bindings(
    get_libjvm_path = function(...) "/mock/java/home/lib/server/libjvm.dylib",
    .package = "rJavaEnv"
  )

  withr::with_envvar(c(PATH = "/usr/bin", DYLD_LIBRARY_PATH = "/usr/lib"), {
    env_vars <- rJavaEnv:::java_subprocess_env("/mock/java/home", rjava = TRUE)

    expect_equal(env_vars[["JAVA_HOME"]], "/mock/java/home")
    expect_true(grepl("/mock/java/home/bin", env_vars[["PATH"]]))
    expect_true(grepl("/mock/java/home/lib/server", env_vars[["DYLD_LIBRARY_PATH"]]))
  })
})

test_that("java_subprocess_env handles missing loader path variables", {
  local_mocked_bindings(
    Sys.info = function() c(sysname = "Darwin"),
    .package = "base"
  )

  local_mocked_bindings(
    get_libjvm_path = function(...) "/mock/java/home/lib/server/libjvm.dylib",
    .package = "rJavaEnv"
  )

  withr::with_envvar(c(PATH = "/usr/bin", DYLD_LIBRARY_PATH = NA), {
    env_vars <- rJavaEnv:::java_subprocess_env("/mock/java/home", rjava = TRUE)

    expect_equal(
      env_vars[["DYLD_LIBRARY_PATH"]],
      "/mock/java/home/lib/server"
    )
  })
})

test_that("java_subprocess_env leaves Windows at JAVA_HOME and PATH only", {
  local_mocked_bindings(
    Sys.info = function() c(sysname = "Windows"),
    .package = "base"
  )

  local_mocked_bindings(
    get_libjvm_path = function(...) "C:/Java/bin/server/jvm.dll",
    .package = "rJavaEnv"
  )

  withr::with_envvar(c(
    PATH = "C:/Windows/System32",
    LD_LIBRARY_PATH = "sentinel-ld",
    DYLD_LIBRARY_PATH = "sentinel-dyld"
  ), {
    env_vars <- rJavaEnv:::java_subprocess_env("C:/Java", rjava = TRUE)

    expect_equal(env_vars[["JAVA_HOME"]], "C:/Java")
    expect_true(grepl("C:/Java/bin", env_vars[["PATH"]], fixed = TRUE))
    expect_equal(env_vars[["LD_LIBRARY_PATH"]], "sentinel-ld")
    expect_equal(env_vars[["DYLD_LIBRARY_PATH"]], "sentinel-dyld")
  })
})

test_that("local_java_env uses cache when .use_cache = TRUE", {
  state <- new.env(parent = emptyenv())
  state$call_count <- 0
  local_mocked_bindings(
    java_resolve = function(..., .use_cache = FALSE) {
      state$call_count <- state$call_count + 1
      "/mock/java/home"
    },
    .package = "rJavaEnv"
  )

  # First call
  local({
    rJavaEnv::local_java_env(version = 21, .use_cache = TRUE, quiet = TRUE)
  })

  first_count <- state$call_count

  # Second call - java_resolve should still be called but with .use_cache = TRUE
  local({
    rJavaEnv::local_java_env(version = 21, .use_cache = TRUE, quiet = TRUE)
  })

  # Both calls happen, but .use_cache = TRUE is passed through
  expect_equal(state$call_count, 2)
})
