# Unpack a Java distribution file into cache directory

Unpack the Java distribution file into cache directory and return the
path to the unpacked Java directory with Java binaries.

## Usage

``` r
java_unpack(java_distrib_path, quiet = FALSE, force = FALSE)
```

## Arguments

- java_distrib_path:

  A `character` vector of length 1 containing the path to the Java
  distribution file.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

- force:

  A logical. Whether to overwrite an existing installation. Defaults to
  `FALSE`.

## Value

A `character` vector containing of length 1 containing the path to the
unpacked Java directory.

## Examples

``` r
if (FALSE) { # \dontrun{

# set cache dir to temporary directory
options(rJavaEnv.cache_path = tempdir())

# download Java 17 distrib and unpack it into cache dir
java_17_distrib <- java_download(version = "17")
java_home <- java_unpack(java_distrib_path = java_17_distrib)

# set the JAVA_HOME environment variable in the current session
# to the cache dir without touching any files in the current project directory
java_env_set(where = "session", java_home = java_home)
} # }
```
