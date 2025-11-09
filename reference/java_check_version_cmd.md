# Check installed Java version using terminal commands

Check installed Java version using terminal commands

## Usage

``` r
java_check_version_cmd(java_home = NULL, quiet = FALSE)
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
java_check_version_cmd()
#> JAVA_HOME: /usr/lib/jvm/temurin-17-jdk-amd64
#> Java path: /usr/bin/java
#> Java version: "openjdk version \"17.0.17\" 2025-10-21 OpenJDK Runtime
#> Environment Temurin-17.0.17+10 (build 17.0.17+10) OpenJDK 64-Bit Server VM
#> Temurin-17.0.17+10 (build 17.0.17+10, mixed mode, sharing)"
#> [1] "17"
```
