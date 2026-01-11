# Test java_unpack macOS fallback when Contents/Home missing
test_that("java_unpack macOS fallback when Contents/Home missing", {
  cache_path <- withr::local_tempdir()
  withr::local_options(rJavaEnv.cache_path = cache_path)

  distrib_path <- file.path(
    cache_path,
    "weird-distro-21-macos-aarch64-jdk.tar.gz"
  )
  file.create(distrib_path)

  local_mocked_bindings(
    untar = function(tarfile, exdir, ...) {
      # Create NON-standard structure (no Contents/Home)
      # e.g. just the bin dir at root of extract
      extracted_dir <- file.path(
        exdir,
        "weird-distro-21"
      )
      dir.create(extracted_dir, recursive = TRUE)
      file.create(file.path(extracted_dir, "bin"))
      file.create(file.path(extracted_dir, "lib"))
    },
    .package = "utils"
  )

  result <- java_unpack(
    java_distrib_path = distrib_path,
    quiet = TRUE
  )

  expect_true(dir.exists(result))
  # Should have found it at the root
  expect_true(
    file.exists(file.path(result, "bin")) ||
      dir.exists(file.path(result, "bin"))
  )
})
