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
if (FALSE) { # \dontrun{
# List all system Java installations
java_find_system()

# Use cache for faster repeated calls if you are using it in your R package
java_find_system(.use_cache = TRUE)
} # }
```
