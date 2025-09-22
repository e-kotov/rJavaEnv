test_that("java_get_home() gets JAVA_HOME", {
  withr::with_envvar(
    c("JAVA_HOME" = "/path/to/java"),
    expect_equal(java_get_home(), "/path/to/java")
  )
})

test_that("java_get_home() returns empty string when JAVA_HOME is not set", {
  withr::with_envvar(
    c("JAVA_HOME" = NA),
    {
      Sys.unsetenv("JAVA_HOME")
      expect_equal(java_get_home(), "")
    }
  )
})
