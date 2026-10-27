# Cache locations, platform folders and version matching

# A minimal JDK archive: <root>/bin/java and a release file
make_jdk_archive <- function(dir, filename) {
  src <- file.path(withr::local_tempdir(.local_envir = parent.frame()), "jdk-root")
  dir.create(file.path(src, "bin"), recursive = TRUE)
  writeLines("", file.path(src, "bin", "java"))
  writeLines('IMPLEMENTOR="Test"', file.path(src, "release"))
  archive <- file.path(dir, filename)
  withr::with_dir(dirname(src), utils::tar(archive, "jdk-root", compression = "gzip"))
  archive
}

test_that("java_unpack installs into the given cache_path", {
  option_cache <- withr::local_tempdir()
  cache_path <- withr::local_tempdir()
  withr::local_options(rJavaEnv.cache_path = option_cache)
  archive <- make_jdk_archive(withr::local_tempdir(), "native-temurin-21-linux-x64.tar.gz")

  home <- java_unpack(archive, distribution = "Temurin", backend = "native", quiet = TRUE, cache_path = cache_path)
  expect_equal(home, file.path(cache_path, "installed", "linux", "x64", "Temurin", "native", "21"))
  expect_true(file.exists(file.path(home, "bin", "java")))
  expect_false(dir.exists(file.path(option_cache, "installed")))
})

test_that("use_java installs into its cache_path argument", {
  option_cache <- withr::local_tempdir()
  cache_path <- withr::local_tempdir()
  withr::local_options(rJavaEnv.cache_path = option_cache)
  archive <- make_jdk_archive(withr::local_tempdir(), "native-temurin-21-linux-x64.tar.gz")
  attr(archive, "distribution") <- "Temurin"
  attr(archive, "backend") <- "native"

  set_home <- NULL
  local_mocked_bindings(
    java_download = function(...) archive,
    java_valid_versions = function(...) "21",
    ._java_env_set_impl = function(java_home, ...) set_home <<- java_home
  )
  use_java(21, distribution = "Temurin", cache_path = cache_path, platform = "linux", arch = "x64")
  expect_equal(set_home, file.path(cache_path, "installed", "linux", "x64", "Temurin", "native", "21"))
  expect_false(dir.exists(file.path(option_cache, "installed")))
})

test_that("Alpine archives are not installed as glibc Linux", {
  cache_path <- withr::local_tempdir()
  archive <- make_jdk_archive(
    withr::local_tempdir(),
    "native-amazon-corretto-21.0.13.0.11-alpine-linux-x64.tar.gz"
  )
  attr(archive, "version") <- "21"
  home <- java_unpack(archive, distribution = "Corretto", backend = "native", quiet = TRUE, cache_path = cache_path)
  expect_equal(home, file.path(cache_path, "installed", "alpine-linux", "x64", "Corretto", "native", "21"))
})

test_that("Corretto resolves Alpine builds from the index's alpine key", {
  index <- list(alpine = list(x64 = list(jdk = list(`21` = list(`tar.gz` = list(
    resource = "/downloads/resources/21.0.13.0.11/amazon-corretto-21.0.13.0.11-alpine-linux-x64.tar.gz",
    checksum_sha256 = "abc"
  ))))))
  local_mocked_bindings(read_json_url = function(...) index)

  build <- resolve_corretto_metadata("21", "alpine-linux", "x64")
  expect_equal(build$filename, "amazon-corretto-21.0.13.0.11-alpine-linux-x64.tar.gz")
  expect_match(build$download_url, "amazon-corretto-21-x64-alpine-jdk.tar.gz", fixed = TRUE)

  expect_equal(java_valid_major_versions_corretto(arch = "x64", platform = "alpine-linux"), "21")
  expect_equal(list_corretto_versions_impl("alpine-linux", "x64")$version, "21.0.13.0.11")
})

test_that("Zulu lists musl builds for Alpine", {
  url <- NULL
  local_mocked_bindings(read_json_url = function(u, ...) {
    url <<- u
    list()
  })
  list_zulu_versions_impl("alpine-linux", "x64")
  expect_match(url, "os=linux-musl&", fixed = TRUE)
})

test_that("a specific Corretto version matches whole version components only", {
  expect_true(corretto_version_matches("11.0.29.7.1", "11.0.29"))
  expect_true(corretto_version_matches("11.0.29.7.1", "11.0.29.7.1"))
  expect_false(corretto_version_matches("11.0.29.7.1", "11.0.2"))
  expect_false(corretto_version_matches("21.0.13.0.11", "2"))

  index <- list(linux = list(x64 = list(jdk = list(`11` = list(`tar.gz` = list(
    resource = "/downloads/resources/11.0.29.7.1/amazon-corretto-11.0.29.7.1-linux-x64.tar.gz",
    checksum_sha256 = "abc"
  ))))))
  local_mocked_bindings(read_json_url = function(...) index)
  expect_error(resolve_corretto_metadata("11.0.2", "linux", "x64"), "not available")
  expect_equal(resolve_corretto_metadata("11.0.29", "linux", "x64")$semver, "11.0.29.7.1")
})

test_that("cache and project paths starting with ~ are listed", {
  skip_on_os("windows")
  home <- withr::local_tempdir()
  withr::local_envvar(HOME = home)
  dir.create(file.path(home, "cache", "installed", "linux", "x64", "Corretto", "native", "21", "bin"), recursive = TRUE)
  dir.create(file.path(home, "cache", "installed", "linux", "x64", "17", "bin"), recursive = TRUE)

  cache <- java_list_installed(cache_path = "~/cache")
  expect_setequal(cache$version, c("21", "17"))
  expect_setequal(cache$distribution, c("Corretto", "unknown"))

  dir.create(file.path(home, "proj", "rjavaenv", "linux", "x64", "21", "bin"), recursive = TRUE)
  expect_equal(java_list_project("~/proj")$version, "21")
})
