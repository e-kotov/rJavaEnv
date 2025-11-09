# Clear the Java versions symlinked in the current project

Clear the Java versions symlinked in the current project

## Usage

``` r
java_clear_in_project(project_path = NULL, check = TRUE, delete_all = FALSE)
```

## Arguments

- project_path:

  The project directory to clear. Defaults to the current working
  directory.

- check:

  Whether to list the symlinked Java versions before clearing them.
  Defaults to TRUE.

- delete_all:

  Whether to delete all symlinks without prompting. Defaults to FALSE.

## Value

A message indicating whether the symlinks were cleared or not.
