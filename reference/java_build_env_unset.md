# Unset the Java build environment variables in the project .Rprofile

Unset the Java build environment variables in the project .Rprofile

## Usage

``` r
java_build_env_unset(project_path = NULL, quiet = FALSE)
```

## Arguments

- project_path:

  A `character` vector of length 1 containing the project directory
  where Java should be installed. If not specified or `NULL`, defaults
  to the current working directory.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

## Value

Does not return a value. Invisibly returns `NULL`.

## Examples

``` r
# Remove Java build environment settings from the current project
java_build_env_unset()
#> ! No .Rprofile found in the project directory:
#>   /home/runner/work/rJavaEnv/rJavaEnv/docs/reference
```
