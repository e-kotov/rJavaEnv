# Manage Java installations and distributions caches

Wrapper function to clear the Java symlinked in the current project,
installed, or distributions caches.

## Usage

``` r
java_clear(
  type = c("project", "installed", "distrib"),
  target_dir = NULL,
  check = TRUE,
  delete_all = FALSE
)
```

## Arguments

- type:

  What to clear: "project" - remove symlinks to install cache in the
  current project, "installed" - remove installed Java versions,
  "distrib" - remove downloaded Java distributions.

- target_dir:

  The directory to clear. Defaults to current working directory for
  "project" and user-specific data directory for "installed" and
  "distrib". Not recommended to change.

- check:

  Whether to list the contents of the cache directory before clearing
  it. Defaults to TRUE.

- delete_all:

  Whether to delete all items without prompting. Defaults to FALSE.

## Value

A message indicating whether the cache was cleared or not.

## Examples

``` r
if (interactive()) {
  java_clear("project")
  java_clear("installed")
  java_clear("distrib")
}
```
