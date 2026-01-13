# Resolve path to specific Java version

Finds or installs Java and returns the path to JAVA_HOME. This function
does not modify any environment variables.

## Usage

``` r
java_resolve(
  version = NULL,
  type = c("exact", "min"),
  distribution = "Corretto",
  backend = getOption("rJavaEnv.backend", "native"),
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

  Java version specification. Accepts:

  - **Major version** (e.g., `21`, `17`): Downloads the latest release
    for that major version.

  - **Specific version** (e.g., `"21.0.9"`, `"11.0.29"`): Downloads the
    exact version.

  - **SDKMAN identifier** (e.g., `"25.0.1-amzn"`, `"24.0.2-open"`): Uses
    the SDKMAN backend automatically. When an identifier is detected,
    the `distribution` and `backend` arguments are **ignored** and
    derived from the identifier. Find available identifiers in the
    `identifier` column of
    [`java_list_available`](https://www.ekotov.pro/rJavaEnv/reference/java_list_available.md)`(backend = "sdkman")`.

- type:

  Character. `"exact"` (default) checks for exact version match. `"min"`
  checks for version \>= `version`.

- distribution:

  Character. The Java distribution to download. Defaults to "Corretto".
  Ignored if `version` is a SDKMAN identifier.

- backend:

  Download backend to use. One of "native" (vendor APIs) or "sdkman".
  Defaults to "native". Can also be set globally via
  `options(rJavaEnv.backend = "sdkman")`.

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
# \donttest{
# Get path to Java 21 (installing if necessary)
path <- java_resolve(version = 21, install = TRUE)
#> ℹ Checking system for existing Java installations...
#> ✔ Found valid system Java 21 at /usr/lib/jvm/java-21-openjdk-amd64
# }
```
