# Install specified Java version and set the `JAVA_HOME` and `PATH` environment variables in current R session

Using specified Java version, set the `JAVA_HOME` and `PATH` environment
variables in the current R session. If Java distribtuion has not been
downloaded yet, download it. If it was not installed into cache
directory yet, install it there and then set the environment variables.
This is intended as a quick and easy way to use different Java versions
in R scripts that are in the same project, but require different Java
versions. For example, one could use this in scripts that are called by
`targets` package or `callr` package.

## Usage

``` r
use_java(
  version = NULL,
  distribution = "Corretto",
  cache_path = getOption("rJavaEnv.cache_path"),
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  quiet = TRUE
)
```

## Arguments

- version:

  `Integer` or `character` vector of length 1 for major version of Java
  to download or install. If not specified, defaults to the latest LTS
  version. Can be "8", and "11" to "24" (or the same version numbers in
  `integer`) or any newer version if it is available for the selected
  distribution. For `macOS` on `aarch64` architecture (Apple Silicon)
  certain `Java` versions are not available.

- distribution:

  The Java distribution to download. If not specified, defaults to
  "Amazon Corretto". Currently only ["Amazon
  Corretto"](https://aws.amazon.com/corretto/) is supported.

- cache_path:

  The destination directory to download the Java distribution to.
  Defaults to a user-specific data directory.

- platform:

  The platform for which to download the Java distribution. Defaults to
  the current platform.

- arch:

  The architecture for which to download the Java distribution. Defaults
  to the current architecture.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

## Value

`NULL`. Prints the message that Java was set in the current R session if
`quiet` is set to `FALSE`.

## Examples

``` r
if (FALSE) { # \dontrun{

# set cache directory for Java to be in temporary directory
options(rJavaEnv.cache_path = tempdir())

# install and set Java 8 in current R session
use_java(8)
# check Java version
"8" == java_check_version_cmd(quiet = TRUE)
"8" == java_check_version_rjava(quiet = TRUE)

# install and set Java 17 in current R session
use_java(17)
# check Java version
"17" == java_check_version_cmd(quiet = TRUE)
"17" == java_check_version_rjava(quiet = TRUE)

} # }
```
