# Access Java configuration from YAML

Helper function to access configuration loaded from java_config.yaml

## Usage

``` r
java_config(key = NULL)
```

## Arguments

- key:

  Optional key to retrieve specific config section. If NULL, returns
  entire config.

## Value

Configuration value or NULL if not found
