# Check the Java version currently used by the loaded rJava package

Safely queries the `rJava` package (if loaded) to determine which Java
version it is actually using.

## Usage

``` r
java_check_current_rjava_version()
```

## Value

A character string representing the major Java version (e.g., "17",
"21", "8"), or `NULL` if `rJava` is not loaded or the version/property
could not be retrieved.
