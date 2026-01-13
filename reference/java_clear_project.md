# Clear the Java versions symlinked in the current project

Clear the Java versions symlinked in the current project

## Usage

``` r
java_clear_project(project_path = NULL, check = TRUE, delete_all = FALSE)
```

## Arguments

- project_path:

  The project directory to clear. Defaults to the current working
  directory.

- check:

  Whether to list the contents of the cache directory before clearing
  it. Defaults to TRUE.

- delete_all:

  Whether to delete all items without prompting. Defaults to FALSE.

## Value

A message indicating whether the symlinks were cleared or not.

## Examples

``` r
if (interactive()) {
  java_clear_project()
}
```
