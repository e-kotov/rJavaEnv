# Resolve path to specific Java version

Finds or installs Java and returns the path to JAVA_HOME. This function
does not modify any environment variables.

## Usage

``` r
java_resolve(
  version = NULL,
  type = c("exact", "min"),
  distribution = "Corretto",
  install = TRUE,
  accept_system_java = TRUE,
  quiet = FALSE,
  cache_path = getOption("rJavaEnv.cache_path"),
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  .use_cache = FALSE
)
```

## Arguments

- version:

  Integer or character. **Required.** The Java version you need (e.g.,
  17, 21). Defaults to `NULL`, which is invalid and will trigger a
  validation error; callers should always provide a non-`NULL` value
  explicitly.

- type:

  Character. `"exact"` (default) checks for exact version match. `"min"`
  checks for version \>= `version`.

- distribution:

  Character. The Java distribution to download. Defaults to "Corretto".

- install:

  Logical. If `TRUE` (default), attempts to download/install if missing.
  If `FALSE`, returns `FALSE` if the version is not found.

- accept_system_java:

  Logical. If `TRUE` (default), the function will scan the system for
  existing Java installations (using `JAVA_HOME`, `PATH`, and
  OS-specific locations). If a system Java matching the `version` and
  `type` requirements is found, it will be used. Set to `FALSE` to
  ignore system installations and strictly use an `rJavaEnv` managed
  version.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

- cache_path:

  The destination directory to download the Java distribution to.
  Defaults to a user-specific data directory.

- platform:

  The platform for which to download the Java distribution. Defaults to
  the current platform.

- arch:

  The architecture for which to download the Java distribution. Defaults
  to the current architecture.

- .use_cache:

  A `logical` value controlling caching behavior. If `FALSE` (default),
  performs a fresh check each time (safe, reflects current state). If
  `TRUE`, uses session-scoped cached results for performance in loops or
  repeated calls.

  **Caching Behavior:**

  - Session-scoped: Cache is cleared when R restarts

  - Key-based for version checks: Changes to JAVA_HOME create new cache
    entries

  - System-wide for scanning: Always recalculates current default Java

  **Performance Benefits:**

  - First call: ~37-209ms (depending on operation)

  - Cached calls: \<1ms

  - Prevents 30-100ms delays on every call in performance-critical code

  **When to Enable:**

  - Package initialization code (`.onLoad` or similar)

  - Loops calling the same function multiple times

  - Performance-critical paths with frequent version checks

  **When to Keep Default (FALSE):**

  - Interactive use (one-off checks)

  - When you need current data reflecting recent Java installations

  - General-purpose function calls that aren't time-critical

## Value

Character string (Path to JAVA_HOME)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get path to Java 21 (installing if necessary)
path <- java_resolve(version = 21, install = TRUE)
} # }
```
