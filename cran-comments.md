# rJavaEnv 0.3.0 (2025-04-04)


## New features

- `Java` version (currently still only for `Amazon Corretto`) is now determined dynamically using the official GitHub `json` with releases, so when new `Java` version becomes available, you will not be depenent on `rJavaEnv` to be updated. As a fallback, versions up to 24 are hardcoded.

- Added `force` argument to `java_download()`. When set to `TRUE`, allows to overwrite the distribution file if it already exist in the cache. This save the trouble of deleting the cached file with `java_clear()` before re-downloading.

- Added a new function `java_valid_versions()` allows to retrieve a list of all available `Java` versions for the current automatically detected OS and CPU architecture, or user-specified platform and architecture.

## Improvements

- Better command line `Java` detection (thanks to Jonas Lieth)

- Test coverage is now 7.2%
