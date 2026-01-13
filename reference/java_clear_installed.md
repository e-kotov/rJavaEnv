# Clear the Java installations cache folder

Clear the Java installations cache folder

## Usage

``` r
java_clear_installed(
  check = TRUE,
  delete_all = FALSE,
  cache_path = getOption("rJavaEnv.cache_path")
)
```

## Arguments

- check:

  Whether to list the contents of the cache directory before clearing
  it. Defaults to TRUE.

- delete_all:

  Whether to delete all items without prompting. Defaults to FALSE.

- cache_path:

  The destination directory to download the Java distribution to.
  Defaults to a user-specific data directory.

## Value

A message indicating whether the cache was cleared or not.

## Examples

``` r
if (interactive()) {
  java_clear_installed()
}
```
