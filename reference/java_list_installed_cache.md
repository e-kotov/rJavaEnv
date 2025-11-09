# List the contents of the Java installations cache folder

List the contents of the Java installations cache folder

## Usage

``` r
java_list_installed_cache(
  output = c("data.frame", "vector"),
  quiet = TRUE,
  cache_path = getOption("rJavaEnv.cache_path")
)
```

## Arguments

- output:

  The format of the output: "data.frame" or "vector". Defaults to
  "data.frame".

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

- cache_path:

  The cache directory to list. Defaults to the user-specific data
  directory. Not recommended to change.

## Value

A data frame or character vector with the contents of the cache
directory.
