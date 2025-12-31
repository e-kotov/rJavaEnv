test_that("resolve_symlinks returns path as-is on non-Unix or empty path", {
  # We can't easily mock Windows on Linux/Mac for the OS check itself if it uses .Platform$OS.type
  # But we can test empty path
  expect_equal(rJavaEnv:::resolve_symlinks(""), "")
})

test_that("resolve_symlinks returns original path if it is not a symlink", {
  skip_on_os("windows")

  tmp <- withr::local_tempdir()
  target <- file.path(tmp, "target")
  file.create(target)

  expect_equal(rJavaEnv:::resolve_symlinks(target), target)
})

test_that("resolve_symlinks resolves simple symlink", {
  skip_on_os("windows")

  tmp <- withr::local_tempdir()
  target <- file.path(tmp, "target")
  file.create(target)
  link <- file.path(tmp, "link")
  file.symlink(target, link)

  expect_equal(rJavaEnv:::resolve_symlinks(link), target)
})

test_that("resolve_symlinks resolves relative symlink", {
  skip_on_os("windows")

  tmp <- withr::local_tempdir()
  # Use a subdirectory to ensure we are testing relative path resolution
  dir.create(file.path(tmp, "subdir"))

  # Create the target file
  target <- file.path(tmp, "subdir", "target")
  file.create(target)

  # create a symlink "link1" in subdir that points to "target" (relative)
  withr::with_dir(file.path(tmp, "subdir"), {
    file.symlink("target", "link1")
  })

  link1_abs <- file.path(tmp, "subdir", "link1")

  # verify it is a symlink
  expect_true(nzchar(Sys.readlink(link1_abs)))

  # resolve it
  expect_equal(rJavaEnv:::resolve_symlinks(link1_abs), target)
})

test_that("resolve_symlinks handles nested symlinks", {
  skip_on_os("windows")

  tmp <- withr::local_tempdir()
  target <- file.path(tmp, "target")
  file.create(target)

  link1 <- file.path(tmp, "link1")
  link2 <- file.path(tmp, "link2")
  link3 <- file.path(tmp, "link3")

  file.symlink(target, link1)
  file.symlink(link1, link2)
  file.symlink(link2, link3)

  expect_equal(rJavaEnv:::resolve_symlinks(link3), target)
})

test_that("resolve_symlinks respects max_depth", {
  skip_on_os("windows")

  tmp <- withr::local_tempdir()
  link1 <- file.path(tmp, "link1")
  link2 <- file.path(tmp, "link2")

  # Circular reference
  # link1 -> link2
  # link2 -> link1

  file.symlink(link2, link1)
  file.symlink(link1, link2)

  # With default depth (10), it should stop eventually and return one of the links
  # It shouldn't hang or crash stack.

  res <- rJavaEnv:::resolve_symlinks(link1, max_depth = 5)
  expect_true(res %in% c(link1, link2))
})

test_that("resolve_symlinks handles broken links", {
  skip_on_os("windows")

  tmp <- withr::local_tempdir()
  target <- file.path(tmp, "missing_target")
  link <- file.path(tmp, "link")
  file.symlink(target, link)

  res <- rJavaEnv:::resolve_symlinks(link)
  expect_equal(res, target)
})
