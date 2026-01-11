test_that("._find_extracted_dir correctly identifies the Java root directory", {
  # Setup a temporary directory for simulation
  test_tmp <- tempfile(pattern = "extract_test_")
  dir.create(test_tmp)
  on.exit(unlink(test_tmp, recursive = TRUE))

  # Case 1: Standard extraction (one directory)
  dir1_path <- file.path(test_tmp, "jdk-17")
  dir.create(dir1_path)

  # Access internal function
  find_dir <- getFromNamespace("._find_extracted_dir", "rJavaEnv")

  expect_equal(find_dir(test_tmp), dir1_path)

  # Case 2: macOS metadata files present (._ files)
  apple_double <- file.path(test_tmp, "._jdk-17")
  writeLines("metadata", apple_double) # Create a file, not a directory

  # Should still pick the directory
  expect_equal(find_dir(test_tmp), dir1_path)

  # Case 3: Multiple directories, one hidden (common in some tarballs)
  hidden_dir <- file.path(test_tmp, ".hidden_stuff")
  dir.create(hidden_dir)
  # R's list.files by default doesn't show files starting with .
  # but our grepl is a safety net for ._ files specifically which might show up.

  # Case 4: AppleDouble directory (less common but possible)
  apple_dir <- file.path(test_tmp, "._metadata_dir")
  dir.create(apple_dir)

  # Should still pick jdk-17 because it doesn't start with ._
  expect_equal(find_dir(test_tmp), dir1_path)

  # Case 5: Error when no valid directory found
  unlink(dir1_path, recursive = TRUE)
  expect_error(find_dir(test_tmp), "No directory found after unpacking")
})
