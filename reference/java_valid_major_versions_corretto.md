# Get Available Online Versions of Amazon Corretto

This function downloads the latest Amazon Corretto version information
from the Corretto GitHub endpoint and returns a data frame with details
for all eligible releases.

## Usage

``` r
java_valid_major_versions_corretto(
  arch = NULL,
  platform = NULL,
  imageType = "jdk"
)
```

## Arguments

- arch:

  Optional character string for the target architecture (e.g., "x64").
  If `NULL`, it is inferred using
  [`platform_detect()`](https://www.ekotov.pro/rJavaEnv/reference/platform_detect.md).

- platform:

  Optional character string for the operating system (e.g., "windows",
  "macos", "linux"). If `NULL`, it is inferred using
  [`platform_detect()`](https://www.ekotov.pro/rJavaEnv/reference/platform_detect.md).

- imageType:

  Optional character string to filter on; defaults to `"jdk"`. Can be
  set to `"jre"` for Windows Java Runtime Environment.

## Value

A `character` vector of available major Corretto versions.

## Details

It leverages the existing
[`platform_detect()`](https://www.ekotov.pro/rJavaEnv/reference/platform_detect.md)
function to infer the current operating system and architecture if these
are not provided.
