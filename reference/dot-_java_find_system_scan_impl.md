# Scan system for Java installations (cacheable part)

Internal function that scans the system for installed Java Development
Kits (JDKs) without calculating the `is_default` flag. This function is
designed to be cached.

Includes `JAVA_HOME`, versioned `JAVA_HOME_<major>` variables
(optionally suffixed with an architecture), PATH and standard OS
locations. Discovery does not load rJava or a JVM library in the calling
process.

**Note**: This function only returns true system installations. Java
installations managed by rJavaEnv (stored in the package cache) are
explicitly excluded, even if `JAVA_HOME` or `PATH` currently point to
them.

## Usage

``` r
._java_find_system_scan_impl(quiet = TRUE)
```

## Arguments

- quiet:

  Logical. If `TRUE`, suppresses informational messages.

## Value

A data frame with columns:

- `java_home`: Character. Path to the Java home directory.

- `version`: Character. Major Java version (e.g., "17", "21").

- `is_default`: Logical. Always `FALSE` in this function (set by
  caller). Returns an empty data frame if no Java installations are
  found.
