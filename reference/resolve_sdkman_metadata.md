# Resolve metadata via SDKMAN broker (NO CHECKSUM)

Resolves download metadata by querying the SDKMAN API. Note: SDKMAN does
not provide checksums, so verification will be skipped with a warning.

## Usage

``` r
resolve_sdkman_metadata(version, distribution, platform, arch)
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

  Java distribution name

- platform:

  Platform OS

- arch:

  Architecture

## Value

A java_build object with checksum=NULL
