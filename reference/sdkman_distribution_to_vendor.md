# Map distribution name to SDKMAN vendor code

Uses reverse lookup on vendor_reverse_map with fallback to vendor_map.
Case-insensitive matching.

## Usage

``` r
sdkman_distribution_to_vendor(distribution)
```

## Arguments

- distribution:

  Distribution name (e.g., "Corretto", "Temurin", "microsoft")

## Value

Vendor code (e.g., "amzn", "tem", "ms") or NULL if not found
