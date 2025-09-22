test_that("java_get_home() gets java_get_home", {
  withr::with_envvar(
    c("java_get_home" = "/path/to/java"),
    expect_equal(java_get_home(), "/path/to/java")
  )
})

test_that("java_get_home() returns empty string when java_get_home is not set", {
  withr::with_envvar(
    c("java_get_home" = NA),
    {
      Sys.unsetenv("java_get_home")
      expect_equal(java_get_home(), "")
    }
  )
})
