# List the Java versions symlinked in the current project

List the Java versions symlinked in the current project

## Usage

``` r
java_list_in_project(
  project_path = NULL,
  output = c("data.frame", "vector"),
  quiet = TRUE
)
```

## Arguments

- project_path:

  The project directory to list. Defaults to the current working
  directory.

- output:

  The format of the output: "data.frame" or "vector". Defaults to
  "data.frame".

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

## Value

A data frame or character vector with the symlinked Java versions in the
project directory.
