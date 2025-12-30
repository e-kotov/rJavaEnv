# Check if rJava is initialized and warn if so

Checks if the rJava package is currently loaded in the session. If it
is, issues an informative alert explaining that rJava path-locking
prevents new JAVA_HOME settings from taking effect for rJava itself.

## Usage

``` r
check_rjava_initialized(quiet = FALSE)
```

## Arguments

- quiet:

  Logical. If TRUE, suppresses the alert.

## Value

Logical. TRUE if rJava is loaded, FALSE otherwise.
