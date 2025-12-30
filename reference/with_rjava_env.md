# Execute rJava code in a separate process with specific Java version

Runs the provided function in a fresh R subprocess where `rJava` has not
yet been loaded. This allows you to enforce a specific Java version for
`rJava` operations without affecting the main R session or requiring a
restart.

## Usage

``` r
with_rjava_env(
  version,
  func,
  args = list(),
  distribution = "Corretto",
  install = TRUE,
  accept_system_java = TRUE,
  quiet = TRUE,
  libpath = .libPaths()
)
```

## Arguments

- version:

  Integer or character. **Required.** The Java version you need (e.g.,
  17, 21). Defaults to `NULL`, which is invalid and will trigger a
  validation error; callers should always provide a non-`NULL` value
  explicitly.

- func:

  The function to execute in the subprocess.

- args:

  A list of arguments to pass to `func`.

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

- libpath:

  Optional character vector of library paths to use in the subprocess.
  Defaults to [`.libPaths()`](https://rdrr.io/r/base/libPaths.html).

## Value

The result of `func`.

## Details

This function requires the callr package.

## Examples

``` r
if (FALSE) { # \dontrun{
# Run a function using Java 21 in a subprocess
result <- with_rjava_env(
  version = 21,
  func = function(x) {
    library(rJava)
    .jinit()
    .jcall("java.lang.System", "S", "getProperty", "java.version")
  },
  args = list(x = 1)
)
print(result)
} # }
```
