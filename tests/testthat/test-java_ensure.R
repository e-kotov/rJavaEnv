test_that("java_ensure prioritizes session, then system, then cache", {
  # Setup mock environments
  local_mocked_bindings(
    # Mock no active java first
    check_rjava_initialized = function(...) FALSE,
    java_check_version_cmd = function(...) FALSE,
    # Mock system javas
    java_find_system = function(...) {
      data.frame(
        java_home = c("/path/to/sys17", "/path/to/sys21"),
        version = c("17", "21"),
        is_default = c(TRUE, FALSE),
        stringsAsFactors = FALSE
      )
    },
    # Mock cache
    java_list_installed_cache = function(...) {
      data.frame(
        version = "11",
        path = "/path/to/cache11",
        stringsAsFactors = FALSE
      )
    },
    # Mock action functions
    java_env_set = function(...) invisible(TRUE),
    ._java_env_set_impl = function(...) invisible(TRUE),
    use_java = function(...) invisible(TRUE),
    .package = "rJavaEnv"
  )

  # Test 1: Exact match in system (default behavior)
  # Should find 17 in system
  expect_true(java_ensure(17, quiet = TRUE))

  # Test 2: Min match in system
  # Should find 21 (highest >= 17)
  expect_true(java_ensure(17, type = "min", quiet = TRUE))

  # Test 3: No system match, check cache
  # Should find 11 in cache
  expect_true(java_ensure(11, quiet = TRUE))

  # Test 4: accept_system_java = FALSE
  # Should skip system and fail to find 17 (since it's only in system)
  # But it will then try to install
  expect_true(java_ensure(17, accept_system_java = FALSE, quiet = TRUE))
})

test_that("java_ensure handles install = FALSE correctly", {
  local_mocked_bindings(
    check_rjava_initialized = function(...) FALSE,
    java_check_version_cmd = function(...) FALSE,
    java_find_system = function(...) {
      data.frame(
        java_home = character(),
        version = character(),
        is_default = logical()
      )
    },
    java_list_installed_cache = function(...) {
      data.frame(version = character(), path = character())
    },
    .package = "rJavaEnv"
  )

  expect_false(java_ensure(17, install = FALSE, quiet = TRUE))
})

test_that("java_ensure handled rJava locking correctly (Strict vs Cmd modes)", {
  # Using Dependency Injection for robust testing of internal state logic

  # Common mock setup for external functions
  setup_mocks <- function() {
    local_mocked_bindings(
      java_check_version_cmd = function(...) FALSE,
      java_env_set = function(...) invisible(TRUE),
      ._java_env_set_impl = function(...) invisible(TRUE),
      use_java = function(...) invisible(TRUE),
      java_find_system = function(...) data.frame(),
      java_list_installed_cache = function(...) data.frame(),
      .package = "rJavaEnv"
    )
  }

  # 1. rJava Locked + Mismatch + check_against="rJava" (Default) -> ERROR
  local({
    setup_mocks()
    expect_error(
      java_ensure(
        21,
        check_against = "rJava",
        quiet = TRUE,
        .check_rjava_fun = function(...) TRUE,
        .rjava_ver_fun = function() "11"
      ),
      "rJava is already loaded and locked to Java 11"
    )
  })

  # 2. rJava Locked + Match + check_against="rJava" -> TRUE (Success)
  local({
    setup_mocks()
    expect_true(
      java_ensure(
        21,
        check_against = "rJava",
        quiet = TRUE,
        .check_rjava_fun = function(...) TRUE,
        .rjava_ver_fun = function() "21"
      )
    )
  })

  # 3. rJava Locked + Mismatch + check_against="cmd" -> TRUE (Success)
  local({
    setup_mocks()
    # Mocking successful installation/setting via use_java which returns invisible(TRUE)

    expect_true(
      java_ensure(
        21,
        check_against = "cmd",
        quiet = TRUE,
        .check_rjava_fun = function(...) TRUE,
        .rjava_ver_fun = function() "11"
      )
    )
  })

  # 4. rJava Locked + Unknown Version + check_against="rJava" -> Warning
  local({
    setup_mocks()
    expect_warning(
      java_ensure(
        21,
        check_against = "rJava",
        quiet = TRUE,
        .check_rjava_fun = function(...) TRUE,
        .rjava_ver_fun = function() NULL
      ),
      "rJava is loaded but version could not be determined"
    )
  })
})
