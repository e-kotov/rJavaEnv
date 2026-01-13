# Set Java environment for the current scope

Sets `JAVA_HOME` and `PATH` to the specified Java version for the
remainder of the current function or scope. The environment is
automatically restored when the scope exits.

## Usage

``` r
local_java_env(
  version,
  type = c("exact", "min"),
  distribution = "Corretto",
  install = TRUE,
  accept_system_java = TRUE,
  quiet = TRUE,
  .local_envir = parent.frame(),
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

- .local_envir:

  The environment to apply the scope to. Defaults to the calling frame.

- .use_cache:

  Logical. If `TRUE`, uses cached results for Java version checks,
  improving performance in repeated calls (e.g., inside loops).

## Value

Invisibly returns the path to the selected JAVA_HOME.

## Details

This is the recommended way for package developers to use Java
executables (via `system2` or `processx`) without permanently altering
the user's global environment.

## Warning - Not for rJava

**Do not use this function if your package depends on rJava.** rJava
locks the JVM at initialization and cannot switch versions within a
session. If you load an rJava-dependent package inside a
`local_java_env()` scope, rJava will lock to the scoped version, but
after the scope exits, `JAVA_HOME` will revert while rJava remains
locked to the old version. For rJava packages, use
[`java_ensure()`](https://www.ekotov.pro/rJavaEnv/reference/java_ensure.md)
at the start of the R session instead.

## Examples

``` r
if (FALSE) { # \dontrun{
# Using system2
my_tool_wrapper <- function() {
  rJavaEnv::local_java_env(version = 21)
  system2("java", "-version")
} # Environment restored automatically here

# Using processx
# run_java_jar <- function(jar_path, args) {
#  rJavaEnv::local_java_env(version = 21)
#  processx::run("java", c("-jar", jar_path, args))
# }

# With caching for repeated calls
# process_files <- function(files) {
#  for (f in files) {
#    rJavaEnv::local_java_env(version = 21, .use_cache = TRUE)
#   processx::run("java", c("-jar", "processor.jar", f))
#  }
# }
} # }
```
