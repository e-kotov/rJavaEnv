# List the contents of the Java distributions cache folder

List the contents of the Java distributions cache folder

## Usage

``` r
java_list_distrib(
  cache_path = getOption("rJavaEnv.cache_path"),
  output = c("data.frame", "vector"),
  quiet = TRUE
)
```

## Arguments

- cache_path:

  The destination directory to download the Java distribution to.
  Defaults to a user-specific data directory.

- output:

  The format of the output: ``` data.frame`` or  ```vector“. Defaults to
  `data.frame`.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

## Value

A data frame or character vector with the contents of the cache
directory.

## Examples

``` r
# \donttest{
  java_list_distrib()
#> ✖ No Java distributions have been downloaded.
#> character(0)
# }
```
