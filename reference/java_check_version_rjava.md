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
java_check_version_rjava(java_home = NULL, quiet = FALSE)
```

## Arguments

- java_home:

  Path to Java home directory. If NULL, the function uses the JAVA_HOME
  environment variable.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

## Value

A `character` vector of length 1 containing the major Java version.

## Examples

``` r
if (FALSE) { # \dontrun{
java_check_version_rjava()
} # }
```
