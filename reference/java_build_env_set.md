# Set up the environment for building R packages with Java dependencies from source

This function configures the current R session with the necessary
environment variables to compile Java-dependent packages like 'rJava'
from source. **Note: this function is still experimental.**

## Usage

``` r
java_build_env_set(
  java_home = Sys.getenv("JAVA_HOME"),
  where = c("session", "project", "both"),
  project_path = NULL,
  quiet = FALSE
)
```

## Arguments

- java_home:

  The path to the desired `JAVA_HOME`. Defaults to the value of the
  `JAVA_HOME` environment variable.

- where:

  Where to set the build environment: "session", "project", or "both".
  Defaults to "session". When "both" or "project" is selected, the
  function updates the .Rprofile file in the project directory.

- project_path:

  The path to the project directory, required when `where` is "project"
  or "both". Defaults to the current working directory.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

## Value

Invisibly returns `NULL` after setting the environment variables.

## Examples

``` r
if (FALSE) { # \dontrun{
# Download and install Java 17
java_17_distrib <- java_download(version = "17", temp_dir = TRUE)
java_home_path <- java_install(
  java_distrib_path = java_17_distrib,
  project_path = tempdir(),
  autoset_java_env = FALSE # Manually set env
)

# Set up the build environment in the current session
java_build_env_set(java_home = java_home_path)

# Now, install rJava from source
install.packages("rJava", type = "source", repos = "https://cloud.r-project.org")
} # }
```
