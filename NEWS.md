# rJavaEnv (development version)

## New features

- `Java` version (currently still only for `Amazon Corretto`) is now determined dynamically using the official GitHub `json` with releases, so when new `Java` version becomes available, you will not be depenent on `rJavaEnv` to be updated. As a fallback, versions up to 24 are hardcoded.
- `force` argument in `java_download()`. When set to `TRUE`, allows to overwrite the distribution file if it already exist in the cache.
- new function `java_valid_versions()` allows to retrieve a list of all available `Java` versions for the current automatically detected OS and CPU architecture, or user-specified platform and architecture.

## Improvements

- better command line `Java` detection (thanks to Jonas Lieth)

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
