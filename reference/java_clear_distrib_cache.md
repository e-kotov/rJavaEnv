# Clear the Java distributions cache folder

Clear the Java distributions cache folder

## Usage

``` r
java_clear_distrib_cache(
  cache_path = getOption("rJavaEnv.cache_path"),
  check = TRUE,
  delete_all = FALSE
)
```

## Arguments

- cache_path:

  The cache directory to clear. Defaults to the user-specific data
  directory.

- check:

  Whether to list the contents of the cache directory before clearing
  it. Defaults to TRUE.

- delete_all:

  Whether to delete all items without prompting. Defaults to FALSE.

## Value

A message indicating whether the cache was cleared or not.
