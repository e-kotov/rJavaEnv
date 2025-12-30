# Verify rJava Compatibility (Guard)

Checks if the currently initialized `rJava` session matches the required
Java version. Intended for use in the `.onLoad` function of packages
that depend on `rJava`.

## Usage

``` r
java_check_compatibility(
  version,
  type = c("min", "exact"),
  action = c("warn", "stop", "message", "none")
)
```

## Arguments

- version:

  Integer. The required major Java version (e.g., 21).

- type:

  Character. "min" (default) checks for `>= version`. "exact" checks for
  `== version`.

- action:

  Character. What to do if incompatible:

  - "warn": Issue a warning but continue.

  - "stop": Throw an error (prevent package loading).

  - "message": Print a startup message.

  - "none": Return `FALSE` invisibly (useful for custom handling).

## Value

Logical `TRUE` if compatible, `FALSE` otherwise.

## Details

This function detects if `rJava` has already locked to a specific Java
version (which happens upon package loading) and warns the user if that
version does not match the requirement.

## Examples

``` r
if (FALSE) { # \dontrun{
# In a package .onLoad:
.onLoad <- function(libname, pkgname) {
  rJavaEnv::java_check_compatibility(version = 21, action = "warn")
}
} # }
```
