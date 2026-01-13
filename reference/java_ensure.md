# Ensure specific Java version is set

Checks for a specific Java version in the following order:

1.  Checks if the currently active session has the required version.

2.  (Optional) Scans system for installed Java (via `java_find_system`).

3.  Checks if the required version is already cached in `rJavaEnv`'s
    installed cache.

4.  If none found, downloads and installs the version (if
    `install = TRUE`).

This function is designed to be "lazy": it will do nothing if a valid
Java version is already detected, making it safe to use in scripts or
package startup code (provided `install = FALSE`).

## Usage

``` r
java_ensure(
  version = NULL,
  type = c("exact", "min"),
  accept_system_java = TRUE,
  install = TRUE,
  distribution = "Corretto",
  backend = getOption("rJavaEnv.backend", "native"),
  check_against = c("rJava", "cmd"),
  quiet = FALSE,
  cache_path = getOption("rJavaEnv.cache_path"),
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  .use_cache = FALSE,
  .check_rjava_fun = check_rjava_initialized,
  .rjava_ver_fun = java_check_current_rjava_version
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

- accept_system_java:

  Logical. If `TRUE` (default), the function will scan the system for
  existing Java installations (using `JAVA_HOME`, `PATH`, and
  OS-specific locations). If a system Java matching the `version` and
  `type` requirements is found, it will be used. Set to `FALSE` to
  ignore system installations and strictly use an `rJavaEnv` managed
  version.

- install:

  Logical. If `TRUE` (default), attempts to download/install if missing.
  If `FALSE`, returns `FALSE` if the version is not found.

- distribution:

  Character. The Java distribution to download. Defaults to "Corretto".
  Ignored if `version` is a SDKMAN identifier.

- backend:

  Download backend to use. One of "native" (vendor APIs) or "sdkman".
  Defaults to "native". Can also be set globally via
  `options(rJavaEnv.backend = "sdkman")`.

- check_against:

  Character. Controls which context validity the function checks
  against.

  - `"rJava"` (default): Checks if the requested version can be enforced
    for `rJava`. If `rJava` is already initialized and locked to a
    different version, this will error, as the requested version cannot
    be enforced for the active `rJava` session.

  - `"cmd"`: Checks if the requested version can be enforced for
    command-line use. This ignores the state of `rJava` and allows
    setting the environment variables even if `rJava` is locked to a
    different version.

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

- .check_rjava_fun:

  Internal. Function to check if rJava is initialized.

- .rjava_ver_fun:

  Internal. Function to get the current rJava version.

## Value

Logical. `TRUE` if the requirement is met (active or set successfully),
`FALSE` otherwise.

## Additional Notes

If rJava is already loaded, this function will warn you but will not
prevent the environment variable change (which won't help rJava at that
point).

## rJava Path-Locking

**Important for rJava Users**: This function sets environment variables
(JAVA_HOME, PATH) that affect both command-line Java tools and rJava
initialization. However, due to rJava's path-locking behavior when
[`.jinit`](https://rdrr.io/pkg/rJava/man/jinit.html) is called (see
<https://github.com/s-u/rJava/issues/25>,
<https://github.com/s-u/rJava/issues/249>, and
<https://github.com/s-u/rJava/issues/334>), this function must be called
**BEFORE** [`.jinit`](https://rdrr.io/pkg/rJava/man/jinit.html) is
invoked. Once [`.jinit`](https://rdrr.io/pkg/rJava/man/jinit.html)
initializes, the Java version is locked for that R session and cannot be
changed without restarting R.

[`.jinit`](https://rdrr.io/pkg/rJava/man/jinit.html) is invoked (and
Java locked) when you:

- Explicitly call [`library(rJava)`](http://www.rforge.net/rJava/)

- Load any package that imports rJava (which auto-loads it as a
  dependency)

- Even just use IDE autocomplete with `rJava::` (this triggers
  initialization!)

- Call any rJava-dependent function

Once any of these happen, the Java version used by rJava for that
session is locked in. For command-line Java tools that don't use rJava,
this function can be called at any time to switch Java versions for
subsequent system calls.

## See also

[`vignette("for-developers")`](https://www.ekotov.pro/rJavaEnv/articles/for-developers.md)
for comprehensive guidance on integrating `rJavaEnv` into your package,
including how to use `java_ensure()` in different scenarios and detailed
use cases with `type` and `accept_system_java` parameters.

## Examples

``` r
# \donttest{
# For end users: Ensure Java 21 is ready BEFORE loading rJava packages
library(rJavaEnv)
java_ensure(version = 21, type = "min")
#> ℹ Checking system for existing Java installations...
#> ✔ Found valid system Java 25 at /usr/lib/jvm/temurin-25-jdk-amd64
#> ✔ Current R Session: JAVA_HOME and PATH set to /usr/lib/jvm/temurin-25-jdk-amd64
#> ℹ On Linux, for rJava to work correctly, `libjvm.so` was dynamically loaded in
#>   the current session.
#>   To make this change permanent for installing rJava-dependent packages from
#>   source, you may need to reconfigure Java.
#>   See <https://solutions.posit.co/envs-pkgs/using-rjava/#reconfigure-r> for
#>   details.
#>   If you have admin rights, run the following in your terminal:
#>   `R CMD javareconf JAVA_HOME=/usr/lib/jvm/temurin-25-jdk-amd64`
#>   If you do not have admin rights, run:
#>   `R CMD javareconf JAVA_HOME=/usr/lib/jvm/temurin-25-jdk-amd64 -e`
# Now safe to load packages that depend on rJava
# library(myRJavaPackage)

# For packages using command-line Java (not rJava):
# Can use java_ensure() within functions to set Java before calling system tools
my_java_tool <- function() {
  java_ensure(version = 17)
  system2("java", c("-jar", "tool.jar"))
}
# }
```
