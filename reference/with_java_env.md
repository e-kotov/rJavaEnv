# Execute code with a specific Java environment

Temporarily sets `JAVA_HOME` and `PATH` for the duration of the provided
code block, then restores the previous environment.

## Usage

``` r
with_java_env(version, code, ...)
```

## Arguments

- version:

  Java version specification. Accepts:

  - **Major version** (e.g., `21`, `17`): Downloads the latest release
    for that major version.

  - **Specific version** (e.g., `"21.0.9"`, `"11.0.29"`): Downloads the
    exact version.

  - **SDKMAN identifier** (e.g., `"25.0.1-amzn"`, `"24.0.2-open"`): Uses
    the SDKMAN backend automatically. When an identifier is detected,
    the `distribution` and `backend` arguments are **ignored** and
    derived from the identifier. Find available identifiers in the
    `identifier` column of
    [`java_list_available`](https://www.ekotov.pro/rJavaEnv/reference/java_list_available.md)`(backend = "sdkman")`.

- code:

  The code to execute with the temporary Java environment.

- ...:

  Additional arguments passed to
  [`local_java_env()`](https://www.ekotov.pro/rJavaEnv/reference/local_java_env.md).

## Value

The result of executing `code`.

## Warning - Not for rJava

**Do not use this function if your package depends on rJava.** See
[`local_java_env()`](https://www.ekotov.pro/rJavaEnv/reference/local_java_env.md)
for details on why rJava is incompatible with scoped Java switching.

## Examples

``` r
# \donttest{
# Using system2
rJavaEnv::with_java_env(version = 21, {
  system2("java", "-version")
})

# Using processx
# rJavaEnv::with_java_env(version = 21, {
#  processx::run("java", c("-jar", "tool.jar", "--help"))
# })
# }
```
