# List Available Java Versions

This function retrieves a list of all available installable Java
versions from the specified backend(s). It returns a unified data frame
with version details, vendors, and checksum availability.

## Usage

``` r
java_list_available(
  backend = c("both", "native", "sdkman"),
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  force = FALSE,
  quiet = FALSE
)
```

## Arguments

- backend:

  Character vector. Backends to query: "native", "sdkman", or "both"
  (default).

- platform:

  Platform OS. Defaults to current platform. Use "all" to list for all
  supported platforms.

- arch:

  Architecture. Defaults to current architecture. Use "all" to list for
  all supported architectures.

- force:

  Logical. If TRUE, bypasses and refreshes the internal cache.

- quiet:

  Logical. If TRUE, suppresses progress messages.

## Value

A data.frame with columns:

- `backend`: "native" or "sdkman"

- `vendor`: Java distribution name

- `major`: Major version number

- `version`: Full version string

- `platform`: Platform OS

- `arch`: Architecture

- `identifier`: Internal identifier (mainly for SDKMAN)

- `checksum_available`: Whether checksum verification is available

## Examples

``` r
if (FALSE) { # \dontrun{
# List all available versions for current platform
java_list_available()

# List all versions for all platforms (Pro users)
java_list_available(platform = "all", arch = "all")
} # }
```
