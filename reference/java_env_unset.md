# Unset the JAVA_HOME and PATH environment variables in the project .Rprofile

Unset the JAVA_HOME and PATH environment variables in the project
.Rprofile

## Usage

``` r
java_env_unset(project_path = NULL, quiet = FALSE)
```

## Arguments

- project_path:

  A `character` vector of length 1 containing the project directory
  where Java should be installed. If not specified or `NULL`, defaults
  to the current working directory.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

## Value

Nothing. Removes the JAVA_HOME and PATH environment variables settings
from the project .Rprofile.

## Examples

``` r
# clear the JAVA_HOME and PATH environment variables in the specified project .Rprofile
java_env_unset(project_path = tempdir())
#> Removed JAVA_HOME settings from .Rprofile in '/tmp/RtmpZMc8LF/.Rprofile'
```
