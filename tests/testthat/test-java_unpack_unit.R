# Additional coverage tests for java_unpack.R

# Test java_unpack with force = TRUE removes existing installation
test_that("java_unpack with force removes existing installation", {
  cache_path <- withr::local_tempdir()
  withr::local_options(rJavaEnv.cache_path = cache_path)

  # Create fake existing installation (new structure: platform/arch/distribution/backend/version)
  installed_path <- file.path(
    cache_path,
    "installed",
    "linux",
    "x64",
    "unknown",
    "unknown",
    "21"
  )
  dir.create(installed_path, recursive = TRUE)
  file.create(file.path(installed_path, "old_file.txt"))

  # Create a fake tar.gz file
  distrib_path <- file.path(
    cache_path,
    "amazon-corretto-21-linux-x64-jdk.tar.gz"
  )

  # Mock untar to create files
  local_mocked_bindings(
    untar = function(tarfile, exdir, ...) {
      # Create expected structure
      extracted_dir <- file.path(exdir, "amazon-corretto-21")
      dir.create(extracted_dir, recursive = TRUE)
      file.create(file.path(extracted_dir, "new_file.txt"))
    },
    .package = "utils"
  )

  # Create a dummy tar file
  file.create(distrib_path)

  result <- java_unpack(
    java_distrib_path = distrib_path,
    quiet = TRUE,
    force = TRUE
  )

  expect_true(dir.exists(result))
  # Old file should be gone after force
  expect_false(file.exists(file.path(result, "old_file.txt")))
})

# Test java_unpack with force = TRUE outputs message
test_that("java_unpack with force outputs message when quiet = FALSE", {
  cache_path <- withr::local_tempdir()
  withr::local_options(rJavaEnv.cache_path = cache_path)

  # Create fake existing installation (new structure: platform/arch/distribution/backend/version)
  installed_path <- file.path(
    cache_path,
    "installed",
    "macos",
    "aarch64",
    "unknown",
    "unknown",
    "17"
  )
  dir.create(installed_path, recursive = TRUE)
  file.create(file.path(installed_path, "existing.txt"))

  distrib_path <- file.path(
    cache_path,
    "amazon-corretto-17-macos-aarch64-jdk.tar.gz"
  )
  file.create(distrib_path)

  local_mocked_bindings(
    untar = function(tarfile, exdir, ...) {
      extracted_dir <- file.path(
        exdir,
        "amazon-corretto-17",
        "Contents",
        "Home"
      )
      dir.create(extracted_dir, recursive = TRUE)
      file.create(file.path(extracted_dir, "bin"))
    },
    .package = "utils"
  )

  expect_message(
    java_unpack(
      java_distrib_path = distrib_path,
      quiet = FALSE,
      force = TRUE
    ),
    "Forced re-installation"
  )
})

# Test java_unpack skips unpacking when already installed
test_that("java_unpack skips when already unpacked", {
  cache_path <- withr::local_tempdir()
  withr::local_options(rJavaEnv.cache_path = cache_path)

  # Create fake existing installation with content (new structure)
  installed_path <- file.path(
    cache_path,
    "installed",
    "linux",
    "x64",
    "unknown",
    "unknown",
    "11"
  )
  dir.create(installed_path, recursive = TRUE)
  file.create(file.path(installed_path, "bin"))

  distrib_path <- file.path(
    cache_path,
    "amazon-corretto-11-linux-x64-jdk.tar.gz"
  )

  expect_message(
    result <- java_unpack(
      java_distrib_path = distrib_path,
      quiet = FALSE,
      force = FALSE
    ),
    "already unpacked"
  )

  expect_equal(result, installed_path)
})

# Test java_unpack errors on invalid version in filename
test_that("java_unpack errors on invalid version in filename", {
  cache_path <- withr::local_tempdir()
  withr::local_options(rJavaEnv.cache_path = cache_path)

  distrib_path <- file.path(cache_path, "invalid-version-linux-x64.tar.gz")

  expect_error(
    java_unpack(java_distrib_path = distrib_path, quiet = TRUE),
    "Unable to detect Java version"
  )
})

# Test java_unpack errors on invalid architecture in filename
test_that("java_unpack errors on invalid architecture in filename", {
  cache_path <- withr::local_tempdir()
  withr::local_options(rJavaEnv.cache_path = cache_path)

  distrib_path <- file.path(cache_path, "amazon-corretto-21-linux-mips.tar.gz")

  expect_error(
    java_unpack(java_distrib_path = distrib_path, quiet = TRUE),
    "Unable to detect architecture"
  )
})

# Test java_unpack errors on invalid platform in filename
test_that("java_unpack errors on invalid platform in filename", {
  cache_path <- withr::local_tempdir()
  withr::local_options(rJavaEnv.cache_path = cache_path)

  distrib_path <- file.path(cache_path, "amazon-corretto-21-freebsd-x64.tar.gz")

  expect_error(
    java_unpack(java_distrib_path = distrib_path, quiet = TRUE),
    "Unable to detect platform"
  )
})

# Test java_unpack handles .zip files
test_that("java_unpack handles zip files", {
  cache_path <- withr::local_tempdir()
  withr::local_options(rJavaEnv.cache_path = cache_path)

  distrib_path <- file.path(
    cache_path,
    "amazon-corretto-21-windows-x64-jdk.zip"
  )
  file.create(distrib_path)

  local_mocked_bindings(
    unzip = function(zipfile, exdir, ...) {
      extracted_dir <- file.path(exdir, "amazon-corretto-21")
      dir.create(extracted_dir, recursive = TRUE)
      file.create(file.path(extracted_dir, "bin"))
    },
    .package = "utils"
  )

  result <- java_unpack(
    java_distrib_path = distrib_path,
    quiet = TRUE
  )

  expect_true(dir.exists(result))
})

# Test java_unpack errors on unsupported format
test_that("java_unpack errors on unsupported file format", {
  cache_path <- withr::local_tempdir()
  withr::local_options(rJavaEnv.cache_path = cache_path)

  # Create path for installed dir first (new structure)
  installed_path <- file.path(
    cache_path,
    "installed",
    "linux",
    "x64",
    "unknown",
    "unknown",
    "21"
  )

  distrib_path <- file.path(cache_path, "amazon-corretto-21-linux-x64-jdk.dmg")
  file.create(distrib_path)

  expect_error(
    java_unpack(java_distrib_path = distrib_path, quiet = TRUE),
    "Unsupported file format"
  )
})

# Test java_unpack macOS extracts from Contents/Home
test_that("java_unpack macOS extracts from Contents/Home", {
  cache_path <- withr::local_tempdir()
  withr::local_options(rJavaEnv.cache_path = cache_path)

  distrib_path <- file.path(
    cache_path,
    "amazon-corretto-21-macos-aarch64-jdk.tar.gz"
  )
  file.create(distrib_path)

  local_mocked_bindings(
    untar = function(tarfile, exdir, ...) {
      # Create macOS-style structure
      extracted_dir <- file.path(
        exdir,
        "amazon-corretto-21",
        "Contents",
        "Home"
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
  # Should have extracted the contents
  expect_true(
    file.exists(file.path(result, "bin")) ||
      dir.exists(file.path(result, "bin"))
  )
})
