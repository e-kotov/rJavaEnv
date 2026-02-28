# Download a Java distribution

Download a Java distribution

## Usage

``` r
java_download(
  version = 21,
  distribution = "Corretto",
  backend = getOption("rJavaEnv.backend", "native"),
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

  Java version specification. Accepts:

  - **Major version** (e.g., `21`, `17`): Downloads the latest release
    for that major version.

  - **Specific version** (e.g., `"21.0.9"`, `"11.0.29"`): Downloads the
    exact version.

  - **SDKMAN identifier** (e.g., `"25.0.1-amzn"`, `"24.0.2-open"`): Uses
    the SDKMAN backend automatically. When an identifier is detected,
    the `distribution` and `backend` arguments are **ignored** and
    derived from the identifier. Find available identifiers in the
    `identifier` column of
    [`java_list_available`](https://www.ekotov.pro/rJavaEnv/reference/java_list_available.md)`(backend = "sdkman")`.

- distribution:

  The Java distribution to download. One of "Corretto", "Temurin", or
  "Zulu". Defaults to "Corretto". Ignored if `version` is a SDKMAN
  identifier.

- backend:

  Download backend to use. One of "native" (vendor APIs) or "sdkman".
  Defaults to "native". Can also be set globally via
  `options(rJavaEnv.backend = "sdkman")`.

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
# \donttest{

# download distribution of Java version 17
java_download(version = "17", temp_dir = TRUE)
#> Detected platform: linux
#> Detected architecture: x64
#> You can change the platform and architecture by specifying the `platform` and
#> `arch` arguments.
#> File already cached: amazon-corretto-17.0.18.9.1-linux-x64.tar.gz
#> [1] "/tmp/RtmpoeQtFr/rJavaEnv_cache/distrib/amazon-corretto-17.0.18.9.1-linux-x64.tar.gz"
#> attr(,"distribution")
#> [1] "Corretto"
#> attr(,"backend")
#> [1] "native"
#> attr(,"version")
#> [1] "17"
#> attr(,"platform")
#> [1] "linux"
#> attr(,"arch")
#> [1] "x64"

# download default Java distribution (version 21)
java_download(temp_dir = TRUE)
#> Detected platform: linux
#> Detected architecture: x64
#> You can change the platform and architecture by specifying the `platform` and
#> `arch` arguments.
#> Downloading Corretto Java 21...
#> Verifying sha256 checksum...
#> Checksum verified.
#> [1] "/tmp/RtmpoeQtFr/rJavaEnv_cache/distrib/amazon-corretto-21.0.10.7.1-linux-x64.tar.gz"
#> attr(,"distribution")
#> [1] "Corretto"
#> attr(,"backend")
#> [1] "native"
#> attr(,"version")
#> [1] "21"
#> attr(,"platform")
#> [1] "linux"
#> attr(,"arch")
#> [1] "x64"

# download using SDKMAN backend
java_download(version = "21", backend = "sdkman", temp_dir = TRUE)
#> Detected platform: linux
#> Detected architecture: x64
#> You can change the platform and architecture by specifying the `platform` and
#> `arch` arguments.
#> ! SDKMAN backend: checksum verification unavailable
#> Downloading Corretto Java 21...
#> ! Skipping checksum (unavailable for SDKMAN)
#> [1] "/tmp/RtmpoeQtFr/rJavaEnv_cache/distrib/corretto-21-linux-x64.tar.gz"
#> attr(,"distribution")
#> [1] "Corretto"
#> attr(,"backend")
#> [1] "sdkman"
#> attr(,"version")
#> [1] "21"
#> attr(,"platform")
#> [1] "linux"
#> attr(,"arch")
#> [1] "x64"
# }
```
