# Map SDKMAN vendor code to distribution name

Uses reverse mapping from java_config.yaml. Issues warning for unknown
vendors.

## Usage

``` r
sdkman_vendor_to_distribution(vendor_code)
```

## Arguments

- vendor_code:

  SDKMAN vendor code (e.g., "amzn", "tem")

## Value

Distribution name (e.g., "Corretto", "Temurin")
