# Execute code with a specific Java environment

Temporarily sets `JAVA_HOME` and `PATH` for the duration of the provided
code block, then restores the previous environment.

## Usage

``` r
with_java_env(version, code, ...)
```

## Arguments

- version:

  Integer or character. **Required.** The Java version you need (e.g.,
  17, 21). Defaults to `NULL`, which is invalid and will trigger a
  validation error; callers should always provide a non-`NULL` value
  explicitly.

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
if (FALSE) { # \dontrun{
# Using system2
rJavaEnv::with_java_env(version = 21, {
  system2("java", "-version")
})

# Using processx
rJavaEnv::with_java_env(version = 21, {
  processx::run("java", c("-jar", "tool.jar", "--help"))
})
} # }
```
