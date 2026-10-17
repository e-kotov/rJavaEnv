# Resolve Java download metadata

Dispatches metadata resolution to the appropriate backend and
distribution resolver

## Usage

``` r
resolve_java_metadata(
  version,
  distribution = "Corretto",
  platform = platform_detect()$os,
  arch = platform_detect()$arch,
  backend = getOption("rJavaEnv.backend", "native"),
  quiet = FALSE
)
```

## Arguments

- version:

  Major Java version (e.g., 21, 17, 11)

- distribution:

  Java distribution name ("Corretto", "Temurin", or "Zulu")

- platform:

  Platform OS (e.g., "linux", "macos", "windows")

- arch:

  Architecture (e.g., "x64", "aarch64")

- backend:

  Download backend to use: "native" (vendor APIs) or "sdkman"

- quiet:

  A `logical` value indicating whether to suppress messages. Can be
  `TRUE` or `FALSE`.

## Value

A java_build object containing all download metadata
