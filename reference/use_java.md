# Install specified Java version and set the `JAVA_HOME` and `PATH` environment variables in current R session

Using specified Java version, set the `JAVA_HOME` and `PATH` environment
variables in the current R session. If Java distribtuion has not been
downloaded yet, download it. If it was not installed into cache
directory yet, install it there and then set the environment variables.
This function first checks if the requested version is already present
in the `rJavaEnv` cache. If found, it sets the environment immediately
without downloading. If not found, it downloads and unpacks the
distribution.

This is intended as a quick and easy way to use different Java versions
in R scripts that are in the same project, but require different Java
versions. For example, one could use this in scripts that are called by
`targets` package or `callr` package.

## Usage

``` r
use_java(
  version = NULL,
  distribution = "Corretto",
  backend = getOption("rJavaEnv.backend", "native"),
  cache_path = getOption("rJavaEnv.cache_path"),
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  quiet = TRUE,
  ._skip_rjava_check = FALSE
)
```

## Arguments

- version:

  Java version specification. Accepts:

  - **Major version** (e.g., `21`, `17`): Downloads the latest release
    for that major version.

  - **Specific version** (e.g., `"21.0.9"`, `"11.0.29"`): Requests that
    exact release. Only
    [`java_resolve()`](https://www.ekotov.pro/rJavaEnv/reference/java_resolve.md)
    and functions built on it check the installed runtime version.

  - **SDKMAN identifier** (e.g., `"25.0.1-amzn"`, `"24.0.2-open"`): Uses
    the SDKMAN backend automatically. When an identifier is detected,
    the `distribution` and `backend` arguments are **ignored** and
    derived from the identifier. Find available identifiers in the
    `identifier` column of
    [`java_list_available`](https://www.ekotov.pro/rJavaEnv/reference/java_list_available.md)`(backend = "sdkman")`.

- distribution:

  The Java distribution to download. Defaults to "Corretto". Ignored if
  `version` is a SDKMAN identifier.

- backend:

  The download backend used (e.g., "native", "sdkman"). If NULL, uses
  attributes from java_distrib_path or defaults to "unknown".

- cache_path:

  The destination directory to download the Java distribution to.
  Defaults to a user-specific data directory.

- platform:

  The platform for which to download the Java distribution. Defaults to
  the current platform.

- arch:

  The architecture for which to download the Java distribution. Defaults
  to the current architecture.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

- .\_skip_rjava_check:

  Internal. If TRUE, skip the rJava initialization check.

## Value

Logical. Returns `TRUE` invisibly on success. Prints status messages if
`quiet` is set to `FALSE`.

## rJava Path-Locking

**Important for *rJava* Users**: This function sets environment
variables (JAVA_HOME, PATH) that affect both command-line Java tools and
*rJava* initialization. Configure Java **before loading rJava**,
including before
[`requireNamespace("rJava")`](https://www.rforge.net/rJava/) or loading
packages that import it. Loading the namespace can resolve and lock the
JVM library path even before `.jinit()` starts the JVM. See
<https://github.com/s-u/rJava/issues/334> and
<https://github.com/s-u/rJava/issues/25>.

Once rJava has loaded, restart R before selecting another JVM, or use
[`with_rjava_env()`](https://www.ekotov.pro/rJavaEnv/reference/with_rjava_env.md)
to run with a different JVM in a fresh R process.
[`java_check_compatibility()`](https://www.ekotov.pro/rJavaEnv/reference/java_check_compatibility.md)
does not load rJava or initialize a JVM.
[`java_check_version_rjava()`](https://www.ekotov.pro/rJavaEnv/reference/java_check_version_rjava.md)
performs its probe in a separate R process.

For command-line Java tools that don't use *rJava*, this function can be
called at any time to switch Java versions for subsequent system calls.

## Examples

``` r
if (FALSE) { # \dontrun{

# set cache directory for Java to be in temporary directory
options(rJavaEnv.cache_path = tempdir())

# For end users: Install and set Java BEFORE loading rJava packages
use_java(21)
# library(myRJavaPackage)  # Now uses Java 21

# For command-line Java tools (no rJava involved):
# Can switch versions between system calls
use_java(8)
system2("java", "-version")  # Shows Java 8
use_java(17)
system2("java", "-version")  # Shows Java 17

# WARNING: Do NOT do this with rJava packages:
# library(rJava)          # Initializes with system Java
# use_java(21)            # Too late! rJava is already locked
# rJava still uses the Java version from before use_java() call

} # }
```
