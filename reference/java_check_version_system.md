# Check and print Java path and version using system commands

This function checks the Java executable path and retrieves the Java
version, then prints these details to the console.

## Usage

``` r
java_check_version_system(quiet)
```

## Arguments

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

## Value

A `character` vector of length 1 containing the major Java version.
