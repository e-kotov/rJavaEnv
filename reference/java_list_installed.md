# List the contents of the Java installations cache folder

List the contents of the Java installations cache folder

## Usage

``` r
java_list_installed(
  output = c("data.frame", "vector"),
  quiet = TRUE,
  cache_path = getOption("rJavaEnv.cache_path")
)
```

## Arguments

- output:

  The format of the output: ``` data.frame`` or  ```vector“. Defaults to
  `data.frame`.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

- cache_path:

  The destination directory to download the Java distribution to.
  Defaults to a user-specific data directory.

## Value

A data frame or character vector with the contents of the cache
directory.

## Examples

``` r
# List the contents
java_list_installed()
#>                                                                    path
#> 1 /home/runner/.cache/R/rJavaEnv/installed/linux/x64/Corretto/native/17
#>   platform arch distribution backend version
#> 1    linux  x64     Corretto  native      17
```
