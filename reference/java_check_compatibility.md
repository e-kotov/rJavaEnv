# Verify rJava Compatibility (Guard)

Checks if the currently initialized `rJava` session matches the required
Java version. Use after your package has deliberately started rJava, for
example at the start of a Java-dependent operation. It is safe to call
earlier, but then returns `FALSE` because compatibility has not been
verified.

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

This function reads an already running JVM without loading rJava or
calling `.jinit()`. If no JVM is running, compatibility is unverified
and the function returns `FALSE`, using `action` to report the result.
For a check in a fresh subprocess, use
[`java_check_version_rjava()`](https://www.ekotov.pro/rJavaEnv/reference/java_check_version_rjava.md).
A loaded rJava namespace may already have locked its library path even
if its JVM is not running.

## Examples

``` r
if (FALSE) { # \dontrun{
# After deliberately initializing rJava in a Java-dependent operation:
rJava::.jinit()
java_check_compatibility(version = 21, action = "stop")
} # }
```
