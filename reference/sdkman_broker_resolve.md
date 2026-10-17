# Resolve a download URL from the SDKMAN broker

Does not follow the redirect, so the JDK archive itself is not fetched.

## Usage

``` r
sdkman_broker_resolve(identifier, sdk_platform)
```

## Arguments

- identifier:

  SDKMAN identifier (e.g., "21.0.4-amzn")

- sdk_platform:

  SDKMAN platform string (e.g., "linuxx64")

## Value

The download URL, or NULL if the broker cannot serve the identifier
