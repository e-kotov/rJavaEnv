# Discover system-wide Java installations

Scans the system for installed Java Development Kits (JDKs).
Implementation based on CMake `FindJava.cmake` logic, rJava detection,
and standard OS checks.

**Note**: This function only returns true system installations. Java
installations managed by rJavaEnv (stored in the package cache) are
explicitly excluded, even if `JAVA_HOME` or `PATH` currently point to
them.

## Usage

``` r
java_find_system(quiet = TRUE, .use_cache = FALSE)
```

## Arguments

- quiet:

  Logical. If `TRUE`, suppresses informational messages.

- .use_cache:

  Logical. If `TRUE`, uses memoisation cache for the expensive system
  scanning part. The `is_default` flag is always calculated dynamically
  based on the current `JAVA_HOME`. Default: `FALSE` (bypass cache for
  safety). Set to `TRUE` for performance in loops or repeated calls.

## Value

A data frame with columns:

- `java_home`: Character. Path to the Java home directory.

- `version`: Character. Major Java version (e.g., "17", "21").

- `is_default`: Logical. `TRUE` if this matches the current system
  default Java (determined by `JAVA_HOME` or PATH). Rows are ordered
  with the default Java first (if detected), then by version descending.
  Returns an empty data frame if no Java installations are found.

## Performance

The system scan is memoised (cached) for the session duration. First
scan: ~209ms. Subsequent scans with `.use_cache = TRUE`: \<1ms. The
`is_default` flag is always calculated fresh to reflect current
`JAVA_HOME`.

## Examples

``` r
# \donttest{
# List all system Java installations
java_find_system()
#>                            java_home version is_default
#> 1   /usr/lib/jvm/temurin-8-jdk-amd64       8      FALSE
#> 2  /usr/lib/jvm/temurin-11-jdk-amd64      11      FALSE
#> 3  /usr/lib/jvm/temurin-17-jdk-amd64      17      FALSE
#> 4 /usr/lib/jvm/java-21-openjdk-amd64      21      FALSE
#> 5  /usr/lib/jvm/temurin-21-jdk-amd64      21      FALSE
#> 6  /usr/lib/jvm/temurin-25-jdk-amd64      25      FALSE

# Use cache for faster repeated calls if you are using it in your R package
java_find_system(.use_cache = TRUE)
#>                            java_home version is_default
#> 1   /usr/lib/jvm/temurin-8-jdk-amd64       8      FALSE
#> 2  /usr/lib/jvm/temurin-11-jdk-amd64      11      FALSE
#> 3  /usr/lib/jvm/temurin-17-jdk-amd64      17      FALSE
#> 4 /usr/lib/jvm/java-21-openjdk-amd64      21      FALSE
#> 5  /usr/lib/jvm/temurin-21-jdk-amd64      21      FALSE
#> 6  /usr/lib/jvm/temurin-25-jdk-amd64      25      FALSE
# }
```
