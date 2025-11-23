# rJavaEnv (development version)

## New features

- Linux support. On Linux, `libjvm.so` location is automatically detected and force-loaded via `dyn.load()`. Thanks to that, `rJava` and any depenent R packages can be installed and loaded, if repositories with pre-built packages, such as `Posit Package Manager`, is used or if you build `rJava` from source, see the `java_build_env_set()` function.

- New function `java_build_env_set()` that sets the environment (either temporarily in the current session or in `./.Rprofile` file of the current working directory) to build `rJava` from source on `macOS`, `Linux` and `Windows` platforms. It uses the current value of `JAVA_HOME` environment variable by default, so that it is more convenient to use after `java_quick_install()` or `use_java()` commands. After running `java_build_env_set()`, users can install `rJava` from source with `install.packages("rJava", type = "source")` without any additional configuration. However, users will still need some system dependencies, e.g. on Linux they will need: libpcre2-dev, libdeflate-dev, libzstd-dev, liblzma-dev, libbz2-dev, zlib1g-dev, libicu-dev. A system message with a suggested `apt-get` command is printed. On Windows, `Rtools` must be installed. On `macOS`, `Xcode Command Line Tools` must be installed. See the new vignette `Install 'rJava' from source` for more details.

- New function `java_get_home()` to get currently set `JAVA_HOME`. This is just a shortcut to `Sys.getenv("JAVA_HOME")`, as it is faster to type and can be even faster then used with autocomplete.

## Improvements

- Download progress printing in `java_download()` respects the `quiet` argument now (internally passing the value to `curl::curl_download()`).

- More robust Java version detection in `java_check_version_cmd()`.

- `java_quick_install()` now also invisibly returns the path to `JAVA_HOME`.

- Added `{rlang}` as a dependency, as `{cli}` uses it anyway for the functions that we use in `{rJavaEnv}`, but does not declare it as a dependency. Therefore this previously might have caused annoyances to the users, as after installing `{rJavaEnv}` they could not use any of the functions until they installed `{rlang}` manually.

# rJavaEnv 0.3.0

## New features

- `Java` version (currently still only for `Amazon Corretto`) is now determined dynamically using the official GitHub `json` with releases, so when new `Java` version becomes available, you will not be depenent on `rJavaEnv` to be updated. As a fallback, versions up to 24 are hardcoded.

- Added `force` argument to `java_download()`. When set to `TRUE`, allows to overwrite the distribution file if it already exist in the cache. This save the trouble of deleting the cached file with `java_clear()` before re-downloading.

- Added a new function `java_valid_versions()` allows to retrieve a list of all available `Java` versions for the current automatically detected OS and CPU architecture, or user-specified platform and architecture.

## Improvements

- Better command line `Java` detection (thanks to Jonas Lieth)

- Test coverage is now 7.2%

# rJavaEnv 0.2.2 (2024-09-13)

* Hot fix: improve robustness of setting `Java` environment in the current session with either `use_java()` or `java_quick_install()`. See bug fix below.

* Bug fix: Setting Java environment via `rJava::.jniInitialized()` rendered impossible changing Java version for `rJava`-dependent packages, because it somehow pre-initialised `rJava`

# rJavaEnv 0.2.1 (2024-09-03)

* Documentation and description clean-up

# rJavaEnv 0.2.0 (2024-08-28)

* Breaking change: `java_check_version_cmd()` and `java_check_version_rjava()` now return detected `Java` version instead of `TRUE`/`FALSE`

* New function `use_java()` to download, install and set `Java` from cache for the current sesssion, without touching the current project/working directory. This is intended for use with `targets` and `callr`.

* New vignette on using the package with `targets' and 'callr`

* Updated documentation with clearer instructions on cache folder cleanup before removing the package

* Depends on `R` > 4.0 to be able to write to the package cache directory without extra user warning. Cache cleanup and management functions are provided, as well as the documentation in both README and vignettes.

# rJavaEnv 0.1.2

* Fixed broken links in README.md

# rJavaEnv 0.1.1

* Improved documentation

* Better handling of cache directory

* Bug fixes and changes to address CRAN reviewer's comments to the first submission

# rJavaEnv 0.1.0

* Initial release
