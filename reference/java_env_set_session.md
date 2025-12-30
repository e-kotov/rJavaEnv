# Set the JAVA_HOME and PATH environment variables for the current session

Set the JAVA_HOME and PATH environment variables for the current session

## Usage

``` r
java_env_set_session(java_home, quiet = FALSE, ._skip_rjava_check = FALSE)
```

## Arguments

- java_home:

  The path to the desired JAVA_HOME.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

- .\_skip_rjava_check:

  Internal. If TRUE, skip the rJava initialization check.
