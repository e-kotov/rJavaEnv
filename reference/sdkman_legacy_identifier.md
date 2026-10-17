# Map a "+build" SDKMAN identifier to its legacy broker form

SDKMAN's listing uses identifiers like "21.0.4.0+7-amzn",
"21.0.12+1.1-tem" or "21.0.12-fx+1.1-librca", while its broker still
serves the legacy forms "21.0.4-amzn", "21.0.12-tem" and
"21.0.12.fx-librca".

## Usage

``` r
sdkman_legacy_identifier(identifier)
```

## Arguments

- identifier:

  SDKMAN identifier

## Value

The legacy identifier, or NULL if `identifier` has no "+build" part or
is an early-access build
