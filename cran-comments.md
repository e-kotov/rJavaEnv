## Update to 0.2.0

Brings new functions based on very quick user feedback after the first release.

# rJavaEnv 0.2.0 (2024-08-28)

* Breaking change: `java_check_version_cmd()` and `java_check_version_rjava()` now return detected `Java` version instead of `TRUE`/`FALSE`

* New function `use_java()` to download, install and set `Java` from cache for the current sesssion, without touching the current project/working directory. This is intended for use with `targets` and `callr`.

* New vignette on using the package with `targets' and 'callr`

* Updated documentation with clearer instructions on cache folder cleanup before removing the package

* Depends on `R` > 4.0 to be able to write to the package cache directory without extra user warning. Cache cleanup and management functions are provided, as well as the documentation in both README and vignettes.
