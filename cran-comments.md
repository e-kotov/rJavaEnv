# rJavaEnv 0.4.0

This is a feature release. It adds `java_ensure()`, `java_resolve()`, scoped
helpers for command-line and rJava use, the Temurin and Zulu distributions, a
choice between vendor APIs and SDKMAN as download backends, and support for
specific (patch-level) Java versions. See NEWS.md for details.

## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

GitHub Actions:

* macOS (latest, aarch64), R 4.6.1
* Windows (latest), R 4.6.1 and R 4.2.3
* Ubuntu (latest), R-devel, R 4.6.1 and R 4.5.3
* Ubuntu (latest), R-devel with `--as-cran` and HTML5 validation of Rd files,
  treating NOTEs as failures

## Network and downloads

Examples that download Java are wrapped in `\donttest{}` or `\dontrun{}`.
Tests that download Java are skipped on CRAN and run only when enabled through
the `RUN_JAVA_DOWNLOAD_TESTS` environment variable; other download and API
tests use mocked responses or are skipped when offline or on CRAN. Functions
that write to the user's cache, project files or `.Rprofile` ask for consent
first.

## Reverse dependencies

There is one reverse dependency on CRAN, r5r (Suggests). Its checks were not
run for this submission.
