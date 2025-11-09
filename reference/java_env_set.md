# Set the `JAVA_HOME` and `PATH` environment variables to a given path

Set the `JAVA_HOME` and `PATH` environment variables to a given path

## Usage

``` r
java_env_set(
  where = c("session", "both", "project"),
  java_home,
  project_path = NULL,
  quiet = FALSE
)
```

## Arguments

- where:

  Where to set the `JAVA_HOME`: "session", "project", or "both".
  Defaults to "session" and only updates the paths in the current R
  session. When "both" or "project" is selected, the function updates
  the .Rprofile file in the project directory to set the JAVA_HOME and
  PATH environment variables at the start of the R session.

- java_home:

  The path to the desired `JAVA_HOME`.

- project_path:

  A `character` vector of length 1 containing the project directory
  where Java should be installed. If not specified or `NULL`, defaults
  to the current working directory.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

## Value

Nothing. Sets the JAVA_HOME and PATH environment variables.

## Examples

``` r
if (FALSE) { # \dontrun{
# download, install Java 17
java_17_distrib <- java_download(version = "17", temp_dir = TRUE)
java_home <- java_install(
  java_distrib_path = java_17_distrib,
  project_path = tempdir(),
  autoset_java_env = FALSE
)

# now manually set the JAVA_HOME and PATH environment variables in current session
java_env_set(
  where = "session",
  java_home = java_home
)

# or set JAVA_HOME and PATH in the spefific projects' .Rprofile
java_env_set(
  where = "project",
  java_home = java_home,
  project_path = tempdir()
)

} # }
```
