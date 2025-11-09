# Install Java from a distribution file

Unpack Java distribution file into cache directory and link the
installation into a project directory, optionally setting the
`JAVA_HOME` and `PATH` environment variables to the Java version that
was just installed.

## Usage

``` r
java_install(
  java_distrib_path,
  project_path = NULL,
  autoset_java_env = TRUE,
  quiet = FALSE,
  force = FALSE
)
```

## Arguments

- java_distrib_path:

  A `character` vector of length 1 containing the path to the Java
  distribution file.

- project_path:

  A `character` vector of length 1 containing the project directory
  where Java should be installed. If not specified or `NULL`, defaults
  to the current working directory.

- autoset_java_env:

  A `logical` indicating whether to set the `JAVA_HOME` and `PATH`
  environment variables to the installed Java directory. Defaults to
  `TRUE`.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

- force:

  A logical. Whether to overwrite an existing installation. Defaults to
  `FALSE`.

## Value

The path to the installed Java directory.

## Examples

``` r
if (FALSE) { # \dontrun{

# set cache dir to temporary directory
options(rJavaEnv.cache_path = tempdir())
# download, install and autoset environmnet variables for Java 17
java_17_distrib <- java_download(version = "17")
java_install(java_distrib_path = java_17_distrib, project_path = tempdir())
} # }
```
