# Fetch SDKMAN candidate identifiers for a platform

Queries /versions/all primary endpoint, falling back to /versions/list
table parsing if /versions/all returns an empty result.

## Usage

``` r
sdkman_fetch_identifiers(sdk_platform)
```

## Arguments

- sdk_platform:

  SDKMAN platform string (e.g., "linuxx64", "darwinarm64")

## Value

Character vector of identifiers
