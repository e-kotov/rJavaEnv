# List the contents of the Java versions installed or cached

This function lists one of the following:

- `project` - list the contents of the Java symlinked/copied in the
  current project or directory specified by `target_dir`

- `distrib` - list the contents of the downloaded Java distributions
  cache in default location or specified by `target_dir`

- `installed` - list the contents of the Java installations cache
  (unpacked distributions) in default location or specified by
  `target_dir`

## Usage

``` r
java_list(
  type = c("project", "installed", "distrib"),
  output = c("data.frame", "vector"),
  quiet = TRUE,
  target_dir = NULL
)
```

## Arguments

- type:

  The type of cache to list: "distrib", "installed", or "project".
  Defaults to "project".

- output:

  The format of the output: ``` data.frame`` or  ```vector“. Defaults to
  `data.frame`.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

- target_dir:

  The cache directory to list. Defaults to the user-specific data
  directory for "distrib" and "installed", and the current working
  directory for "project".

## Value

A `dataframe` or `character` `vector` with the contents of the specified
cache or project directory.

## Examples

``` r
if (FALSE) { # \dontrun{
java_list("project")
java_list("installed")
java_list("distrib")
} # }
```
