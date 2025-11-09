# Download a Java distribution

Download a Java distribution

## Usage

``` r
java_download(
  version = 21,
  distribution = "Corretto",
  cache_path = getOption("rJavaEnv.cache_path"),
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  quiet = FALSE,
  force = FALSE,
  temp_dir = FALSE
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

- force:

  A logical. Whether the distribution file should be overwritten or not.
  Defaults to `FALSE`.

- temp_dir:

  A logical. Whether the file should be saved in a temporary directory.
  Defaults to `FALSE`.

## Value

The path to the downloaded Java distribution file.

## Examples

``` r
if (FALSE) { # \dontrun{

# download distribution of Java version 17
java_download(version = "17", temp_dir = TRUE)

# download default Java distribution (version 21)
java_download(temp_dir = TRUE)
} # }
```
