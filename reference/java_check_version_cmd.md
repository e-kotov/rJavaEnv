# Check installed Java version using terminal commands

Check installed Java version using terminal commands

## Usage

``` r
java_check_version_cmd(java_home = NULL, quiet = FALSE, .use_cache = FALSE)
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
`FALSE` if JAVA_HOME is not set or the Java executable cannot be found.

## Performance

This function is memoised (cached) within the R session using the
effective JAVA_HOME as cache key. First call for a given JAVA_HOME:
~37ms. Subsequent calls (with `.use_cache = TRUE`): \<1ms. When you
switch Java versions via
[`use_java()`](https://www.ekotov.pro/rJavaEnv/reference/use_java.md),
JAVA_HOME changes, creating a new cache entry. Cache is session-scoped.

## Examples

``` r
if (FALSE) { # \dontrun{
java_check_version_cmd()
} # }
```
