# Clear the Java installations cache folder

Clear the Java installations cache folder

## Usage

``` r
java_clear_installed_cache(
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

  Whether to delete all installations without prompting. Defaults to
  FALSE.

- cache_path:

  The cache directory to clear. Defaults to the user-specific data
  directory.

## Value

A message indicating whether the cache was cleared or not.
