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
  backend = getOption("rJavaEnv.backend", "native")
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

## Value

A java_build object containing all download metadata
