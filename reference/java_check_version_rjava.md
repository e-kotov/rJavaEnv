# Check Java Version with a Specified JAVA_HOME Using a Separate R Session

This function sets the JAVA_HOME environment variable, initializes the
JVM using rJava, and prints the Java version that would be used if the
user sets the given JAVA_HOME in the current R session. This check is
performed in a separate R session to avoid having to reload the current
R session. The reason for this is that once Java is initialized in an R
session, it cannot be uninitialized unless the current R session is
restarted.

## Usage

``` r
java_check_version_rjava(java_home = NULL, quiet = FALSE, .use_cache = FALSE)
```

## Arguments

- java_home:

  Path to Java home directory. If NULL, the function uses the JAVA_HOME
  environment variable.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

- .use_cache:

  Logical. If `TRUE`, uses cached results for repeated calls with the
  same JAVA_HOME. If `FALSE` (default), forces a fresh check. Set to
  `TRUE` for performance in loops or repeated checks within the same
  session.

## Value

A `character` vector of length 1 containing the major Java version, or
`FALSE` if rJava is not installed or the version check fails.

## Examples

``` r
# \donttest{
java_check_version_rjava()
#> Using current session's JAVA_HOME:
#> /home/runner/.cache/R/rJavaEnv/installed/linux/x64/Corretto/native/17
#> With the current session's JAVA_HOME rJava and other rJava/Java-based packages
#> will use Java version: "17.0.18"
#> [1] "17"
# }
```
