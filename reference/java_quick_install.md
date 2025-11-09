# Download and install and set Java in current working/project directory

Download and install and set Java in current working/project directory

## Usage

``` r
java_quick_install(
  version = 21,
  distribution = "Corretto",
  project_path = NULL,
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  quiet = FALSE,
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

- project_path:

  A `character` vector of length 1 containing the project directory
  where Java should be installed. If not specified or `NULL`, defaults
  to the current working directory.

- platform:

  The platform for which to download the Java distribution. Defaults to
  the current platform.

- arch:

  The architecture for which to download the Java distribution. Defaults
  to the current architecture.

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

- temp_dir:

  A logical. Whether the file should be saved in a temporary directory.
  Defaults to `FALSE`.

## Value

Invisibly returns the path to the Java home directory. If quiet is set
to `FALSE`, also prints a message indicating that Java was installed and
set in the current working/project directory.

## Examples

``` r
if (FALSE) { # \dontrun{

# quick download, unpack, install and set in current working directory default Java version (21)
java_quick_install(17, temp_dir = TRUE)
} # }
```
